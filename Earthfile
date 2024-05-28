# https://docs.earthly.dev/basics

VERSION 0.8

nix-dev-shell:
  ARG --required DEVSHELL
  FROM nixos/nix:2.20.4
  # enable flakes
  RUN echo "extra-experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  # replace /bin/sh with a script that sources `/root/sh_env` for every RUN command.
  # we use this to execute all `RUN`-commands in our nix dev shell.
  # we need to explicitly delete `/bin/sh` first, because it's a symlink to `/bin/busybox`,
  # and `COPY` would actually follow the symlink and replace `/bin/busybox` instead.
  RUN rm /bin/sh
  # copy in our own `sh`, which wraps `bash`, and which sources `/root/sh_env`
  COPY ci_sh.sh /bin/sh
  ARG ARCH=$(uname -m)
  # cache `/nix`, especially `/nix/store`, with correct chmod and a global id, so we can reuse it
  # only works before installing nix
  # CACHE --persist --sharing shared --chmod 0755 --id nix-store /nix
  WORKDIR /app
  COPY flake.nix flake.lock .
  # build our dev-shell, creating a gcroot, so it won't be garbage collected by nix.
  RUN nix build --out-link /root/flake-devShell-gcroot ".#devShells.$ARCH-linux.$DEVSHELL"
  # set up our `/root/sh_env` file to source our flake env, will be used by ALL `RUN`-commands!
  RUN nix print-dev-env ".#$DEVSHELL" >> /root/sh_env

root-julia-setup:
  FROM +nix-dev-shell --DEVSHELL=build
  WORKDIR /app
  COPY Manifest.toml Project.toml ./
  # https://discourse.julialang.org/t/precompiling-module-each-time-without-any-change/99711
  # Pass --code-coverage=none and --check-bounds=yes so that we don't have to compile again when testing.
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
	COPY --dir src ./


node-ext:
  FROM +root-julia-setup

  WORKDIR  /app/globalbrain-node/julia
  COPY globalbrain-node/julia/Project.toml globalbrain-node/julia/Manifest.toml ./
  COPY --dir globalbrain-node/julia/build.jl globalbrain-node/julia/globalbrain.h ./
  # Example c callable lib project: https://github.com/JuliaLang/PackageCompiler.jl/tree/master/examples/MyLib
  RUN julia -t auto --startup-file=no --project -e 'using Pkg; Pkg.instantiate(); include("build.jl")'
  # rpath pointed to /nix/store, TODO: report upstream to julia / PackageCompiler
  # To patch a new file, first print the rpath using:
  # RUN patchelf --print-rpath build/lib/julia/<libfile>

  RUN find build | sort
  RUN patchelf --set-rpath '$ORIGIN/..:$ORIGIN' build/lib/julia/libjulia-internal.so \
   && patchelf --set-rpath '$ORIGIN/..:$ORIGIN' build/lib/julia/libjulia-codegen.so \
   && patchelf --set-rpath '$ORIGIN' build/lib/julia/libgfortran.so \
   && patchelf --set-rpath '$ORIGIN' build/lib/julia/libmbedtls.so 
  RUN find build -name '*.so*' -type f -exec bash -c 'echo -n "{}, rpath=" && patchelf --print-rpath {} && ldd {}' \;

  WORKDIR /app/globalbrain-node
  COPY globalbrain-node/package.json globalbrain-node/package-lock.json ./
  COPY --dir globalbrain-node/binding.cc globalbrain-node/binding.gyp globalbrain-node/index.js ./
  RUN npm install
  COPY globalbrain-node/test.js ./
  # RUN npm test

  # Create artifact
  RUN mkdir -p /artifact/julia/build \
   && mv julia/build /artifact/julia/ \
   && mv build /artifact/ \
   && mv package.json /artifact/ \
   && mv package-lock.json /artifact/ \
   && mv binding.gyp /artifact/ \
   && mv binding.cc /artifact/ \
   && mv index.js /artifact/ \
   && mv test.js /artifact/
  RUN find /artifact -type d -exec du -sh {} \;
  SAVE ARTIFACT /artifact


node-ext-test:
  FROM nixos/nix:2.20.4
  # enable flakes
  RUN echo "extra-experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  RUN nix profile install --impure "nixpkgs#nodejs_20"
  RUN nix profile install --impure "nixpkgs#gcc"
  COPY +node-ext/artifact /globalbrain-node-package
  COPY globalbrain-node/globalbrain-node-test /app/globalbrain-node-test
  WORKDIR /app/globalbrain-node-test

  # call from C
  ENV GB_OUT=/globalbrain-node-package/julia/build
  ENV GLOBALBRAIN_INCLUDES=$GB_OUT/include/julia_init.h $GB_OUT/include/globalbrain.h
  ENV GLOBALBRAIN_PATH=$GB_OUT/lib/libglobalbrain.so
  RUN gcc test.c -o test-c.out -I$GB_OUT/include -L$GB_OUT/lib -ljulia -lglobalbrain
  RUN rm -f test.db && ./test-c.out

  # call from C++
  RUN g++ test.cc -o test-cc.out -I$GB_OUT/include -L$GB_OUT/lib -ljulia -lglobalbrain
  RUN rm -f test.db && ./test-cc.out

  # call from javascript
  RUN npm install --ignore-scripts --save /globalbrain-node-package
  RUN npm test 

sim-run:
  FROM +root-julia-setup
  ENV SIM_DATABASE_PATH=sim.db
  COPY --dir src simulations ./
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project=simulations -e 'using Pkg; Pkg.instantiate()'
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project=simulations simulations/run.jl simulations/scenarios
  SAVE ARTIFACT sim.db AS LOCAL app/public/

vis-setup:
  FROM +nix-dev-shell --DEVSHELL=build
  WORKDIR /app/app
  COPY app/package.json app/package-lock.json ./
  RUN npm install
  COPY app/tsconfig.json app/index.html app/vite.config.js ./
  COPY --dir app/src/ ./

vis-build:
  FROM +vis-setup
  RUN npx tsc
  COPY +sim-run/sim.db public/sim.db
  RUN npx vite build
  SAVE ARTIFACT dist AS LOCAL app/dist

vis-format-check:
  FROM +vis-setup
  COPY app/.prettierrc ./
  RUN npx prettier --check .

# vis-dev:
#   # TODO: expose port: because https://github.com/earthly/earthly/issues/2047
#   FROM +setup-visualization
#   RUN --interactive npm run dev 

sim-test-unit:
  FROM +root-julia-setup
  ENV SOCIAL_PROTOCOLS_DATADIR=.
  COPY --dir test ./
  RUN julia -t auto --project --code-coverage=none  --check-bounds=yes --eval "using Pkg; Pkg.test()"

sim-test:
  FROM +root-julia-setup
  ENV SOCIAL_PROTOCOLS_DATADIR=.
  COPY --dir test test-data scripts ./
  COPY test.sh ./
  RUN ./test.sh

# TODO:
# sim-lint:
#      FROM +setup-julia
#      # RUN julia -e 'using Pkg; Pkg.add(PackageSpec(name="StaticLint", version="8.2.0"))'
#      RUN julia -e 'using Pkg; Pkg.add(PackageSpec(name="JET", version="0.8.2duompile/global-brain-service/ g  obal-brain-service
#      RUN ls -l global-brain-service/bin
#      RUN ./global-brain-service/bin/GlobalBrainService

ci-test:
  BUILD +sim-test-unit
  BUILD +sim-test
  BUILD +sim-run
  BUILD +vis-build
  BUILD +vis-format-check
  BUILD +node-ext-test

ci-deploy:
  BUILD +ci-test
  BUILD +vis-build

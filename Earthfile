# https://docs.earthly.dev/basics

VERSION 0.8

alpine-with-nix:
  FROM alpine:20240329
  # need the 'testing'-repo to install `nix`
  RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
  RUN apk add --no-cache nix bash
  RUN mkdir -p /etc/nix && echo "extra-experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  # replace /bin/sh with a script that sources `/root/sh_env` for every RUN command.
  # we use this to execute all `RUN`-commands in our nix dev shell.
  # we need to explicitly delete `/bin/sh` first, because it's a symlink to `/bin/busybox`,
  # and `COPY` would actually follow the symlink and replace `/bin/busybox` instead.
  RUN rm /bin/sh
  # copy in our own `sh`, which wraps `bash`, and which sources `/root/sh_env`
  COPY ci_sh.sh /bin/sh

nix-dev-shell:
  ARG DEVSHELL=build
  FROM +alpine-with-nix
  ARG ARCH=$(uname -m)
  # cache `/nix`, especially `/nix/store`, with correct chmod and a global id, so we can reuse it
  CACHE --persist --sharing shared --chmod 0755 --id nix-store /nix
  WORKDIR /app
  COPY flake.nix flake.lock .
  # build our dev-shell, creating a gcroot, so it won't be garbage collected by nix.
  # TODO: `x86_64-linux` is hardcoded here, but it would be nice to determine it dynamically.
  RUN nix build --out-link /root/flake-devShell-gcroot ".#devShells.$ARCH-linux.$DEVSHELL"
  # set up our `/root/sh_env` file to source our flake env, will be used by ALL `RUN`-commands!
  RUN nix print-dev-env ".#$DEVSHELL" >> /root/sh_env
  RUN npm config set update-notifier false # disable npm update checks

root-julia-setup:
  FROM +nix-dev-shell
  WORKDIR /app
  COPY Manifest.toml Project.toml ./
  # https://discourse.julialang.org/t/precompiling-module-each-time-without-any-change/99711
  # Pass --code-coverage=none and --check-bounds=yes so that we don't have to compile again when testing.
  RUN julia -t auto --project --code-coverage=none  --check-bounds=yes --eval 'using Pkg; Pkg.instantiate()'
  RUN julia -t auto --project --code-coverage=none  --check-bounds=yes --eval 'using Pkg; Pkg.precompile()'
	COPY --dir src ./


node-ext:
  FROM +root-julia-setup

  WORKDIR /app/globalbrain-node
  COPY globalbrain-node/Project.toml globalbrain-node/Manifest.toml ./

  WORKDIR  /app/globalbrain-node/julia
  COPY --dir globalbrain-node/julia/build.jl ./
  # Example c callable lib project: https://github.com/JuliaLang/PackageCompiler.jl/tree/master/examples/MyLib
  RUN julia -t auto --startup-file=no --project -e 'using Pkg; Pkg.instantiate(); include("build.jl")'

  WORKDIR /app/globalbrain-node
  COPY globalbrain-node/package.json globalbrain-node/package-lock.json ./
  COPY --dir globalbrain-node/node globalbrain-node/binding.gyp globalbrain-node/index.js ./
  RUN npm install
  COPY globalbrain-node/test.js ./
  RUN npm test

test-node-ext:
  FROM +node-ext
  WORKDIR /app/globalbrain-node
  COPY --dir globalbrain-node/globalbrain-node-test ./
  WORKDIR /app/globalbrain-node/globalbrain-node-test
  RUN npm install --ignore-scripts --save ..
  RUN npm test 


sim-run:
  FROM +root-julia-setup
  ENV SIM_DATABASE_PATH=sim.db
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project -e 'using Pkg; Pkg.add("Distributions")' # HACK: we don't want Distributions to be compiled into the node extension. Better let the simulation depend on the core algorithm.
  COPY --dir scripts simulations ./
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project scripts/sim.jl
  SAVE ARTIFACT sim.db AS LOCAL app/public/

vis-setup:
  FROM +nix-dev-shell
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
  BUILD +test-node-ext

ci-deploy:
  BUILD +ci-test
  BUILD +vis-build

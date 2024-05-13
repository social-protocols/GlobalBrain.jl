# https://docs.earthly.dev/basics

VERSION 0.8

devbox-shell:
  FROM jetpackio/devbox:latest

  USER root:root
  WORKDIR /app
  RUN chown ${DEVBOX_USER}:${DEVBOX_USER} /app
  USER ${DEVBOX_USER}:${DEVBOX_USER}
  COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.json
  COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.lock devbox.lock
  RUN devbox install
  USER root:root

  # replace shell with our own script for every RUN command.
  # it wraps `bash` and sources `/root/sh_env`.
  # we need to explicitly delete `/bin/sh` first, because it's a symlink to `/bin/busybox`,
  # and `COPY` would actually follow the symlink and replace `/bin/busybox` instead.
  RUN rm /bin/sh
  # copy in our own `sh`, which wraps `bash`, and which sources `/root/sh_env`
  COPY ci_sh.sh /bin/sh

  # every RUN command runs in a devbox shell
  RUN devbox shellenv --no-refresh-alias >> /root/sh_env
  RUN npm config set update-notifier false # disable npm update checks


root-julia-setup:
  FROM +devbox-shell
  WORKDIR /app
  COPY Manifest.toml Project.toml ./
  # https://discourse.julialang.org/t/precompiling-module-each-time-without-any-change/99711
  # Pass --code-coverage=none and --check-bounds=yes so that we don't have to compile again when testing.
  RUN julia -t auto --project --code-coverage=none  --check-bounds=yes --eval 'using Pkg; Pkg.instantiate()'
  RUN julia -t auto --project --code-coverage=none  --check-bounds=yes --eval 'using Pkg; Pkg.precompile()'
  COPY --dir src sql ./


node-ext:
  FROM +root-julia-setup
  WORKDIR /app/globalbrain-node
  COPY globalbrain-node/Project.toml globalbrain-node/Manifest.toml globalbrain-node/package.json globalbrain-node/package-lock.json globalbrain-node/binding.gyp globalbrain-node/index.js ./
  COPY --dir globalbrain-node/julia/ globalbrain-node/node/ ./
  RUN julia -t auto --project --code-coverage=none --check-bounds=yes --eval 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
  RUN npm install
  COPY globalbrain-node/test.js ./
  RUN node test.js ./test-globalbrain-node.db

node-ext-tgz:
  FROM +node-ext
  WORKDIR /app
  RUN tar -cvzf socialprotocols-globalbrain-node-0.0.1.tgz globalbrain-node/package.json globalbrain-node/package-lock.json globalbrain-node/index.js globalbrain-node/dist
  SAVE ARTIFACT socialprotocols-globalbrain-node-0.0.1.tgz
  SAVE ARTIFACT socialprotocols-globalbrain-node-0.0.1.tgz AS LOCAL ./socialprotocols-globalbrain-node-0.0.1.tgz

test-node-ext:
  FROM +node-ext
  WORKDIR /app/globalbrain-node
  COPY --dir globalbrain-node/globalbrain-node-test ./
  WORKDIR /app/globalbrain-node/globalbrain-node-test
  RUN npm install --ignore-scripts --save ..
  RUN npm test
  RUN fail

test-node-ext-tgz:
  FROM +node-ext-tgz
  WORKDIR /app/globalbrain-node
  COPY --dir globalbrain-node/globalbrain-node-test ./
  WORKDIR /app/globalbrain-node/globalbrain-node-test
  COPY +node-ext-tgz/socialprotocols-globalbrain-node-0.0.1.tgz ./
  RUN tar -xzvf socialprotocols-globalbrain-node-0.0.1.tgz
  RUN npm install --save './globalbrain-node'
  RUN npm test

sim-run:
  FROM +root-julia-setup
  ENV SIM_DATABASE_PATH=sim.db
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project -e 'using Pkg; Pkg.add("Distributions")' # HACK: we don't want Distributions to be compiled into the node extension. Better let the simulation depend on the core algorithm.
  COPY --dir scripts simulations ./
  RUN julia -t auto --code-coverage=none --check-bounds=yes --project scripts/sim.jl
  SAVE ARTIFACT sim.db AS LOCAL app/public/

vis-setup:
  FROM +devbox-shell
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
  BUILD +test-node-ext-tgz

ci-deploy:
  BUILD +ci-test
  BUILD +vis-build

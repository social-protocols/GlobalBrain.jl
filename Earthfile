# https://docs.earthly.dev/basics

VERSION 0.8


flake:
  FROM nixos/nix:2.20.4
  WORKDIR /app
  # Enable flakes
  RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  COPY flake.nix flake.lock ./
  # install packages from the packages section in flake.nix
  RUN nix profile install --impure -L '.#ci'
  RUN npm config set update-notifier false # disable npm update checks


node-ext:
  FROM +flake
  WORKDIR /ext
  COPY globalbrain-node/Project.toml globalbrain-node/Manifest.toml globalbrain-node/package.json globalbrain-node/package-lock.json globalbrain-node/binding.gyp globalbrain-node/index.js globalbrain-node/
  COPY --dir globalbrain-node/julia/ globalbrain-node/node/ globalbrain-node/
  COPY Project.toml Manifest.toml ./
  COPY --dir src/ sql/ ./
  RUN julia --project --eval 'using Pkg; Pkg.instantiate()'
  RUN julia --project --eval 'using Pkg; Pkg.precompile()'
  WORKDIR /ext/globalbrain-node
  RUN julia --project --eval 'using Pkg; Pkg.instantiate()'
  RUN npm install
  COPY globalbrain-node/test.js ./
  RUN node test.js ./test-globalbrain-node.db



sim-setup:
  FROM +flake
  # FROM julia:1.10.1-bookworm
  WORKDIR /app
  # julia
  COPY Manifest.toml Project.toml ./
  RUN julia --project --eval 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

sim-run:
  FROM +sim-setup
  ENV SIM_DATABASE_PATH=sim.db
  COPY --dir src/ scripts/ sql/ simulations/ ./
  RUN julia --project scripts/sim.jl
  SAVE ARTIFACT sim.db AS LOCAL app/public/

vis-setup:
  FROM +flake
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
  FROM +sim-setup
  ENV SOCIAL_PROTOCOLS_DATADIR=.
  COPY --dir sql/ src/ test/ ./
  RUN julia --project --eval "using Pkg; Pkg.test()"

sim-test:
  FROM +sim-setup
  ENV SOCIAL_PROTOCOLS_DATADIR=.
  COPY --dir src/ test/ test-data/ sql/ scripts/ ./
  COPY test.sh ./
  RUN ./test.sh

# TODO:
# sim-lint:
# 	FROM +setup-julia
# 	# RUN julia -e 'using Pkg; Pkg.add(PackageSpec(name="StaticLint", version="8.2.0"))'
# 	RUN julia -e 'using Pkg; Pkg.add(PackageSpec(name="JET", version="0.8.2duompile/global-brain-service/ global-brain-service
# 	RUN ls -l global-brain-service/bin
# 	RUN ./global-brain-service/bin/GlobalBrainService


ci-test:
  BUILD +sim-test-unit
  BUILD +sim-test
  BUILD +vis-build
  BUILD +vis-format-check
  BUILD +node-ext

ci-deploy:
  BUILD +ci-test
  BUILD +vis-build

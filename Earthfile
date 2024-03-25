VERSION 0.8


# lint:
# 	FROM +setup-julia
# 	# RUN julia -e 'using Pkg; Pkg.add(PackageSpec(name="StaticLint", version="8.2.0"))'
# 	RUN julia -e 'using Pkg; Pkg.add(PackageSpec(name="JET", version="0.8.2duompile/global-brain-service/ global-brain-service
# 	RUN ls -l global-brain-service/bin
# 	RUN ./global-brain-service/bin/GlobalBrainService


flake:
  FROM nixos/nix:2.20.4
  WORKDIR /app
  # Enable flakes
  RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  COPY flake.nix flake.lock ./
  # install packages from the packages section in flake.nix
  RUN nix profile install --impure -L '.#ci'

vis-setup:
  FROM +flake
  WORKDIR /app/app
  COPY app/package.json app/package-lock.json ./
  RUN npm install
  COPY app/tsconfig.json app/index.html ./
  COPY --dir app/src/ ./

vis-build:
  FROM +vis-setup
  COPY +sim-run/sim.db public/sim.db
  RUN npm run build
  SAVE ARTIFACT dist AS LOCAL app/dist

# vis-dev:
#   # TODO: expose port: because https://github.com/earthly/earthly/issues/2047
#   FROM +setup-visualization
#   RUN --interactive npm run dev 

sim-run:
  FROM +sim-setup
  ENV SIM_DATABASE_PATH=sim.db
  COPY --dir src/ scripts/ sql/ simulations/ ./
  RUN julia --project scripts/sim.jl
  SAVE ARTIFACT sim.db AS LOCAL app/public/


sim-setup:
  FROM +flake
  # FROM julia:1.10.1-bookworm
  WORKDIR /app
  # julia
  COPY Manifest.toml Project.toml ./
  RUN julia --project=@. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'


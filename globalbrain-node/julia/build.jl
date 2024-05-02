using PackageCompiler: bundle_artifacts, bundle_julia_libraries, create_pkg_context, create_sysimage
using Libdl

# The directory of the GlobalBrain.jl source
globalbrainSourceDir = "../.."

builddir = length(ARGS) > 0 ? ARGS[1] : "build"
project = joinpath(@__DIR__, globalbrainSourceDir)
sysimage_path = joinpath(builddir, "lib", "sysimage.$(Libdl.dlext)")

mkpath(builddir)

@info "Building Julia system image..." builddir=builddir project=project sysimage_path=sysimage_path

# From PackageCompiler.jl `create_app(...)`
@info "  bundle_artifacts"
ctx = create_pkg_context(project)
bundle_artifacts(ctx, builddir, include_lazy_artifacts=false)
bundle_julia_libraries(builddir)

cp(joinpath(project, "Project.toml"), joinpath(builddir, "lib", "Project.toml"))

@info "  create_sysimage"
create_sysimage(
    :GlobalBrain,
    sysimage_path = sysimage_path,
    project = project,
    # Optionally, to minimize the image size.
    incremental = false,
    filter_stdlibs = true,
    # Optionally, to target a specific CPU.
    # Use `julia -C help` to list CPU targets.
    # cpu_target = skylake
)

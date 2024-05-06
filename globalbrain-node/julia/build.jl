using PackageCompiler
using Libdl

globalbrainSourceDir = "../.."
target_dir = get(ENV, "OUTDIR", "$(@__DIR__)/../MyLibCompiled")

println("Creating library in $target_dir")
PackageCompiler.create_library(globalbrainSourceDir, target_dir;
                                lib_name="mylib",
                                # precompile_execution_file=["$(@__DIR__)/generate_precompile.jl"],
                                # precompile_statements_file=["$(@__DIR__)/additional_precompile.jl"],
                                incremental=false,
                                filter_stdlibs=true,
                                force=true, # Overwrite target_dir.
                                header_files = ["$(@__DIR__)/mylib.h"],
                            )


# The directory of the GlobalBrain.jl source
# globalbrainSourceDir = "../.."
#
# builddir = length(ARGS) > 0 ? ARGS[1] : "build"
# project = joinpath(@__DIR__, globalbrainSourceDir)
# sysimage_path = joinpath(builddir, "lib", "sysimage.$(Libdl.dlext)")
#
# mkpath(builddir)
#
# @info "Building Julia system image..." builddir=builddir project=project sysimage_path=sysimage_path
#
# # From PackageCompiler.jl `create_app(...)`
# @info "  bundle_artifacts"
# ctx = create_pkg_context(project)
# bundle_artifacts(ctx, builddir, include_lazy_artifacts=true)
#
# cp(joinpath(project, "Project.toml"), joinpath(builddir, "lib", "Project.toml"))
#
# @info "  create_sysimage"
# create_sysimage(
#     :GlobalBrain,
#     sysimage_path = sysimage_path,
#     project = project,
#     # Optionally, to minimize the image size.
#     incremental = false,
#     filter_stdlibs = true,
#     # Optionally, to target a specific CPU.
#     # Use `julia -C help` to list CPU targets.
#     # cpu_target = skylake
# )

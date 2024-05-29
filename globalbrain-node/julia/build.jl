using PackageCompiler
using Libdl

# The directory of the GlobalBrain.jl source
globalbrainSourceDir = "../.."

target_dir = "$(@__DIR__)/build"

println("Creating library in $target_dir")
# https://julialang.github.io/PackageCompiler.jl/stable/refs.html#PackageCompiler.create_library
PackageCompiler.create_library(globalbrainSourceDir, target_dir;
                                lib_name="globalbrain",
                                incremental=true,
                                filter_stdlibs=false,
                                force=true, # Overwrite target_dir.
                                header_files = ["$(@__DIR__)/globalbrain.h"],
                            )

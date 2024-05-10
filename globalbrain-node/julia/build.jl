using PackageCompiler
using Libdl

globalbrainSourceDir = "../.."
target_dir = "$(@__DIR__)/../globalbrain-compiled"

println("Creating library in $target_dir")
PackageCompiler.create_library(globalbrainSourceDir, target_dir;
                                lib_name="globalbrain",
                                incremental=true,
                                filter_stdlibs=false,
                                force=true, # Overwrite target_dir.
                                header_files = ["$(@__DIR__)/globalbrain.h"],
                            )

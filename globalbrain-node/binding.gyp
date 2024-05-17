{
  "targets": [
    {
      "target_name": "binding",
      "sources": [ "binding.cc" ],
      "include_dirs": [ 
        "<!@(node -p \"require('node-addon-api').include\")",
        "julia/build/include"
      ],
      "libraries": [ 
        "-L<(module_root_dir)/julia/build/lib", 
        "-lglobalbrain",
        "-ljulia",
        # Linux
        "-Wl,-rpath,'$$ORIGIN/../../julia/build/lib'",
        "-Wl,-rpath,'$$ORIGIN/../../julia/build/lib/globalbrain'",
        "-Wl,-rpath,'$$ORIGIN/../../julia/build/lib/julia'",
        # macOS
        "-Wl,-rpath,@loader_path/../../julia/build/lib",
        "-Wl,-rpath,@loader_path/../../julia/build/lib/globalbrain",
        "-Wl,-rpath,@loader_path/../../julia/build/lib/julia"
      ],
      "defines": ["NAPI_VERSION=<(napi_build_version)", "NAPI_DISABLE_CPP_EXCEPTIONS"],
      "ldflags": [
        "-Wl,-rpath,@loader_path/../../julia/build/lib",
        "-Wl,-rpath,@loader_path/../../julia/build/lib/globalbrain",
        "-Wl,-rpath,@loader_path/../../julia/build/lib/julia"
      ]
    }
  ]
}

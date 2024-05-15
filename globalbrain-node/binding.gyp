{
  "targets": [
    {
      "target_name": "binding",
      "sources": [ "node/binding.cc" ],
      "include_dirs": [ 
        "<!@(node -p \"require('node-addon-api').include\")",
        '<!@(julia -E "abspath(Sys.BINDIR, Base.INCLUDEDIR, \\"julia\\")")'
      ],
      "libraries": [ 
        "-L<(module_root_dir)/julia/build/lib", 
        "-ljulia" 
        # Linux
        " -Wl,-rpath,'$$ORIGIN/../../julia/build/lib'",
        " -Wl,-rpath,'$$ORIGIN/../../julia/build/lib/julia'",
        # macOS
        "-Wl,-rpath,'@loader_path/../../julia/build/lib'",
        "-Wl,-rpath,'@loader_path/../../julia/build/lib/julia'",
      ],
      "defines": ["NAPI_VERSION=<(napi_build_version)","NAPI_DISABLE_CPP_EXCEPTIONS"],
    }
  ]
}

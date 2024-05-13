{
  "targets": [
    {
      "target_name": "addon",
      "sources": [ "binding.cc" ],
      "include_dirs": [ "<!(node -e \"require('node-addon-api')\")" ],
      "libraries": [ "-L<(module_root_dir)/globalbrain-compiled/lib", "-lglobalbrain" ],
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ],
      "ldflags": [ "-Wl,-rpath,'$ORIGIN/../../globalbrain-compiled/lib'" ]
    }
  ]
}


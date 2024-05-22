{
  "targets": [
    {
      "target_name": "binding",
      "sources": [ "binding.cc" ],
      "include_dirs": [
        "<!(node -e \"console.log(require('path').dirname(require('child_process').execSync('node -p process.argv[0]', {encoding: 'utf8'}).trim()) + '/include/node')\")",
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
      "defines": [],
      "cflags": ["-std=c++17"],
      "cflags_cc": ["-std=c++17"],
      "ldflags": [
        "-Wl,-rpath,@loader_path/../../julia/build/lib",
        "-Wl,-rpath,@loader_path/../../julia/build/lib/globalbrain",
        "-Wl,-rpath,@loader_path/../../julia/build/lib/julia"
      ]
    }
  ]
}

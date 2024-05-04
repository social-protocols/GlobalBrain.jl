# vim: set ft=python:
# References:
# https://github.com/nodejs/node-addon-api/blob/master/doc/setup.md
# https://github.com/nodejs/node-addon-api/blob/master/doc/node-gyp.md
# https://github.com/mapbox/node-pre-gyp#configuring
{
    "targets": [
        {
            "target_name": "binding",
            "sources": ["node/binding.cc"],
            "cflags_cc": ["-fPIC"],
            "cflags_cc!": ["-fno-exceptions"],
            "defines": ["NAPI_VERSION=<(napi_build_version)",],
            "include_dirs": [
                '<!@(julia -E "abspath(Sys.BINDIR, Base.INCLUDEDIR, \\"julia\\")")',
                '<!@(node -p "require(\\"node-addon-api\\").include")',
            ],
            "libraries": [
                "-ljulia",
                "-L'<(PRODUCT_DIR)/lib'",
                # Linux
                "-Wl,-rpath,'$$ORIGIN/lib'",
                "-Wl,-rpath,'$$ORIGIN/lib/julia'",
                # macOS
                "-Wl,-rpath,'@loader_path/lib'",
                "-Wl,-rpath,'@loader_path/lib/julia'",
            ],
            "msvs_settings": {"VCCLCompilerTool": {"ExceptionHandling": 1},},
            "xcode_settings": {
                "CLANG_CXX_LIBRARY": "libc++",
                "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
                "MACOSX_DEPLOYMENT_TARGET": "10.7",
            },
        },
    ]
}

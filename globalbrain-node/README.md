# Node extension for GlobalBrain.jl

##  Based on example form Maxime Mouchet git+https://github.com/maxmouchet/julia-node-extension-demo.git

## TODOS:

- Use latest version of julia PackageCompiler
- Use node-gyp directly instead of node-pre-gyp
- Use cmake.js instead of node-gyp
- Log stack traces to a file. Include name of file in error returned from Julia, so when there is a error in the GlobalBrain.jl called form typescript code, you can see stacktraces

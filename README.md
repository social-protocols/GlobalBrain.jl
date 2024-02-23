# Global Brain Note Scoring Service

>[!NOTE]
>A Julia service that consumes an input stream of vote events and outputs a stream of top reply scores.

## Overview

To get a dev shell, run `direnv allow`.
This will copy the contents from .env.example to a .env file, set the environment variables, and fetch the required dependencies.

To run with test data (located in `testdata/`), execute:

```
just runtest
```

To run with real data, execute:

```
just run
```

Make sure to check out the `.env.example` file to see the required environment variables.

To inspect the produced data:

```
just sqlite
```

## Compilation to Avoid Startup Lag

`just run` and `just runtest` do not run precompiled versions of the code, so the startup time might lag.
`ScheduledScoring.jl` setup according to the structure required by [`PackageCompiler.jl`](https://github.com/JuliaLang/PackageCompiler.jl) to produce an executable app with `create_app`.

>[!WARNING]
>This might currently be broken, since we haven't tested it after a structure change.

To compile the app, execute:

```
just compile
```

To update the depedencies, navigate to the `ScheduledScoring.jl` folder and execute:

```
just up
```


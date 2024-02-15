# Global Brain Note Scoring on a Schedule

Produce an executable file that runs the [Global Brain top reply scoring algorithm](https://social-protocols.org/global-brain/) every 60 seconds on a SQLite database.

The following command produces the executable (~10 mins compile time):

```
just compile
```

Before you run the task, make sure that you have an environment variable called `DATABASE_PATH` that speciefies the path to your SQLite database available.
Note, that the [GlobalBrain.jl](https://github.com/social-protocols/GlobalBrain.jl) package assumes a specific database schema.
You can run the scheduled scoring task with this command (assuming the `DATABASE_PATH` variable is set):
 
```
just run
```

To inspect the produced data:

```
just sqlite
```

## ScheduledScoring.jl

This is a Julia module that is setup according to the structure required by [`PackageCompiler.jl`](https://github.com/JuliaLang/PackageCompiler.jl) to produce an executable app with `create_app`.
To update the depedencies, navigate to the `ScheduledScoring.jl` folder and execute:

```
just up
```

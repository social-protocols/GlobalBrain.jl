<h1 align="center" style="border-bottom: none">
    The Global Brain Algorithm
</h1>


>[!NOTE]
>*This is a reference implementation and experimentation sandbox for the [Global Brain algorithm](https://social-protocols.org/global-brain/).*


## Setup

To get a dev shell, run `direnv allow`.
This will copy the contents from .env.example to a .env file, set the environment variables, and fetch the required dependencies.
Make sure to check out the `.env.example` file to see the required environment variables.


## Project Structure

**`src/`**

This project is structured as a Julia module, so the code is located in `src`.
Within `src`, there are two main components: `lib` and `service`.
The `lib` folder contains the algorithm along with the tooling around it and the service folder contains a service that consumes a vote stream and outputs a top reply score stream.
As the service maintains some state, `db.jl` contains a SQLite database interface.
Finally, `simulations.jl` contains a simulation framework with which simple scenarios can be created and run on the Global Brain algorithm.

**`simulations/`**

A simulations module (`GlobalBrainSimulations.jl`) to test scenarios against the Global Brain algorithm.
We use it as a testing framework.
Simulations are located in `simulations/scenarios`.
Each scenario is a Julia script with a single anonymous function that takes a `SimulationAPI` object as input.

**`app/`**

A visualization app with which simulations can be explored and analyzed.


## Workflows

We use the [`just`](https://github.com/casey/just) command runner to automate some workflows.
Run `just` to see a list of workflows.

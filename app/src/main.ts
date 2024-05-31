import "./style.css"
import simDbUrl from "../public/sim.db?url"
import initSqlJs from "sql.js"
import wasmUrl from "../node_modules/sql.js/dist/sql-wasm.wasm?url"
import { unpackDBResult } from "./database.ts"
import { render } from "./render.ts"
import {
  setPeriodsSelectInput,
  initializeSimulationSelectInput,
  getSimulationFilter,
  getSelectedSimulationName,
} from "./control-form.ts"
import { Simulation } from "./types.ts"

// Architecture:
// - Unidirectional data flow from mutable state to view
// - central mutable state, which is represented by the control form
// - the ?simulationName URL parameter value is synced with the simulationID select input in the form
// - Whenever an item on the form is changed:
//   - the state is updated
//   - state is used to fetch data from the database
//   - data is used for derived lookups, created by pure functions in another file
//   - A single render call, which takes the data and renders/updates the view

async function main() {
  const sqlPromise = initSqlJs({ locateFile: () => wasmUrl })
  const dataPromise = fetch(simDbUrl).then((res) => res.arrayBuffer())
  const [SQL, buf] = await Promise.all([sqlPromise, dataPromise])
  const db = new SQL.Database(new Uint8Array(buf))

  const simulationsQueryResult =
    db.exec("select simulation_id, simulation_name from simulation")

  const simulations: Simulation[] =
    unpackDBResult(simulationsQueryResult[0])
      .map((x: any) => {
        return {
          simulationId: x.simulation_id,
          simulationName: x.simulation_name,
        } as Simulation
      })

  const simulationNames = simulations.map((x: Simulation) => x.simulationName)
  const simulationName = initializeSimulationSelectInput(simulationNames)
  setPeriodsSelectInput(db, simulationName)

  document.getElementById("period")!.addEventListener("change", function () {
    render(db, getSimulationFilter())
  })

  document
    .getElementById("simulationName")!
    .addEventListener("change", function () {
      const simulationName = getSelectedSimulationName()
      setPeriodsSelectInput(db, simulationName)
      render(db, getSimulationFilter())
    })

  render(db, getSimulationFilter())
}

google.charts.load("current", { packages: ["corechart", "line"] })
google.charts.setOnLoadCallback(main)
window.addEventListener("resize", main, false)

main()

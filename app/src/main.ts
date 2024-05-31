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
  getSelectedSimulationId,
} from "./control-form.ts"

// Architecture:
// - Unidirectional data flow from mutable state to view
// - central mutable state, which is represented by the control form
// - the ?simulationId URL parameter value is synced with the simulationID select input in the form
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

	const simulationIdsQueryResult =
		db.exec("select simulation_id, simulation_name from simulation")

	const simulations = unpackDBResult(simulationIdsQueryResult[0])
	const simulationNames = simulations.map((x: any) => x.simulation_name)

  const simulationId = initializeSimulationSelectInput(simulationNames)

  setPeriodsSelectInput(db, simulationId)

  document.getElementById("period")!.addEventListener("change", function () {
    render(db, getSimulationFilter())
  })

  document
    .getElementById("simulationId")!
    .addEventListener("change", function () {
      const simulationId = getSelectedSimulationId()
      setPeriodsSelectInput(db, simulationId)
      render(db, getSimulationFilter())
    })

  render(db, getSimulationFilter())
}

google.charts.load("current", { packages: ["corechart", "line"] })
google.charts.setOnLoadCallback(main)
window.addEventListener("resize", main, false)

main()

import "./style.css"
import simDbUrl from "../public/sim.db?url"
import initSqlJs from "sql.js"
import wasmUrl from "../node_modules/sql.js/dist/sql-wasm.wasm?url"
import { SimulationFilter } from "./types.ts"
import { unpackDBResult } from "./database.ts"
import { render } from "./render.ts"
import {
  addSimulationSelectInput,
  getSimulationFilterFromControlForm,
  setPeriodsSelectInput,
} from "./control-form.ts"
// Architecture:
// - Unidirectional data flow from mutable state to view
// - central mutable state, which represents the form
// - Once form is submitted:
//   - the state is updated
//   - state is used to fetch data from the database
//   - data is used for derived lookups, created by pure functions in another file
//   - A single render call, which takes the data and renders/updates the view

async function main() {
  const sqlPromise = initSqlJs({ locateFile: () => wasmUrl })
  const dataPromise = fetch(simDbUrl).then((res) => res.arrayBuffer())
  const [SQL, buf] = await Promise.all([sqlPromise, dataPromise])
  const db = new SQL.Database(new Uint8Array(buf))

  const simulationsQueryResult = db.exec("select tag from tag")
  const simulationIds = unpackDBResult(simulationsQueryResult[0]).map(
    (x: any) => x.tag,
  )

  addSimulationSelectInput(simulationIds)

  const simulationSelectInput = document.getElementById("simulationId")!
  setPeriodsSelectInput(db, (simulationSelectInput as HTMLInputElement).value)

  simulationSelectInput.addEventListener("change", (e) => {
    setPeriodsSelectInput(db, (e.target as HTMLInputElement).value)
  })

  // TODO: set default more robustly
  const controlForm = document.getElementById("controlForm")! as HTMLFormElement
  let simulationFilter = getSimulationFilterFromControlForm()

  function handleControlFormSubmit(e: SubmitEvent) {
    e.preventDefault()
  }

  function updateSimulationFilter() {
    simulationFilter = getSimulationFilterFromControlForm()
    render(db, simulationFilter)
  }

  controlForm.addEventListener("submit", handleControlFormSubmit)

  document
    .getElementById("simulationId")!
    .addEventListener("change", function () {
      updateSimulationFilter()
    })

  document.getElementById("period")!.addEventListener("change", function () {
    updateSimulationFilter()
  })

  render(db, simulationFilter)
}

google.charts.load("current", { packages: ["corechart", "line"] })
google.charts.setOnLoadCallback(main)
window.addEventListener("resize", main, false)

// main()

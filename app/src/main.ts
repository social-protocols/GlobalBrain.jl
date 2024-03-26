import "./style.css"
import simDbUrl from "../public/sim.db?url"
import initSqlJs from "sql.js"
import wasmUrl from "../node_modules/sql.js/dist/sql-wasm.wasm?url"
import { SimulationFilter } from "./types.ts"
import { unpackDBResult } from "./database.ts"
import { render } from "./render.ts"

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

  function addSimulationSelectInput(simulationIds: string[]) {
    const simulationSelect = document.getElementById("simulationId")
    simulationIds.forEach((id, i) => {
      const option = document.createElement("option")
      option.value = id
      option.text = id
      if (i === 0) option.selected = true
      simulationSelect?.appendChild(option)
    })
  }

  const simulationsQueryResult = db.exec("select tag from tag")
  const simulationIds = unpackDBResult(simulationsQueryResult[0]).map(
    (x: any) => x.tag,
  )

  addSimulationSelectInput(simulationIds)

  function setPeriodsSelectInput(db: any, simulationId: string) {
    const periodIdsQueryResult = db.exec(
      "select distinct vote_event_time from VoteEvent join Tag on (Tag.id = tag_id) where tag = :simulationId",
      { ":simulationId": simulationId },
    )
    const periods = unpackDBResult(periodIdsQueryResult[0]).map(
      (x: any) => x.vote_event_time,
    )
    const periodSelect = document.getElementById("period")!
    periodSelect.innerHTML = ""

    periods.forEach((id, i) => {
      const option = document.createElement("option")
      option.value = id.toString()
      option.text = id.toString()
      if (i === periods.length-1) option.selected = true
      periodSelect?.appendChild(option)
    })
  }

  const simulationSelectInput = document.getElementById("simulationId")!
  setPeriodsSelectInput(db, (simulationSelectInput as HTMLInputElement).value)

  simulationSelectInput.addEventListener("change", (e) => {
    setPeriodsSelectInput(db, (e.target as HTMLInputElement).value)
  })

  // TODO: set default more robustly
  let simulationFilter: SimulationFilter = {
    simulationId: "marbles",
    period: 1,
  }

  function handleControlFormSubmit(e: SubmitEvent) {
    e.preventDefault()
    const formData = new FormData(e.target as HTMLFormElement)
    simulationFilter = {
      simulationId: formData.get("simulationId")
        ? (formData.get("simulationId") as string)
        : null,
      period: formData.get("period")
        ? parseInt(formData.get("period") as string)
        : null,
    }
    render(db, simulationFilter)
  }

  const controlForm = document.getElementById("controlForm")
  controlForm?.addEventListener("submit", handleControlFormSubmit)

  render(db, simulationFilter)
}

main()

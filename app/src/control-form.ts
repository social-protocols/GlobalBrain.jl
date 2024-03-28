import { SimulationFilter } from "./types.ts"
import { unpackDBResult } from "./database.ts"

export function addSimulationSelectInput(simulationIds: string[]) {
  const simulationSelect = document.getElementById("simulationId")
  simulationIds.forEach((id, i) => {
    const option = document.createElement("option")
    option.value = id
    option.text = id
    if (i === 0) option.selected = true
    simulationSelect?.appendChild(option)
  })
}

export function setPeriodsSelectInput(db: any, simulationId: string) {
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
    if (i === periods.length - 1) option.selected = true
    periodSelect?.appendChild(option)
  })
}

export function getSimulationFilterFromControlForm(): SimulationFilter {
  const controlForm = document.getElementById("controlForm")! as HTMLFormElement
  const formData = new FormData(controlForm as HTMLFormElement)
  return {
    simulationId: formData.get("simulationId")
      ? (formData.get("simulationId") as string)
      : null,
    period: formData.get("period")
      ? parseInt(formData.get("period") as string)
      : null,
  }
}

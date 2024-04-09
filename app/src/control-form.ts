import { SimulationFilter } from "./types.ts"
import { unpackDBResult } from "./database.ts"


function setSimulationIdInURL(simulationId: string): void {
  const url = new URL(window.location.href);
  url.searchParams.set('simulationId', simulationId);
  window.history.replaceState({}, '', url.toString());
}

function getSimulationIdFromURL(): string | null {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('simulationId');
}

export function getSimulationFilter(): SimulationFilter {
  const urlParams = new URLSearchParams(window.location.search);
  const simulationId = urlParams.get('simulationId');


  const controlForm = document.getElementById("controlForm")! as HTMLFormElement
  const formData = new FormData(controlForm as HTMLFormElement)

  const period = formData.get("period")
      ? parseInt(formData.get("period") as string)
      : 1;

  return {simulationId, period}
}

export function getSelectedSimulationId(): string {
  const selectElement = document.getElementById('simulationId') as HTMLSelectElement;

  // Get the current simulation ID from the URL or fallback to the select element's default value
  return getSimulationIdFromURL() || selectElement.value!;

}

export function initializeSimulationSelectInput(simulationIds: string[]): string {

  addSimulationSelectInput(simulationIds)

  const selectElement = document.getElementById('simulationId') as HTMLSelectElement;

  // Get the current simulation ID from the URL or fallback to the select element's default value
  const simulationId: string = getSelectedSimulationId()

  // Set the select element's value
  selectElement.value = simulationId;

  // Update the URL without reloading
  setSimulationIdInURL(simulationId);

  // Add event listener to select element
  selectElement.addEventListener('change', (event) => {
    const selectedSimulationId = (event.target as HTMLSelectElement).value;
    setSimulationIdInURL(selectedSimulationId)
  });

  return simulationId

}

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
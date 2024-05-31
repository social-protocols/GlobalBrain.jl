import { SimulationFilter } from "./types.ts"
import { unpackDBResult } from "./database.ts"

function setSimulationIdInURL(simulationId: string): void {
  const url = new URL(window.location.href)
  url.searchParams.set("simulationId", simulationId)
  window.history.replaceState({}, "", url.toString())
}

function getSimulationIdFromURL(): string | null {
  const urlParams = new URLSearchParams(window.location.search)
  return urlParams.get("simulationId")
}

export function getSimulationFilter(): SimulationFilter {
  const urlParams = new URLSearchParams(window.location.search)
  const simulationId = urlParams.get("simulationId")

  const controlForm = document.getElementById("controlForm")! as HTMLFormElement
  const formData = new FormData(controlForm as HTMLFormElement)

  const period = formData.get("period")
    ? parseInt(formData.get("period") as string)
    : 1

  return { simulationId, period }
}

export function getSelectedSimulationId(): string {
  const selectElement = document.getElementById(
    "simulationId",
  ) as HTMLSelectElement

  // Get the current simulation ID from the URL or fallback to the select element's default value
  return getSimulationIdFromURL() || selectElement.value!
}

export function initializeSimulationSelectInput(
  simulationIds: string[],
): string {
  addSimulationSelectInput(simulationIds)

  const selectElement = document.getElementById(
    "simulationId",
  ) as HTMLSelectElement

  // Get the current simulation ID from the URL or fallback to the select element's default value
  const simulationId: string = getSelectedSimulationId()

  // Set the select element's value
  selectElement.value = simulationId

  // Update the URL without reloading
  setSimulationIdInURL(simulationId)

  // Add event listener to select element
  selectElement.addEventListener("change", (event) => {
    const selectedSimulationId = (event.target as HTMLSelectElement).value
    setSimulationIdInURL(selectedSimulationId)
  })

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
    `
		select step, description
		from Period
		join simulation on (simulation.simulation_id = period.simulation_id)
		where simulation_name = :simulationId
		`,
    { ":simulationId": simulationId },
  )
  const periods = unpackDBResult(periodIdsQueryResult[0])

  console.log("Periods", periods)
  const periodSelect = document.getElementById("period")! as HTMLSelectElement
  periodSelect.innerHTML = ""

  periods.forEach((period, i) => {
    const id = period.step
    const option = document.createElement("option")
    option.value = id.toString()
    option.text = id.toString()
    if (i === periods.length - 1) option.selected = true
    periodSelect?.appendChild(option)
  })

  const periodList = document.getElementById("periods")!
  periodList.innerHTML = ""

  periods.forEach((period, i) => {
    if (period.description !== null) {
      const li = document.createElement("li")
      li.innerHTML =
        "<strong>Period " + (i + 1) + "</strong>: " + period.description
      li.dataset.step = period.step
      li.className = "period"
      periodList?.appendChild(li)

      li.addEventListener("mouseenter", (_) => {
        if (periodSelect.value != period.step) {
          periodSelect.value = period.step
          periodSelect.dispatchEvent(new Event("change"))
        }
      })
      li.addEventListener("mouseleave", (_) => {
        periodSelect.selectedIndex = periodSelect.options.length - 1
        periodSelect.dispatchEvent(new Event("change"))
      })
    }
  })
}

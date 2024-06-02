import { SimulationFilter } from "./types.ts"
import { unpackDBResult } from "./database.ts"

export function getSimulationFilter(): SimulationFilter {
  const urlParams = new URLSearchParams(window.location.search)
  const simulationName = urlParams.get("simulationName")

  const controlForm = document.getElementById("controlForm")! as HTMLFormElement
  const formData = new FormData(controlForm as HTMLFormElement)

  const period = formData.get("period")
    ? parseInt(formData.get("period") as string)
    : 1

  return { simulationName: simulationName, period: period }
}

export function initializeSimulationSelectInput(
  simulationNames: string[],
): string {
  addSimulationSelectInput(simulationNames)

  const selectElement = document.getElementById(
    "simulationName",
  ) as HTMLSelectElement

  // Get the current simulation ID from the URL or fallback to the select element's default value
  const simulationName: string = getSelectedSimulationName()

  selectElement.value = simulationName

  // Update the URL without reloading
  setSimulationNameInURL(simulationName)

  selectElement.addEventListener("change", (event) => {
    const selectedSimulationName = (event.target as HTMLSelectElement).value
    setSimulationNameInURL(selectedSimulationName)
  })

  return simulationName
}

function addSimulationSelectInput(simulationNames: string[]) {
  const simulationSelect = document.getElementById(
    "simulationName",
  ) as HTMLSelectElement
  simulationSelect.innerHTML = ""
  simulationNames.forEach((id, i) => {
    const option = document.createElement("option")
    option.value = id
    option.text = id
    if (i === 0) option.selected = true
    simulationSelect?.appendChild(option)
  })
}

export function getSelectedSimulationName(): string {
  const selectElement = document.getElementById(
    "simulationName",
  ) as HTMLSelectElement

  // Get the current simulation ID from the URL or fallback to the select element's default value
  return getSimulationNameFromURL() || selectElement.value!
}

function getSimulationNameFromURL(): string | null {
  const urlParams = new URLSearchParams(window.location.search)
  return urlParams.get("simulationName")
}

function setSimulationNameInURL(simulationName: string): void {
  const url = new URL(window.location.href)
  url.searchParams.set("simulationName", simulationName)
  window.history.replaceState({}, "", url.toString())
}

export function setPeriodsSelectInput(db: any, simulationName: string) {
  const periodsQueryResult = db.exec(
    `
    select step, description
    from Period
    join Simulation on (Simulation.simulation_id = Period.simulation_id)
    where simulation_name = :simulationName 
    `,
    { ":simulationName": simulationName },
  )
  const periods = unpackDBResult(periodsQueryResult[0])

  const periodHidden = document.getElementById("period")! as HTMLSelectElement

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
        if (periodHidden.value != period.step) {
          periodHidden.value = period.step
          periodHidden.dispatchEvent(new Event("change"))
        }
      })
      li.addEventListener("mouseleave", (_) => {
        periodHidden.selectedIndex = periodHidden.options.length - 1
        periodHidden.dispatchEvent(new Event("change"))
      })
    }
  })
}

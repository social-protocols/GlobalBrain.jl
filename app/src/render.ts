import {
  getData,
  getRootPostIds,
  getTagId,
  type VisualizationData,
} from "./database"
import { getLookups, type LookupData } from "./lookups"
import {
  Effect,
  PostWithScore,
  PostWithScoreWithPosition,
  SimulationFilter,
  VoteEvent,
} from "./types"
import { getSimulationFilterFromControlForm } from "./control-form.ts"

import * as d3 from "d3"

const CHART_WIDTH = 1600
const CHART_HEIGHT = 1600

export const CHILD_NODE_SPREAD = 400
export const CHILD_PARENT_OFFSET = 150

export const ROOT_POST_RECT_X = 100
export const ROOT_POST_RECT_Y = 30

export const POST_RECT_WIDTH = 250
export const POST_RECT_HEIGHT = 65

export const LINE_PLOT_X_STEP_SIZE = 20
export const LINEPLOT_WIDTH = 300
export const LINEPLOT_HEIGHT = 100

const UP_ARROW_SVG_POLYGON_COORDS = "0,10 10,10 5,0"
const DOWN_ARROW_SVG_POLYGON_COORDS = "0,0 10,0 5,10"

export async function render(db: any, simulationFilter: SimulationFilter) {
  let simulationId = simulationFilter.simulationId!
  let tagId = await getTagId(db, simulationId)

  let period = simulationFilter.period!
  // TODO: handle case with several root post ids
  let rootPostIds = await getRootPostIds(db, tagId)
  let rootPostId = rootPostIds[0].post_id

  let data = await getData(db, tagId, rootPostId, period)
  let lookups = getLookups(data)

  let root = lookups.postsByPostId[lookups.childrenIdsByPostId[0][0]]

  d3.select("div#tree-chart svg").remove()
  const svg = d3
    .select("div#tree-chart")
    .append("svg")
    .attr("width", CHART_WIDTH)
    .attr("height", CHART_HEIGHT)

  svg.html("")

  // -----------------------------------
  // --- LINE PLOTS --------------------
  // -----------------------------------

  // await renderLineChart(svg, data, lookups, root.id)

  await renderTreeChart(svg, data, lookups)

  let rootPostScore = data.scoreEvents.filter((d) => d["post_id"] === root.id)

  function setPeriodHandler(n: number) {
    const voteEvent = rootPostScore[n]!
    if (voteEvent === undefined) {
      return
    }
    const voteEventTime = voteEvent.vote_event_time

    const e = document.getElementById("period")! as HTMLSelectElement
    if (e.value != voteEventTime) {
      e.value = voteEventTime
      const simulationFilter = getSimulationFilterFromControlForm()
      render(db, simulationFilter)
    }
  }

  await renderGoogleLineChart(data, lookups, root.id, setPeriodHandler)
}

function getXAxis(
  rootId: number,
  lookups: LookupData,
): [number, number, Array<number>] {
  let minVoteEventId: number = d3.min(
    lookups.voteEventsByPostId[rootId],
    (d: VoteEvent) => d.vote_event_id,
  )!
  let maxVoteEventId: number = d3.max(
    lookups.voteEventsByPostId[rootId],
    (d: VoteEvent) => d.vote_event_id,
  )!

  let maxVoteIdLower10 = Math.floor(maxVoteEventId / 10) * 10
  let minVoteIdLower10 = Math.floor(minVoteEventId / 10) * 10

  let steps = Math.floor(
    (maxVoteIdLower10 + LINE_PLOT_X_STEP_SIZE - minVoteIdLower10) /
      LINE_PLOT_X_STEP_SIZE,
  )

  const xTickValues = [...Array(steps).keys()].map(
    (v) => v * LINE_PLOT_X_STEP_SIZE + minVoteIdLower10,
  )

  return [minVoteEventId, maxVoteEventId, xTickValues]
  // , maxVoteEventId, xTickValues
}

async function renderLineChart(
  svg: d3.Selection<SVGSVGElement, unknown, HTMLElement, any>,
  data: VisualizationData,
  lookups: LookupData,
  rootId: number,
) {
  let rootPostScore = data.scoreEvents.filter((d) => d["post_id"] === rootId)

  let [minVoteEventId, maxVoteEventId, xTickValues] = getXAxis(rootId, lookups)

  let scaleProbability = d3
    .scaleLinear()
    .domain([0, 1])
    .range([LINEPLOT_HEIGHT, 0])
  let scaleVoteId = d3
    .scaleLinear()
    .domain([minVoteEventId, maxVoteEventId])
    .range([0, LINEPLOT_WIDTH])

  let lineGroup = svg.append("g").attr("transform", "translate(30, 10)")
  // Add axes
  let xAxis = d3.axisBottom(scaleVoteId).tickValues(xTickValues).tickSize(3)
  let yAxis = d3
    .axisLeft(scaleProbability)
    .tickValues([0.0, 0.25, 0.5, 0.75, 1.0])
    .tickSize(3)
  lineGroup.append("g").attr("transform", "translate(0, 101)").call(xAxis)
  lineGroup.append("g").call(yAxis)

  let lineGenerator = d3.line()

  // Overall probability line
  let pathDataOverallProb: Array<[number, number]> = rootPostScore.map((e) => {
    // TODO: rename "o" back to "overallProb"
    return [scaleVoteId(e.vote_event_id), scaleProbability(e.o)]
  })

  let pathOverallProb = lineGenerator(pathDataOverallProb)
  lineGroup
    .append("path")
    .attr("d", pathOverallProb)
    .attr("stroke", "black")
    .attr("stroke-width", 2)
    .attr("opacity", 0.5)
    .attr("fill", "none")

  // Informed probability line
  let pathDataP: Array<[number, number]> = rootPostScore.map((e) => {
    return [scaleVoteId(e.vote_event_id), scaleProbability(e.p)]
  })
  let pathP = lineGenerator(pathDataP)
  lineGroup
    .append("path")
    .attr("d", pathP)
    .attr("stroke", "steelblue")
    .attr("stroke-width", 2)
    .attr("opacity", 0.5)
    .attr("fill", "none")
}

async function renderTreeChart(
  svg: d3.Selection<SVGSVGElement, unknown, HTMLElement, any>,
  data: VisualizationData,
  lookups: LookupData,
) {
  // -----------------------------------
  // --- EDGES -------------------------
  // -----------------------------------

  type Edge = {
    parent: PostWithScoreWithPosition | null
    post: PostWithScoreWithPosition
    edgeData: Effect
  }

  let edges: Edge[] = data.discussionTree
    .filter((row) => row["parent_id"] !== null)
    .map((row) => {
      return {
        parent: lookups.postsByPostId[row["parent_id"]],
        post: lookups.postsByPostId[row["id"]],
        edgeData:
          lookups.effectsByPostIdNoteId[`${row["parent_id"]}-${row["id"]}`],
      }
    })

  let edgeData = svg
    .append("g")
    .selectAll("g")
    .data(edges, (d: any) => d.parent?.id + "-" + d.post.id)

  let edgeGroup = edgeData
    .join("g")
    .attr("id", (d) => "edgeGroup" + d.parent?.id + "-" + d.post["id"])

  edgeGroup
    .append("line")
    .attr("x1", (d) => d.parent?.x! + POST_RECT_WIDTH / 2)
    .attr("y1", (d) => d.parent?.y! + POST_RECT_HEIGHT)
    .attr("x2", (d) => d.post.x + POST_RECT_WIDTH / 2)
    .attr("y2", (d) => d.post.y)
    .attr("stroke-width", (d) => {
      // measured in bits (i.e., [0, Inf)), we clamp at 10 and scale down to [0, 1]
      let maxWidth = 10
      let width = Math.min(maxWidth, d.edgeData.magnitude) / maxWidth
      return 1 + width * 10
    })
    .attr("stroke", (d) => {
      return d.edgeData.p > d.edgeData.q ? "forestgreen" : "tomato"
    })
    .style("stroke-linecap", "round")

  // -----------------------------------
  // --- NODES -------------------------
  // -----------------------------------

  let nodeData = svg
    .append("g")
    .selectAll("g")
    .data(
      data.discussionTree.map((row) => lookups.postsByPostId[row.id]),
      (d: any) => d.id,
    )

  let nodeGroup = nodeData
    .join("g")
    .attr("id", (d) => "nodeGroup" + d.id)
    .attr("transform", (d) => `translate(${d.x}, ${d.y})`)

  // Post container
  nodeGroup
    .append("rect")
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", POST_RECT_WIDTH)
    .attr("height", POST_RECT_HEIGHT)
    // .style("fill", "white")
    .attr("stroke", "black")
  // TODO: fix -> no parentP and parentQ on discussionTree anymore
  // .attr("stroke", (d) => {
  //   if (d.parentP == d.parentQ) {
  //     return "black"
  //   }
  //   return d.parentP > d.parentQ ? "forestgreen" : "tomato"
  // })

  // Post content
  nodeGroup
    .append("foreignObject")
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", POST_RECT_WIDTH)
    .attr("height", POST_RECT_HEIGHT)
    .append("xhtml:div")
    .style("width", `${POST_RECT_WIDTH}px`)
    .style("height", `${POST_RECT_HEIGHT}px`)
    .style("overflow", "auto")
    .style("box-sizing", "border-box")
    .style("padding", "5px")
    .classed("post-content", true)
    .html((d) => d.content)

  // TODO: fix (doesn't work since porting to TypeScript)
  // https://stackoverflow.com/questions/2685911/is-there-a-way-to-round-numbers-into-a-reader-friendly-format-e-g-1-1k
  function numberToText(num: number) {
    let decPlaces = 10
    let abbrev = ["k", "m", "b", "t"]
    let numStringified = ""
    for (let i = abbrev.length - 1; i >= 0; i--) {
      let size = Math.pow(10, (i + 1) * 3)
      if (size <= num) {
        num = Math.round((num * decPlaces) / size) / decPlaces
        if (num == 1000 && i < abbrev.length - 1) {
          num = 1
          i++
        }
        numStringified = num + abbrev[i]
        break
      }
    }
    return numStringified
  }

  function addUpvoteProbabilityBar(
    groupSelection: d3.Selection<SVGGElement, any, SVGGElement, unknown>,
    x: number,
    fill: string,
    heightPercentageFunc: (post: PostWithScoreWithPosition) => number,
    opacityFunc: (post: PostWithScoreWithPosition) => number,
    displayFunc: (post: PostWithScoreWithPosition) => string,
  ) {
    let group = groupSelection.append("g")

    group
      .append("rect")
      .attr("width", 25)
      .attr("height", POST_RECT_HEIGHT)
      .attr("x", x)
      .attr("y", 0)
      .attr("opacity", 0.05)
      .style("fill", "transparent")
      .attr("stroke", "black")
      .attr("display", displayFunc)

    group
      .append("rect")
      .attr("width", 25)
      .attr("height", (d) => heightPercentageFunc(d) * POST_RECT_HEIGHT)
      .attr("x", x)
      .attr("y", (d) => {
        return POST_RECT_HEIGHT - heightPercentageFunc(d) * POST_RECT_HEIGHT
      })
      .attr("opacity", opacityFunc)
      .style("fill", fill)
      .attr("display", displayFunc)
  }

  let voteGroup = nodeGroup.append("g")

  // Upvote arrow
  voteGroup
    .append("g")
    .attr("transform", `translate(-20, ${POST_RECT_HEIGHT / 2 - 15})`)
    .append("polygon")
    .attr("points", UP_ARROW_SVG_POLYGON_COORDS)
    .attr("opacity", (d) => d.o_count / d.o_size)

  // Downvote arrow
  voteGroup
    .append("g")
    .attr("transform", `translate(-20, ${POST_RECT_HEIGHT / 2 + 5})`)
    .append("polygon")
    .attr("points", DOWN_ARROW_SVG_POLYGON_COORDS)
    .attr("opacity", (d) => (d.o_size - d.o_count) / d.o_size)

  // Upvote count
  voteGroup
    .append("text")
    .text((d) => numberToText(d.o_count))
    .attr("width", 10)
    .attr("x", -15)
    .attr("y", POST_RECT_HEIGHT / 2 - 20)
    .attr("text-anchor", "middle")

  // Downvote count
  voteGroup
    .append("text")
    .text((d) => numberToText(d.o_size - d.o_count))
    .attr("width", 10)
    .attr("x", -15)
    .attr("y", POST_RECT_HEIGHT / 2 + 30)
    .attr("text-anchor", "middle")

  addUpvoteProbabilityBar(
    voteGroup,
    -55,
    "black",
    (d: PostWithScore) =>
      d.o_count / d.o_size == 0 ? 0.05 : d.o_count / d.o_size,
    (d: PostWithScore) => 1 - 1 / (1 + 0.3 * d.o_size),
    () => "inline",
  )

  addUpvoteProbabilityBar(
    voteGroup,
    -85,
    "steelblue",
    (d: PostWithScore) => {
      let edges = lookups.childEffectsByPostId[d.id] || []
      let topNoteEdge = edges[0]
      return topNoteEdge && topNoteEdge.p_count !== 0
        ? topNoteEdge.p_count / topNoteEdge.p_size
        : 0.05
    },
    (d: PostWithScore) => {
      let edges = lookups.childEffectsByPostId[d.id] || []
      let topNoteEdge = edges[0]
      return topNoteEdge && 1 - 1 / (1 + 0.3 * topNoteEdge.p_size)
    },
    (d: PostWithScore) =>
      lookups.childrenIdsByPostId[d.id] ? "inline" : "none",
  )
}

async function renderGoogleLineChart(
  data: VisualizationData,
  lookups: LookupData,
  rootId: number,
  setPeriodHandler: (arg0: number) => void,
) {
  let rootPostScore = data.scoreEvents.filter((d) => d["post_id"] === rootId)

  let [_minVoteEventId, _maxVoteEventId, xTickValues] = getXAxis(
    rootId,
    lookups,
  )

  let dataPoints: Array<[number, number, number, string | undefined]> =
    rootPostScore.map((e, _) => {
      return [e.vote_event_id, e.o, e.p, undefined]
    })

  var voteEventTime = 0
  let p = 0
  for (var i = 0; i < rootPostScore.length; i++) {
    // for (var e of rootPostScore) {
    const e = rootPostScore[i]
    const t = e.vote_event_time
    if (t !== voteEventTime) {
      p += 1
      dataPoints[i][3] = "Period " + p
      voteEventTime = t
    }
  }

  var plotDiv = document.getElementById("line-chart")!

  var plotData = new google.visualization.DataTable()
  plotData.addColumn("number", "Time")
  plotData.addColumn("number", "overall")
  plotData.addColumn("number", "informed")
  plotData.addColumn({ type: "string", role: "annotation" })
  // plotData.addColumn({type: 'string', role: 'annotationText'});

  plotData.addRows(dataPoints)

  var options = {
    backgroundColor: { fill: "transparent" },
    dataOpacity: 0.85,
    hAxis: {
      title: "Time",
      logScale: false,
      ticks: xTickValues,
    },
    vAxis: {
      title: "Probability",
      logScale: false,
      ticks: [0.0, 0.25, 0.5, 0.75, 1.0],
    },
    lineWidth: 2,
    colors: ["black", "lightblue", "#AF7FDF", "#6FAEAE", "green", "pink"],
    chartArea: { left: 40, top: 10, bottom: 40, right: 40, width: "95%" },
    height: 160,
    legend: { position: "bottom" as google.visualization.ChartLegendPosition },
    crosshair: { trigger: "both" },
    displayAnnotations: true,
    annotations: {
      boxStyle: {},
      stem: {
        color: "black",
        length: 30,
      },

      textStyle: {
        color: "brown",
        fontSize: 11,
        bold: true,
      },
      alwaysOutside: true,
    },
    // theme: 'material',
    // title: "Estimated Upvote Probability",
  }

  var chart = new google.visualization.LineChart(plotDiv)

  function onmouseoverHandler(properties: { row: number; column: number }) {
    // setPeriodHandler(properties.row)
  }

  function selectHandler(e: MouseEvent) {
    var s = chart.getSelection()[0]
    if (s !== undefined) {
      setPeriodHandler(s.row!)
    }
  }

  google.visualization.events.addListener(chart, "select", selectHandler)
  google.visualization.events.addListener(
    chart,
    "onmouseover",
    onmouseoverHandler,
  )

  chart.draw(plotData, options)
}

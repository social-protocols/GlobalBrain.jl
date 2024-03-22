import './style.css'
import initSqlJs from 'sql.js'
import wasmUrl from "../node_modules/sql.js/dist/sql-wasm.wasm?url";
import * as d3 from 'd3'
import relativeEntropy from './entropy.ts'
import {
  Effect,
  EffectEvent,
  PostWithScore,
  SimulationFilter,
  VoteEvent,
} from './types.ts'
import {
  Lookup,
  getLookupPostsByPostId,
  getLookupVoteEventsByPostId,
  getLookupEffectsByPostIdNoteId,
  getLookupEffectEventsByPostId,
  getLookupCurrentEffectsByPostId,
  getLookupChildrenByPostId,
  getLookupChildEffectsByPostId,
} from './lookups.ts';

// Architecture:
// - Unidirectional data flow from mutable state to view
// - central mutable state, which represents the form
// - Once form is submitted:
//   - the state is updated
//   - state is used to fetch data from the database
//   - data is used for derived lookups, created by pure functions in another file
//   - A single render call, which takes the data and renders/updates the view


const CHILD_NODE_SPREAD = 400
const CHILD_PARENT_OFFSET = 150

const ROOT_POST_RECT_X = 450
const ROOT_POST_RECT_Y = 30

const POST_RECT_WIDTH = 250
const POST_RECT_HEIGHT = 65

const LINE_PLOT_X_STEP_SIZE = 20
const LINEPLOT_WIDTH = 300
const LINEPLOT_HEIGHT = 100

const UP_ARROW_SVG_POLYGON_COORDS = "0,10 10,10 5,0"
const DOWN_ARROW_SVG_POLYGON_COORDS = "0,0 10,0 5,10"

async function rerender(simulationFilter: SimulationFilter) {
  console.log("new simulation filter", simulationFilter)
  d3.select("svg").remove()
  const svg = d3.select("div#app").append("svg")
  // TODO
}

function addSimulationSelectInput(simulationIds: number[]) {
  const simulationSelect = document.getElementById("simulationId")
  simulationIds.forEach((id, i) => {
    const option = document.createElement("option")
    option.value = id.toString()
    option.text = id.toString()
    if (i === 0) option.selected = true
    simulationSelect?.appendChild(option)
  })
}

function unpackDBResult(result: { columns: string[], values: any[] }) {
  const columns = result.columns;
  const values = result.values;
  return values.map((value) => {
    return columns.reduce<Record<string, any>>((obj, col, index) => {
      obj[col] = value[index];
      return obj;
    }, {});
  })
}

async function getDiscussionTree(db: any, postId: number, period: number) {
  const stmt = db.prepare(`
    WITH currentPosts AS(
      SELECT *
      FROM post
      WHERE created_at <= :period
    )
    , currentScoreWithMax AS(
      SELECT MAX(vote_event_id), *
      FROM ScoreEvent
      WHERE vote_event_time <= :period
      GROUP BY tag_id, post_id
    )
    , currentScore AS(
      SELECT
          vote_event_id
        , vote_event_time
        , tag_id
        , post_id
        , top_note_id
        , o
        , o_count
        , o_size
        , p
        , score
      FROM currentScoreWithMax
    )
    , idsRecursive AS(
      SELECT *
      FROM currentPosts
      WHERE id = :root_post_id
      UNION ALL
      SELECT p2.*
      FROM currentPosts p2
      JOIN idsRecursive ON p2.parent_id = idsRecursive.id
    )
    SELECT
        idsRecursive.*
      , vote_event_id
      , vote_event_time
      , top_note_id
      , o
      , o_count
      , o_size
      , p
      , score
    FROM idsRecursive
    LEFT OUTER JOIN currentScore
    ON idsRecursive.id = currentScore.post_id
  `)
  stmt.bind({ ':root_post_id': postId, ':period': period })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}


async function getEffects(db: any, tagId: number, period: number) {
  let stmt = db.prepare(`
    SELECT MAX(vote_event_id) AS max_id, *
    FROM EffectEvent
    WHERE tag_id = :tagId
    AND vote_event_time <= :period
    GROUP BY post_id, note_id
  `)
  stmt.bind({ ':tagId': tagId, ':period': period })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  const effectsWithMagnitude = res.map((effect) => {
    effect.magnitude = relativeEntropy(effect.p, effect.q)
    return effect
  })
  return effectsWithMagnitude
}

async function getScoreEvent(db: any) {
  let stmt = db.prepare(`SELECT * FROM ScoreEvent`)
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

async function getEffectEvent(db: any) {
  let stmt = db.prepare(`SELECT * FROM EffectEvent`)
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  const effectsWithMagnitude = res.map((effect) => {
    effect.magnitude = relativeEntropy(effect.p, effect.q)
    return effect
  })
  return effectsWithMagnitude
}

async function getVoteEvent(db: any) {
  let stmt = db.prepare(`SELECT * FROM VoteEvent`)
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

async function main() {
  const sqlPromise = initSqlJs({ locateFile: () => wasmUrl })
  const dataPromise = fetch("/sim.db").then(res => res.arrayBuffer())
  const [SQL, buf] = await Promise.all([sqlPromise, dataPromise])
  const db = new SQL.Database(new Uint8Array(buf))

  const simulationsQueryResult = db.exec("select id from tag")
  const simulationIds = unpackDBResult(simulationsQueryResult[0]).map((x: any) => x.id)
  addSimulationSelectInput(simulationIds)


  let simulationFilter: SimulationFilter = {
    simulationId: null,
    postId: null,
    period: null,
  }


  function handleControlFormSubmit(e: SubmitEvent) {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    simulationFilter = {
      simulationId: formData.get("simulationId") ? parseInt(formData.get("simulationId") as string) : null,
      postId: formData.get("postId") ? parseInt(formData.get("postId") as string) : null,
      period: formData.get("period") ? parseInt(formData.get("period") as string) : null,
    }
    rerender(simulationFilter)
  }

  const controlForm = document.getElementById("controlForm")
  controlForm?.addEventListener("submit", handleControlFormSubmit)

  // to test the form submission
  // document.getElementById("submitbutton")!.click()


  let tagId = 3
  let period = 3
  let rootPostId = 4
  let discussionTree = await getDiscussionTree(db, rootPostId, period)
  let effects = await getEffects(db, tagId, period)
  let effectEvents = await getEffectEvent(db)
  let scoreEvents = await getScoreEvent(db)
  let voteEvents = await getVoteEvent(db)

  let postsByPostId: Lookup<PostWithScore> = getLookupPostsByPostId(discussionTree)
  let voteEventsByPostId: Lookup<VoteEvent[]> = getLookupVoteEventsByPostId(voteEvents, postsByPostId)
  let effectsByPostIdNoteId: Lookup<Effect> = getLookupEffectsByPostIdNoteId(effects)
  let effectEventsByPostId: Lookup<EffectEvent[]> = getLookupEffectEventsByPostId(effectEvents)
  let currentEffects: Lookup<Effect> = getLookupCurrentEffectsByPostId(postsByPostId, effectEventsByPostId)
  let childrenByPostId: Lookup<PostWithScore[]> = getLookupChildrenByPostId(discussionTree, effectsByPostIdNoteId)
  let childEffectsByPostId: Lookup<Effect[]> = getLookupChildEffectsByPostId(discussionTree, effectsByPostIdNoteId)

  d3.select("svg").remove()
  const svg = d3.select("div#app")
    .append("svg")
    .attr("width", 1600)
    .attr("height", 1600)

  function assignPositionsFromRootRecursive(postId: number) {
    let post = postsByPostId[postId]
    if (postId in childrenByPostId) {
      let spread = 0
      let stepSize = 0
      if (childrenByPostId[postId].length > 1) {
        spread = CHILD_NODE_SPREAD
        stepSize = spread / (childrenByPostId[postId].length - 1)
      }
      childrenByPostId[postId].forEach((child, i) => {
        if (post.x === null) throw new Error("post.x is null")
        if (post.y === null) throw new Error("post.x is null")
        child.x = post.x + i * stepSize
        child.y = post.y + CHILD_PARENT_OFFSET
        assignPositionsFromRootRecursive(child["id"])
      })
    }
  }

  let root = childrenByPostId[0][0]
  root.x = ROOT_POST_RECT_X
  root.y = ROOT_POST_RECT_Y
  assignPositionsFromRootRecursive(root["id"])

  svg.html("")

  // -----------------------------------
  // --- LINE PLOTS --------------------
  // -----------------------------------

  let rootPostScore = scoreEvents.filter((d) => d["post_id"] === root["id"])

  let minVoteEventId = d3.min(voteEventsByPostId[root.id], (d) => d.vote_event_id)!
  let maxVoteEventId = d3.max(voteEventsByPostId[root.id], (d) => d.vote_event_id)!

  let scaleProbability = d3.scaleLinear()
    .domain([0, 1])
    .range([LINEPLOT_HEIGHT, 0])
  let scaleVoteId = d3.scaleLinear()
    .domain([minVoteEventId, maxVoteEventId])
    .range([0, LINEPLOT_WIDTH])

  let lineGroup = svg
    .append("g")
    .attr("transform", "translate(30, 10)")

  let maxVoteIdLower10 = Math.floor((maxVoteEventId) / 10) * 10
  let minVoteIdLower10 = Math.floor((minVoteEventId) / 10) * 10
  let steps = ((maxVoteIdLower10 + LINE_PLOT_X_STEP_SIZE) - minVoteIdLower10) / LINE_PLOT_X_STEP_SIZE
  let xTickValues = [...Array(steps).keys()].map(v => (v * LINE_PLOT_X_STEP_SIZE) + minVoteIdLower10)

  // Add axes
  let xAxis = d3.axisBottom(scaleVoteId)
    .tickValues(xTickValues)
    .tickSize(3)
  let yAxis = d3.axisLeft(scaleProbability)
    .tickValues([0.0, 0.25, 0.5, 0.75, 1.0])
    .tickSize(3)
  lineGroup
    .append("g")
    .attr("transform", "translate(0, 101)")
    .call(xAxis)
  lineGroup
    .append("g")
    .call(yAxis)

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


  // -----------------------------------
  // --- EDGES -------------------------
  // -----------------------------------

  type Edge = {
    parent: PostWithScore | null,
    post: PostWithScore,
    edgeData: Effect,
  }

  let edges: Edge[] = discussionTree
    .filter((row) => row["parent_id"] !== null)
    .map((row) => {
      return {
        parent: postsByPostId[row["parent_id"]],
        post: postsByPostId[row["id"]],
        edgeData: effectsByPostIdNoteId[`${row["parent_id"]}-${row["id"]}`]
      }
    })

  let edgeData = svg
    .append("g")
    .selectAll("g")
    .data(edges, (d: Edge) => d.parent!["id"] + "-" + d.post["id"])

  let edgeGroup = edgeData
    .join("g")
    .attr("id", (d) => "edgeGroup" + d.parent["id"] + "-" + d.post["id"])

  edgeGroup
    .append("line")
    .attr("x1", (d) => d.parent.x + POST_RECT_WIDTH / 2)
    .attr("y1", (d) => d.parent.y + POST_RECT_HEIGHT)
    .attr("x2", (d) => d.post.x + POST_RECT_WIDTH / 2)
    .attr("y2", (d) => d.post.y)
    .attr("stroke-width", (d) => {
      // measured in bits (i.e., [0, Inf)), we clamp at 10 and scale down to [0, 1]
      let maxWidth = 10
      let width = Math.min(maxWidth, d.edgeData.magnitude) / maxWidth
      return 1 + width * 200
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
    .data(discussionTree, (d) => d["id"])

  let nodeGroup = nodeData
    .join("g")
    .attr("id", (d) => "nodeGroup" + d["id"])
    .attr("transform", (d) => `translate(${d.x}, ${d.y})`)

  // Post container
  nodeGroup.append("rect")
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", POST_RECT_WIDTH)
    .attr("height", POST_RECT_HEIGHT)
    .style("fill", "white")
    .attr("stroke", "black")
  // TODO: fix -> no parentP and parentQ on discussionTree anymore
  // .attr("stroke", (d) => {
  //   if (d.parentP == d.parentQ) {
  //     return "black"
  //   }
  //   return d.parentP > d.parentQ ? "forestgreen" : "tomato"
  // })

  // Post content
  nodeGroup.append("foreignObject")
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
        num = Math.round(num * decPlaces / size) / decPlaces
        if ((num == 1000) && (i < abbrev.length - 1)) {
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
    groupSelection,
    x: number,
    fill: string,
    heightPercentageFunc: Function,
    opacityFunc: Function,
    displayFunc: Function,
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
    (d: PostWithScore) => d.o_count / d.o_size == 0 ? 0.05 : d.o_count / d.o_size,
    (d: PostWithScore) => 1 - (1 / (1 + 0.3 * d.o_size)),
    () => "inline"
  )

  addUpvoteProbabilityBar(
    voteGroup,
    -85,
    "steelblue",
    (d: PostWithScore) => {
      let edges = childEffectsByPostId[d.id] || []
      let topNoteEdge = edges[0]
      return topNoteEdge && (topNoteEdge.p_count !== 0) ?
        topNoteEdge.p_count / topNoteEdge.p_size :
        0.05
    },
    (d: PostWithScore) => {
      let edges = childEffectsByPostId[d.id] || []
      let topNoteEdge = edges[0]
      return topNoteEdge && 1 - (1 / (1 + 0.3 * topNoteEdge.p_size))
    },
    (d: PostWithScore) => childrenByPostId[d.id] ? "inline" : "none"
  )
}

main()

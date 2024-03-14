// TODO:
// -- shift further right according to whether child node has siblings (so that posts are not plotted on top of each other)
// -- plot edge with low opacity how much the note *would* have been affected by the parent if there were no sub top note

try {

const period = r2d3.data.period
const discussionTree = r2d3.data.discussion_tree.filter((post) => post.createdAt <= period)
const effects = r2d3.data.effects
const scoreEvents = r2d3.data.score_events
const voteEvents = r2d3.data.vote_events

const CHILD_NODE_SPREAD = 400
const CHILD_PARENT_OFFSET = 150

const ROOT_POST_RECT_X = 450
const ROOT_POST_RECT_Y = 30

const POST_RECT_WIDTH = 250
const POST_RECT_HEIGHT = 65

const LINEPLOT_X_OFFSET = -5
const LINEPLOT_Y_OFFSET = 120

const LINEPLOT_WIDTH = 300
const LINEPLOT_HEIGHT = 100

const USER_ICON_SVG_PATH =
    "M224 256A128 128 0 1 0 224 0a128 128 0 1 0 0" +
    " 256zm-45.7 48C79.8 304 0 383.8 0 482.3C0 498.7" +
    " 13.3 512 29.7 512H418.3c16.4 0 29.7-13.3 29.7-29.7C448" +
    " 383.8 368.2 304 269.7 304H178.3z"
const UP_ARROW_SVG_POLYGON_COORDS = "0,10 10,10 5,0"
const DOWN_ARROW_SVG_POLYGON_COORDS = "0,0 10,0 5,10"

let postsByPostId = {}
discussionTree.forEach((d) => {
  postsByPostId[d["postId"]] = d
})

let voteEventsByPostId = {}
voteEvents.forEach((voteEvent) => {
  let postId = voteEvent.postId
  if (postsByPostId[postId]) {
    if (!(postId in voteEventsByPostId)) {
      voteEventsByPostId[postId] = [voteEvent]
    } else {
      voteEventsByPostId[postId].push(voteEvent)
    }
  }
})

let effectsByPostIdNoteId = {}
effects.forEach((effect) => {
  effectsByPostIdNoteId[`${effect["postId"]}-${effect["noteId"]}`] = effect
})

let childPostsByPostId = {}
let childEffectsByPostId = {}
discussionTree.forEach((post) => {
  let parentId = post["parentId"]
  if (parentId !== null) {
    let effect = effectsByPostIdNoteId[`${parentId}-${post["postId"]}`]
    if (!(parentId in childPostsByPostId)) {
      childEffectsByPostId[parentId] = [effect]
    } else {
      childEffectsByPostId[parentId].push(effect)
      childEffectsByPostId[parentId].sort((a, b) => b.magnitude - a.magnitude)
    }
  }

  if (!(parentId in childPostsByPostId)) {
    childPostsByPostId[parentId] = [post]
  } else {
    childPostsByPostId[parentId].push(post)
    childPostsByPostId[parentId].sort((a, b) => {
      let effectA = effectsByPostIdNoteId[`${parentId}-${a["postId"]}`].magnitude
      let effectB = effectsByPostIdNoteId[`${parentId}-${b["postId"]}`].magnitude
      return effectB - effectA
    })
  }
})

function assignPositionsFromRootRecursive(postId) {
  let post = postsByPostId[postId]
  if (postId in childPostsByPostId) {
    let spread = 0
    let stepSize = 0
    if (childPostsByPostId[postId].length > 1) {
      spread = CHILD_NODE_SPREAD
      stepSize = spread / (childPostsByPostId[postId].length - 1)
    }
    childPostsByPostId[postId].forEach((child, i) => {
      child.x = post.x + i * stepSize
      child.y = post.y + CHILD_PARENT_OFFSET
      assignPositionsFromRootRecursive(child["postId"])
    })
  }
}

let root = childPostsByPostId["null"][0]
root.x = ROOT_POST_RECT_X
root.y = ROOT_POST_RECT_Y
assignPositionsFromRootRecursive(root["postId"])

r2d3.svg.html("")

// -----------------------------------
// --- LINE PLOTS --------------------
// -----------------------------------

let rootPostScore = scoreEvents.filter((d) => d["postId"] === root["postId"])
let rootPostVotes = voteEvents.filter((d) => d["postId"] === root["postId"])

let minVoteEventId = d3.min(voteEventsByPostId[root.postId], (d) => d.voteEventId)
let maxVoteEventId = d3.max(voteEventsByPostId[root.postId], (d) => d.voteEventId)

let scaleProbability = d3.scaleLinear()
  .domain([0, 1])
  .range([LINEPLOT_HEIGHT, 0])
let scaleVoteId = d3.scaleLinear()
  .domain([minVoteEventId, maxVoteEventId])
  .range([0, LINEPLOT_WIDTH])
let scaleUserColor = d3.scaleOrdinal()
  .domain(rootPostVotes.map((d) => d.userId))
  .range(d3.schemeSet2)

// Line data
let lineGenerator = d3.line()
let pathDataP = rootPostScore.map((e) => {
  return [scaleVoteId(e.voteEventId), scaleProbability(e.p)]
})
let pathP = lineGenerator(pathDataP)
let pathDataOverallProb = rootPostScore.map((e) => {
  return [scaleVoteId(e.voteEventId), scaleProbability(e.o)] // TODO: rename back to overallProb
})
let pathOverallProb = lineGenerator(pathDataOverallProb)

let lineGroup = r2d3.svg
  .append("g")
  .attr("transform", "translate(30, 10)")

// Add axes
let xAxis = d3.axisBottom(scaleVoteId)
  .tickValues([0, 5, 10, 15, 20])
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

// Add lines
lineGroup
  .append("path")
  .attr("d", pathOverallProb)
  .attr("stroke", "black")
  .attr("stroke-width", 2)
  .attr("opacity", 0.5)
  .attr("fill", "none")
lineGroup
  .append("path")
  .attr("d", pathP)
  .attr("stroke", "steelblue")
  .attr("stroke-width", 2)
  .attr("opacity", 0.5)
  .attr("fill", "none")

// Add up/down/clear sequence at the bottom of the chart

let upVoteEvents = rootPostVotes.filter((d) => d.vote == 1)
let downVoteEvents = rootPostVotes.filter((d) => d.vote == -1)
let clearVoteEvents = rootPostVotes.filter((d) => d.vote == 0)

lineGroup
  .append("g")
  .selectAll("polygon")
  .data(upVoteEvents)
  .join("polygon")
  .attr("points", (d) => {
    let x_base = scaleVoteId(d.voteEventId) + LINEPLOT_X_OFFSET
    let [x1, x2, x3] = [
      x_base,
      x_base + 10,
      x_base + 5
    ]
    let [y1, y2, y3] = [
      LINEPLOT_Y_OFFSET + 10,
      LINEPLOT_Y_OFFSET + 10,
      LINEPLOT_Y_OFFSET
    ]
    return `${x1},${y1} ${x2},${y2} ${x3},${y3}`
  })
  .attr("opacity", 0.5)
  .attr("fill", "green")

lineGroup
  .append("g")
  .selectAll("polygon")
  .data(downVoteEvents)
  .join("polygon")
  .attr("points", (d) => {
    let x_base = scaleVoteId(d.voteEventId) + LINEPLOT_X_OFFSET
    let [x1, x2, x3] = [
      x_base,
      x_base + 10,
      x_base + 5
    ]
    let [y1, y2, y3] = [
      LINEPLOT_Y_OFFSET + 0,
      LINEPLOT_Y_OFFSET + 0,
      LINEPLOT_Y_OFFSET + 10
    ]
    return `${x1},${y1} ${x2},${y2} ${x3},${y3}`
  })
  .attr("opacity", 0.5)
  .attr("fill", "red")

lineGroup
  .append("g")
  .selectAll("circle")
  .data(clearVoteEvents)
  .join("circle")
  .attr("cx", (d) => scaleVoteId(d.voteEventId) + LINEPLOT_X_OFFSET + 5)
  .attr("cy", LINEPLOT_Y_OFFSET + 5)
  .attr("r", 5)
  .attr("fill", "lightgrey")

lineGroup
  .append("g")
  .selectAll("text")
  .data(rootPostVotes)
  .join("path")
  .attr("d", USER_ICON_SVG_PATH)
  .attr("transform", (d) => `translate(${scaleVoteId(d.voteEventId) - 5}, 140) scale(0.02)`)
  .attr("fill", (d) => scaleUserColor(d.userId))

// -----------------------------------
// --- EDGES -------------------------
// -----------------------------------

let edges = discussionTree
  .filter((row) => row["parentId"] !== null)
  .map((row) => {
    return {
      parent: postsByPostId[row["parentId"]],
      post: postsByPostId[row["postId"]],
      edgeData: effectsByPostIdNoteId[`${row["parentId"]}-${row["postId"]}`]
    }
  })

let edgeData = r2d3.svg
  .append("g")
  .selectAll("g")
  .data(edges, (d) => d.parent["postId"] + "-" + d.post["postId"])

let edgeGroup = edgeData
  .join("g")
  .attr("id", (d) => "edgeGroup" + d.parent["postId"] + "-" + d.post["postId"])

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

let nodeData = r2d3.svg
  .append("g")
  .selectAll("g")
  .data(discussionTree, (d) => d["postId"])

let nodeGroup = nodeData
  .join("g")
  .attr("id", (d) => "nodeGroup" + d["postId"])
  .attr("transform", (d) => `translate(${d.x}, ${d.y})`)

// Post container
nodeGroup.append("rect")
  .attr("x", 0)
  .attr("y", 0)
  .attr("width", POST_RECT_WIDTH)
  .attr("height", POST_RECT_HEIGHT)
  .style("fill", "white")
  .attr("stroke", (d) => {
    if (d.parentP == d.parentQ) {
      return "black"
    }
    return d.parentP > d.parentQ ? "forestgreen" : "tomato"
  })

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

// https://stackoverflow.com/questions/2685911/is-there-a-way-to-round-numbers-into-a-reader-friendly-format-e-g-1-1k
function numberToText(number) {
  decPlaces = 10
  let abbrev = ["k", "m", "b", "t"]
  for (let i = abbrev.length - 1; i >= 0; i--) {
    let size = Math.pow(10, (i + 1) * 3)
    if (size <= number) {
      number = Math.round(number * decPlaces / size) / decPlaces
      if ((number == 1000) && (i < abbrev.length - 1)) {
        number = 1
        i++
      }
      number += abbrev[i]
      break
    }
  }
  return number
}

function addUpvoteProbabilityBar(
  groupSelection,
  x,
  fill,
  heightPercentageFunc,
  heightNaivePercentageFunc,
  opacityFunc,
  displayFunc,
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

  group
    .append("rect")
    .attr("width", 5)
    .attr("height", (d) => heightNaivePercentageFunc(d) * POST_RECT_HEIGHT)
    .attr("x", x)
    .attr("y", (d) => {
      return POST_RECT_HEIGHT - heightNaivePercentageFunc(d) * POST_RECT_HEIGHT
    })
    .style("fill", fill)
    .attr("display", displayFunc)

  // --- KEEP FOR POTENTIAL REUSE TO PLOT THE BAYESIAN PRIOR --->
  // group
  //   .append("line")
  //   .attr("x1", x)
  //   .attr("x2", x + 25)
  //   .attr("y1", POST_RECT_HEIGHT / 2 - 0.75)
  //   .attr("y2", POST_RECT_HEIGHT / 2 - 0.75)
  //   .attr("stroke", "black")
  //   .attr("opacity", 0.7)
  //   .style("stroke-dasharray", "5, 2")
  //   .style("stroke-width", 1.5)
  // <------
}

let voteGroup = nodeGroup.append("g")

// Upvote arrow
voteGroup
  .append("g")
  .attr("transform", `translate(-20, ${POST_RECT_HEIGHT / 2 - 15})`)
  .append("polygon")
  .attr("points", UP_ARROW_SVG_POLYGON_COORDS)
  .attr("opacity", (d) => d.oCount / d.oSize)

// Downvote arrow
voteGroup
  .append("g")
  .attr("transform", `translate(-20, ${POST_RECT_HEIGHT / 2 + 5})`)
  .append("polygon")
  .attr("points", DOWN_ARROW_SVG_POLYGON_COORDS)
  .attr("opacity", (d) => (d.oSize - d.oCount) / d.oSize)

// Upvote count
voteGroup
  .append("text")
  .text((d) => numberToText(d.oCount))
  .attr("width", 10)
  .attr("x", -15)
  .attr("y", POST_RECT_HEIGHT / 2 - 20)
  .attr("text-anchor", "middle")

// Downvote count
voteGroup
  .append("text")
  .text((d) => numberToText(d.oSize - d.oCount))
  .attr("width", 10)
  .attr("x", -15)
  .attr("y", POST_RECT_HEIGHT / 2 + 30)
  .attr("text-anchor", "middle")

addUpvoteProbabilityBar(
  voteGroup,
  -55,
  "black",
  (d) => d.o,
  (d) => d.oCount / d.oSize == 0 ? 0.05 : d.oCount / d.oSize,
  (d) => 1 - (1 / (1 + 0.3 * d.oSize)),
  () => "inline"
)

addUpvoteProbabilityBar(
  voteGroup,
  -85,
  "steelblue",
  (d) => d.p,
  (d) => {
    let edges = childEffectsByPostId[d.postId] || []
    let topNoteEdge = edges[0]
    return topNoteEdge && (topNoteEdge.pCount !== 0) ?
      topNoteEdge.pCount / topNoteEdge.pSize :
      0.05
  },
  (d) => {
    let edges = childEffectsByPostId[d.postId] || []
    let topNoteEdge = edges[0]
    return topNoteEdge && 1 - (1 / (1 + 0.3 * topNoteEdge.pSize))
  },
  (d) => childPostsByPostId[d.postId] ? "inline" : "none"
)

} catch (e) {
  console.error(e.stack)
}

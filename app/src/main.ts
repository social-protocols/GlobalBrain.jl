import './style.css'
import initSqlJs from 'sql.js'
import wasmUrl from "../node_modules/sql.js/dist/sql-wasm.wasm?url";
import * as d3 from 'd3'

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

type SimulationFilter = {
  simulationId: number | null,
  postId: number | null,
  period: number | null,
}

type PostWithScore = {
  parent_id: number | null,
  id: number,
  top_note_id: number | null,
  content: string,
  created_at: number,
  vote_event_id: number,
  vote_event_time: number,
  o: number,
  o_count: number,
  o_size: number,
  p: number,
  score: number,
}

// TODO: use for positioned posts
type PostWithCoords = PostWithScore & { x: number, y: number }

type VoteEvent = {
  vote_event_id: number,
  vote_event_time: number,
  user_id: string,
  tag_id: number,
  parent_id: number | null,
  post_id: number,
  note_id: number | null,
  vote: number,
}

type Effect = {
  vote_event_id: number,
  vote_event_time: number,
  tag_id: number,
  post_id: number,
  note_id: number,
  p: number,
  p_count: number,
  p_size: number,
  q: number,
  q_count: number,
  q_size: number,
  r: number,
}

type EffectEvent = {
  vote_event_id: number,
  vote_event_time: number,
  tag_id: number,
  post_id: number,
  note_id: number,
  p: number,
  p_count: number,
  p_size: number,
  q: number,
  q_count: number,
  q_size: number,
  r: number,
}

interface Lookup<T> {
  [Key: string]: T;
}

let simulationFilter: SimulationFilter = {
  simulationId: null,
  postId: null,
  period: null,
}

function handleSubmit(e: any) {
  e.preventDefault();
  const formData = new FormData(e.target);
  for (const [key, value] of formData) {
    simulationFilter[key] = value
  }
  rerender(simulationFilter)
}

async function rerender(simulationFilter: SimulationFilter) {
  d3.select("svg").remove()
  const svg = d3.select("div#app").append("svg")
  // TODO
}

function addSimulationSelectInput(simulationIds: number[]) {
  const simulationSelect = document.getElementById("simulationId")
  simulationIds.forEach((id) => {
    const option = document.createElement("option")
    option.value = id.toString()
    option.text = id.toString()
    simulationSelect?.appendChild(option)
  })
}

const simulationControls = document.getElementById("simulationControls")
simulationControls?.addEventListener("submit", handleSubmit)

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
  return res
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
  return res
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

  let tagId = 3
  let period = 3
  let rootPostId = 4
  let discussionTree = await getDiscussionTree(db, rootPostId, period)
  let effects = await getEffects(db, tagId, period)
  let effectEvents = await getEffectEvent(db)
  let scoreEvents = await getScoreEvent(db)
  let voteEvents = await getVoteEvent(db)
  let postsByPostId: Lookup<PostWithScore> = {}
  discussionTree.forEach((d) => {
    postsByPostId[d.id] = d
  })

  let voteEventsByPostId: Lookup<VoteEvent[]> = {}
  voteEvents.forEach((voteEvent) => {
    let postId = voteEvent.post_id
    if (postsByPostId[postId]) {
      if (!(postId in voteEventsByPostId)) {
        voteEventsByPostId[postId] = [voteEvent]
      } else {
        voteEventsByPostId[postId].push(voteEvent)
      }
    }
  })

  let effectsByPostIdNoteId: Lookup<Effect> = {}
  effects.forEach((effect) => {
    effectsByPostIdNoteId[`${effect["post_id"]}-${effect["note_id"]}`] = effect
  })

  let effectEventsByPostId: Lookup<EffectEvent[]> = {}
  effectEvents.forEach((effectEvent) => {
    let postId = effectEvent.post_id
    if (!effectEventsByPostId[postId]) {
      effectEventsByPostId[postId] = [effectEvent]
    } else {
      effectEventsByPostId[postId].push(effectEvent)
    }
  })

  let thisTreePostIds = Object.keys(postsByPostId)
  let currentEffects: Lookup<Effect> = {}
  thisTreePostIds.forEach((postId) => {
    if (!(postId in effectEventsByPostId)) {
      return
    }
    // https://stackoverflow.com/questions/4020796/finding-the-max-value-of-a-property-in-an-array-of-objects
    currentEffects[postId] = effectEventsByPostId[postId].reduce(function(prev, current) {
      return (prev && prev.vote_event_id > current.vote_event_id) ? prev : current
    })
  })

  // TODO: calculate magnitude
  let childPostsByPostId: Lookup<PostWithScore[]> = {}
  let childEffectsByPostId: Lookup<Effect[]> = {}
  discussionTree.forEach((post: PostWithScore) => {
    let parentId = post["parent_id"]
    if (parentId !== null) {
      let effect = effectsByPostIdNoteId[`${parentId}-${post["id"]}`]
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
        let effectA = effectsByPostIdNoteId[`${parentId}-${a["id"]}`].magnitude
        let effectB = effectsByPostIdNoteId[`${parentId}-${b["id"]}`].magnitude
        return effectB - effectA
      })
    }
  })

  function assignPositionsFromRootRecursive(postId: number) {
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
        assignPositionsFromRootRecursive(child["id"])
      })
    }
  }

  let root = childPostsByPostId["null"][0]
  root.x = ROOT_POST_RECT_X
  root.y = ROOT_POST_RECT_Y
  assignPositionsFromRootRecursive(root["id"])

}

main()

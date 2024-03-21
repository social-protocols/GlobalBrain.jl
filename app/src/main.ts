import './style.css'
import initSqlJs from 'sql.js'
import wasmUrl from "../node_modules/sql.js/dist/sql-wasm.wasm?url";
import * as d3 from 'd3'

let simulationFilter: {
  simulationId: number | null,
  postId: number | null,
  period: number | null,
} = {
  simulationId: null,
  postId: null,
  period: null,
}

function handleSubmit(e: any) {
  e.preventDefault();
  const formData = new FormData(e.target);
  formData.entries().forEach(([key, value]: Array<string>) => {
    simulationFilter[key] = value
  })
  rerender(simulationFilter)
}

async function rerender(
  simulationFilter: {
    simulationId: number | null,
    postId: number | null,
    period: number | null,
  }
) {
  // const discussionTreeQueryResult = await getDiscussionTree(db, Number(simulationFilter.postId!), 3)
  // console.log(discussionTreeQueryResult)
  d3.select("svg").remove()
  const svg = d3.select("div#app").append("svg")
  svg
    .data([simulationFilter])
    .append("circle")
    .attr("cx", 50)
    .attr("cy", 50)
    .attr("r", 20)
    .attr("fill", d => d.postId == 1 ? "blue" : "red")
    .attr("opacity", 0.3)
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



async function main() {
  const sqlPromise = initSqlJs({ locateFile: () => wasmUrl })
  const dataPromise = fetch("/sim.db").then(res => res.arrayBuffer())
  const [SQL, buf] = await Promise.all([sqlPromise, dataPromise])
  const db = new SQL.Database(new Uint8Array(buf))

  const simulationsQueryResult = db.exec("select id from tag")
  const simulationIds = unpackDBResult(simulationsQueryResult[0]).map((x: any) => x.id)
  addSimulationSelectInput(simulationIds)

}

main()

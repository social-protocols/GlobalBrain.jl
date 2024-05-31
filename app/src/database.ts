import relativeEntropy from "./entropy"

// TODO: return types of database functions
export type VisualizationData = {
  discussionTree: any[]
  effects: any[]
  scoreEvents: any[]
  effectEvents: any[]
  voteEvents: any[]
}

export async function getData(
  db: any,
  simulationId: number,
  rootPostId: number,
  period: number,
): Promise<VisualizationData> {
  let discussionTree = await getDiscussionTree(db, rootPostId, period)
  let effects = await getEffects(db, simulationId, period)
  let effectEvents = await getEffectEvents(db)
  let scoreEvents = await getScoreEvents(db)
  let voteEvents = await getVoteEvents(db)

  return {
    discussionTree: discussionTree,
    effects: effects,
    scoreEvents: scoreEvents,
    effectEvents: effectEvents,
    voteEvents: voteEvents,
  }
}

export function unpackDBResult(result: { columns: string[]; values: any[] }) {
  const columns = result.columns
  const values = result.values
  return values.map((value) => {
    return columns.reduce<Record<string, any>>((obj, col, index) => {
      obj[col] = value[index]
      return obj
    }, {})
  })
}

export async function getRootPostIds(db: any, simulationId: number) {
  let stmt = db.prepare(`
		select distinct id
		from Post
		join PostSimulation
		on post.id = PostSimulation.post_id
		where simulation_id = :simulationId
		and parent_id is null
  `)
  stmt.bind({ ":simulationId": simulationId })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

export async function getSimulationId(db: any, simulationName: string) {
  let stmt = db.prepare(`
    SELECT simulation_id from Simulation where simulation_name = :simulationName
  `)
  stmt.bind({ ":simulationName": simulationName })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res[0]!.simulation_id
}

async function getDiscussionTree(db: any, postId: number, period: number) {
  const stmt = db.prepare(`
    WITH postsWithActivity AS(
      select distinct(post_id) as id
      from voteEvent
      where vote_event_time <= :period
    ),
    currentPosts AS(
      SELECT post.*
      FROM post
      JOIN postsWithActivity using (id)
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
  stmt.bind({ ":root_post_id": postId, ":period": period })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

async function getEffects(db: any, simulationId: number, period: number) {
  let stmt = db.prepare(`
		select max(vote_event_id) as max_id, EffectEvent.*
		from EffectEvent
		join PostSimulation
		on EffectEvent.post_id = PostSimulation.post_id
		where simulation_id = :simulationId
		and vote_event_time <= :period
		group by EffectEvent.post_id, EffectEvent.note_id
  `)
  stmt.bind({ ":simulationId": simulationId, ":period": period })
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

async function getScoreEvents(db: any) {
  let stmt = db.prepare(`SELECT * FROM ScoreEvent`)
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

async function getEffectEvents(db: any) {
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

async function getVoteEvents(db: any) {
  let stmt = db.prepare(`SELECT * FROM VoteEvent`)
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

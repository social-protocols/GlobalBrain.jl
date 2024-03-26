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
  tagId: number,
  rootPostId: number,
  period: number,
): Promise<VisualizationData> {
  let discussionTree = await getDiscussionTree(db, rootPostId, period)
  let effects = await getEffects(db, tagId, period)
  let effectEvents = await getEffectEvent(db)
  let scoreEvents = await getScoreEvent(db)
  let voteEvents = await getVoteEvent(db)

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

export async function getRootPostIds(db: any, tagId: number) {
  let stmt = db.prepare(`
    SELECT DISTINCT post_id
    FROM VoteEvent
    WHERE tag_id = :tagId
    AND parent_id IS NULL
  `)
  stmt.bind({ ":tagId": tagId })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res
}

export async function getTagId(db: any, tag: string) {
  let stmt = db.prepare(`
    SELECT id from tag where tag = :tag
  `)
  stmt.bind({ ":tag": tag })
  let res = []
  while (stmt.step()) {
    res.push(stmt.getAsObject())
  }
  return res[0]!.id
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
  stmt.bind({ ":root_post_id": postId, ":period": period })
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
  stmt.bind({ ":tagId": tagId, ":period": period })
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

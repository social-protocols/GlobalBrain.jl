export type Simulation = {
  simulationId: number
  simulationName: string
}

export type SimulationFilter = {
  simulationName: string | null
  period: number | null
}

export type PostWithScore = {
  parent_id: number | null
  id: number
  top_comment_id: number | null
  content: string
  vote_event_id: number
  vote_event_time: number
  o: number
  o_count: number
  o_size: number
  p: number
  r: number
  score: number
}

export type PostWithScoreWithPosition = PostWithScore & { x: number; y: number }

export type VoteEvent = {
  vote_event_id: number
  vote_event_time: number
  user_id: string
  parent_id: number | null
  post_id: number
  vote: number
}

export type Effect = {
  vote_event_id: number
  vote_event_time: number
  post_id: number
  comment_id: number
  top_subthread_id: number | null
  p: number
  p_count: number
  p_size: number
  q: number
  q_count: number
  q_size: number
  r: number
  magnitude: number
}

export type EffectEvent = {
  vote_event_id: number
  vote_event_time: number
  post_id: number
  comment_id: number
  top_subthread_id: number | null
  p: number
  p_count: number
  p_size: number
  q: number
  q_count: number
  q_size: number
  r: number
  magnitude: number
}

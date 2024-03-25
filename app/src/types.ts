export type SimulationFilter = {
  simulationId: number | null
  period: number | null
}

export type PostWithScore = {
  parent_id: number | null
  id: number
  top_note_id: number | null
  content: string
  created_at: number
  vote_event_id: number
  vote_event_time: number
  o: number
  o_count: number
  o_size: number
  p: number
  score: number
}

export type PostWithScoreWithPosition = PostWithScore & { x: number; y: number }

export type VoteEvent = {
  vote_event_id: number
  vote_event_time: number
  user_id: string
  tag_id: number
  parent_id: number | null
  post_id: number
  note_id: number | null
  vote: number
}

export type Effect = {
  vote_event_id: number
  vote_event_time: number
  tag_id: number
  post_id: number
  note_id: number
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
  tag_id: number
  post_id: number
  note_id: number
  p: number
  p_count: number
  p_size: number
  q: number
  q_count: number
  q_size: number
  r: number
  magnitude: number
}

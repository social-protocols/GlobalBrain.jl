import {
  PostWithScore,
  VoteEvent,
  Effect,
  EffectEvent,
} from './types'

export interface Lookup<T> {
  [Key: string]: T;
}

export function getLookupPostsByPostId(
  discussionTree: PostWithScore[]
): Lookup<PostWithScore> {
  let postsByPostId: Lookup<PostWithScore> = {}
  discussionTree.forEach((d) => {
    postsByPostId[d.id] = d
  })
  return postsByPostId
}

export function getLookupVoteEventsByPostId(
  voteEvents: VoteEvent[],
  postsByPostId: Lookup<PostWithScore>
): Lookup<VoteEvent[]> {
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
  return voteEventsByPostId
}

export function getLookupEffectsByPostIdNoteId(
  effects: Effect[]
): Lookup<Effect> {
  let effectsByPostIdNoteId: Lookup<Effect> = {}
  effects.forEach((effect) => {
    effectsByPostIdNoteId[`${effect["post_id"]}-${effect["note_id"]}`] = effect
  })
  return effectsByPostIdNoteId
}

export function getLookupEffectEventsByPostId(
  effectEvents: EffectEvent[]
): Lookup<EffectEvent[]> {
  let effectEventsByPostId: Lookup<EffectEvent[]> = {}
  effectEvents.forEach((effectEvent) => {
    let postId = effectEvent.post_id
    if (!effectEventsByPostId[postId]) {
      effectEventsByPostId[postId] = [effectEvent]
    } else {
      effectEventsByPostId[postId].push(effectEvent)
    }
  })
  return effectEventsByPostId
}

export function getLookupCurrentEffectsByPostId(
  postsByPostId: Lookup<PostWithScore>,
  effectEventsByPostId: Lookup<EffectEvent[]>
): Lookup<Effect> {
  let currentEffects: Lookup<Effect> = {}
  let thisTreePostIds = Object.keys(postsByPostId)
  thisTreePostIds.forEach((postId) => {
    if (!(postId in effectEventsByPostId)) {
      return
    }
    // https://stackoverflow.com/questions/4020796/finding-the-max-value-of-a-property-in-an-array-of-objects
    currentEffects[postId] = effectEventsByPostId[postId].reduce(function(prev, current) {
      return (prev && prev.vote_event_id > current.vote_event_id) ? prev : current
    })
  })
  return currentEffects
}

export function getLookupChildrenByPostId(
  discussionTree: PostWithScore[],
  effectsByPostIdNoteId: Lookup<Effect>,
): Lookup<PostWithScore[]> {
  let childPostsByPostId: Lookup<PostWithScore[]> = {}
  discussionTree.forEach((post: PostWithScore) => {
    let parentId = post["parent_id"]
    let parentIdOrRoot = parentId || 0
    if (!(parentIdOrRoot in childPostsByPostId)) {
      childPostsByPostId[parentIdOrRoot] = [post]
    } else {
      childPostsByPostId[parentIdOrRoot].push(post)
      childPostsByPostId[parentIdOrRoot].sort((a, b) => {
        let effectA = effectsByPostIdNoteId[`${parentId}-${a["id"]}`].magnitude
        let effectB = effectsByPostIdNoteId[`${parentId}-${b["id"]}`].magnitude
        return effectB - effectA
      })
    }
  })
  return childPostsByPostId
}

export function getLookupChildEffectsByPostId(
  discussionTree: PostWithScore[],
  effectsByPostIdNoteId: Lookup<Effect>,
): Lookup<Effect[]> {
  let childEffectsByPostId: Lookup<Effect[]> = {}
  discussionTree.forEach((post: PostWithScore) => {
    let parentId = post["parent_id"]
    if (parentId !== null) {
      let effect = effectsByPostIdNoteId[`${parentId}-${post["id"]}`]
      if (!(parentId in childEffectsByPostId)) {
        childEffectsByPostId[parentId] = [effect]
      } else {
        childEffectsByPostId[parentId].push(effect)
        childEffectsByPostId[parentId].sort((a, b) => b.magnitude - a.magnitude)
      }
    }
  })
  return childEffectsByPostId
}



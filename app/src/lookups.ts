import { VisualizationData } from "./database"
import { PostWithScore, VoteEvent, Effect, EffectEvent } from "./types"

export interface Lookup<T> {
  [Key: string]: T
}

export type LookupData = {
  postsByPostId: Lookup<PostWithScore>
  voteEventsByPostId: Lookup<VoteEvent[]>
  effectsByPostIdNoteId: Lookup<Effect>
  effectEventsByPostId: Lookup<EffectEvent[]>
  currentEffects: Lookup<Effect>
  childrenByPostId: Lookup<PostWithScore[]>
  childEffectsByPostId: Lookup<Effect[]>
}

export function getLookups(data: VisualizationData): LookupData {
  let postsByPostId: Lookup<PostWithScore> = getLookupPostsByPostId(
    data.discussionTree,
  )
  let voteEventsByPostId: Lookup<VoteEvent[]> = getLookupVoteEventsByPostId(
    data.voteEvents,
    postsByPostId,
  )
  let effectsByPostIdNoteId: Lookup<Effect> = getLookupEffectsByPostIdNoteId(
    data.effects,
  )
  let effectEventsByPostId: Lookup<EffectEvent[]> =
    getLookupEffectEventsByPostId(data.effectEvents)
  let currentEffects: Lookup<Effect> = getLookupCurrentEffectsByPostId(
    postsByPostId,
    effectEventsByPostId,
  )
  let childrenByPostId: Lookup<PostWithScore[]> = getLookupChildrenByPostId(
    data.discussionTree,
    effectsByPostIdNoteId,
  )
  let childEffectsByPostId: Lookup<Effect[]> = getLookupChildEffectsByPostId(
    data.discussionTree,
    effectsByPostIdNoteId,
  )

  return {
    postsByPostId: postsByPostId,
    voteEventsByPostId: voteEventsByPostId,
    effectsByPostIdNoteId: effectsByPostIdNoteId,
    effectEventsByPostId: effectEventsByPostId,
    currentEffects: currentEffects,
    childrenByPostId: childrenByPostId,
    childEffectsByPostId: childEffectsByPostId,
  }
}

function getLookupPostsByPostId(
  discussionTree: PostWithScore[],
): Lookup<PostWithScore> {
  let postsByPostId: Lookup<PostWithScore> = {}
  discussionTree.forEach((d) => {
    postsByPostId[d.id] = d
  })
  return postsByPostId
}

function getLookupVoteEventsByPostId(
  voteEvents: VoteEvent[],
  postsByPostId: Lookup<PostWithScore>,
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

function getLookupEffectsByPostIdNoteId(effects: Effect[]): Lookup<Effect> {
  let effectsByPostIdNoteId: Lookup<Effect> = {}
  effects.forEach((effect) => {
    effectsByPostIdNoteId[`${effect["post_id"]}-${effect["note_id"]}`] = effect
  })
  return effectsByPostIdNoteId
}

function getLookupEffectEventsByPostId(
  effectEvents: EffectEvent[],
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

function getLookupCurrentEffectsByPostId(
  postsByPostId: Lookup<PostWithScore>,
  effectEventsByPostId: Lookup<EffectEvent[]>,
): Lookup<Effect> {
  let currentEffects: Lookup<Effect> = {}
  let thisTreePostIds = Object.keys(postsByPostId)
  thisTreePostIds.forEach((postId) => {
    if (!(postId in effectEventsByPostId)) {
      return
    }
    // https://stackoverflow.com/questions/4020796/finding-the-max-value-of-a-property-in-an-array-of-objects
    currentEffects[postId] = effectEventsByPostId[postId].reduce(
      function (prev, current) {
        return prev && prev.vote_event_id > current.vote_event_id
          ? prev
          : current
      },
    )
  })
  return currentEffects
}

function getLookupChildrenByPostId(
  discussionTree: PostWithScore[],
  effectsByPostIdNoteId: Lookup<Effect>,
): Lookup<PostWithScore[]> {
  let childrenByPostId: Lookup<PostWithScore[]> = {}
  discussionTree.forEach((post: PostWithScore) => {
    let parentId = post["parent_id"]
    let parentIdOrRoot = parentId || 0
    if (!(parentIdOrRoot in childrenByPostId)) {
      childrenByPostId[parentIdOrRoot] = [post]
    } else {
      childrenByPostId[parentIdOrRoot].push(post)
      childrenByPostId[parentIdOrRoot].sort((a, b) => {
        let effectA = effectsByPostIdNoteId[`${parentId}-${a["id"]}`].magnitude
        let effectB = effectsByPostIdNoteId[`${parentId}-${b["id"]}`].magnitude
        return effectB - effectA
      })
    }
  })
  return childrenByPostId
}

function getLookupChildEffectsByPostId(
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

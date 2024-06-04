import { VisualizationData } from "./database"
import {
  CHILD_NODE_SPREAD,
  CHILD_PARENT_OFFSET,
  ROOT_POST_RECT_X,
  ROOT_POST_RECT_Y,
} from "./render"
import {
  PostWithScore,
  VoteEvent,
  Effect,
  EffectEvent,
  PostWithScoreWithPosition,
} from "./types"

export interface Lookup<T> {
  [Key: string]: T
}

export type LookupData = {
  postsByPostId: Lookup<PostWithScoreWithPosition>
  voteEventsByPostId: Lookup<VoteEvent[]>
  effectsByPostIdNoteId: Lookup<Effect>
  effectEventsByPostId: Lookup<EffectEvent[]>
  currentEffects: Lookup<Effect>
  childrenIdsByPostId: Lookup<number[]>
  childEffectsByPostId: Lookup<Effect[]>
}

export function getLookups(data: VisualizationData): LookupData {
  const postsByPostId: Lookup<PostWithScore> = getLookupPostsByPostId(
    data.discussionTree,
  )
  const effectsByPostIdNoteId: Lookup<Effect> = getLookupEffectsByPostIdNoteId(
    data.effects,
  )
  const effectEventsByPostId: Lookup<EffectEvent[]> =
    getLookupEffectEventsByPostId(data.effectEvents)

  const childrenIdsByPostId: Lookup<number[]> = getLookupChildrenByPostId(
    data.discussionTree,
    effectsByPostIdNoteId,
  )
  const postsByPostIdWithPosition: Lookup<PostWithScoreWithPosition> =
    assignPositionsFromRootRecursive(postsByPostId, childrenIdsByPostId)
  const voteEventsByPostId: Lookup<VoteEvent[]> = getLookupVoteEventsByPostId(
    data.voteEvents,
    postsByPostId,
  )
  const currentEffects: Lookup<Effect> = getLookupCurrentEffectsByPostId(
    postsByPostId,
    effectEventsByPostId,
  )
  const childEffectsByPostId: Lookup<Effect[]> = getLookupChildEffectsByPostId(
    data.discussionTree,
    effectsByPostIdNoteId,
  )

  return {
    postsByPostId: postsByPostIdWithPosition,
    voteEventsByPostId: voteEventsByPostId,
    effectsByPostIdNoteId: effectsByPostIdNoteId,
    effectEventsByPostId: effectEventsByPostId,
    currentEffects: currentEffects,
    childrenIdsByPostId: childrenIdsByPostId,
    childEffectsByPostId: childEffectsByPostId,
  }
}

function assignPositionsFromRootRecursive(
  postsByPostId: Lookup<PostWithScore>,
  childrenByPostId: Lookup<number[]>,
): Lookup<PostWithScoreWithPosition> {
  const rootOld = postsByPostId[childrenByPostId[0][0]]
  const root: PostWithScoreWithPosition = {
    ...rootOld,
    x: ROOT_POST_RECT_X,
    y: ROOT_POST_RECT_Y,
  }
  const postByPostIdWithPosition: Lookup<PostWithScoreWithPosition> = {
    [root.id]: root,
  }
  function recurse(postId: number, postX: number, postY: number) {
    let postOld = postsByPostId[postId]
    let post = { ...postOld, x: postX, y: postY }
    postByPostIdWithPosition[postId] = post

    if (postId in childrenByPostId) {
      // prepare spread and step size to position children
      let spread = 0
      let stepSize = 0
      if (childrenByPostId[postId].length > 1) {
        spread = CHILD_NODE_SPREAD
        stepSize = spread / (childrenByPostId[postId].length - 1)
      }

      childrenByPostId[postId].forEach((childId, i) => {
        const x = postX + i * stepSize
        const y = postY + CHILD_PARENT_OFFSET
        recurse(childId, x, y)
      })
    }
  }
  recurse(root.id, root.x, root.y)
  return postByPostIdWithPosition
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
    effectsByPostIdNoteId[`${effect["post_id"]}-${effect["comment_id"]}`] = effect
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
): Lookup<number[]> {
  let childrenByPostId: Lookup<number[]> = {}
  discussionTree.forEach((post: PostWithScore) => {
    let parentId = post["parent_id"]
    let parentIdOrRoot = parentId || 0
    if (!(parentIdOrRoot in childrenByPostId)) {
      childrenByPostId[parentIdOrRoot] = [post.id]
    } else {
      childrenByPostId[parentIdOrRoot].push(post.id)
      childrenByPostId[parentIdOrRoot].sort((a, b) => {
        let effectA = effectsByPostIdNoteId[`${parentId}-${a}`].magnitude
        let effectB = effectsByPostIdNoteId[`${parentId}-${b}`].magnitude
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

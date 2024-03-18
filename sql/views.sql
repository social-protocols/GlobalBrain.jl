create view if not exists DetailedTally as
select
      self.tag_id      as tag_id
    , ancestor_id      as ancestor_id
    , self.parent_id   as parent_id
    , self.post_id     as post_id
    , parent.count     as parentCount
    , parent.total     as parentTotal
    , uninformed_count as uninformed_count
    , uninformed_total as uninformed_total
    , informed_count   as informed_count
    , informed_total   as informed_total
    , self.count       as selfCount
    , self.total       as selfTotal
    -- , ifnull(lineage.separation,0) as separation
from Tally self
left join Lineage on (lineage.descendant_id = self.post_id)
left join ConditionalTally on (
  ancestor_id = ConditionalTally.post_id
  and self.post_id = ConditionalTally.note_id
  and event_type = 2
)
left join Tally parent on (
  ancestor_id = parent.post_id
  and self.tag_id = parent.tag_id
);

-- Whenever there is a vote, we need to recalculate scores for
-- 1) the post that was voted on
-- 2) all ancestors of the post that was voted on (because a post's score depends on children's score)
-- 3) all direct children of the post that was voted on (because a post's score also includes its effect on its parent)
create view NeedsRecalculation as
-- First, select posts that were voted on since last processed_vote_event_id
with leafNode as (
    select post_id, tag_id
    from tally
    join LastVoteEvent
    on latest_vote_event_id > processed_vote_event_id
)
select * from leafNode

union
-- Next, select all ancestors
select ancestor_id as post_id, tag_id
from leafNode join Lineage Ancestor on (post_id = descendant_id)

union
-- Next, select all children
select descendant_id as post_id, tag_id
from leafNode
join Lineage Descendant on (post_id = ancestor_id); -- children of item that was voted on


create view VoteEventImport as
select
    0  as vote_event_id,
    '' as user_id,
    0  as tag_id,
    '' as parent_id,
    0  as post_id,
    '' as note_id,
    0  as vote,
    0  as vote_event_time;


-- Table to summarize what posts a user is/is not informed of (has/has not voted on)
-- This table implements two important rules.
-- 1. A user has considered a post if they have considered its parent.
-- 2. Only count user as uninformed of a post when the user is informed of the parent of the post.
create view InformationStatus as
with informed as ( 
  -- first, find all posts that user is informed of (where they have voted on that post OR a parent)
  select user_id, tag_id, post_id, 2 as event_type 
  from vote
  where vote != 0
  -- and parent_id is null
  UNION 
  select user_id, tag_id, ancestor_id as post_id, 2 as event_type
  from lineage
  join vote on
    descendant_id = vote.post_id
    -- and parent_id is null
  where vote != 0
)
, uninformed as (
  -- first, find all posts that user is NOT informed of GIVEN they are informed of the parent.  
  select informed.user_id, informed.tag_id, informed.post_id as parent_id, child.id as post_id, informed.event_type
  from informed
  join post child on informed.post_id = child.parent_id
  left join informed informed_child on
    informed_child.user_id = informed.user_id
    and informed_child.tag_id = informed.tag_id 
    and informed_child.post_id = child.id
    and informed_child.event_type = 2
  where
    informed.event_type=2
    and informed_child.post_id is null
)
  select user_id, tag_id, post_id, event_type, 1 as informed from informed
  union all
  select user_id, tag_id, post_id, event_type, 0 as informed from uninformed
;


-- The current conditional vote, not considering history. The current conditional vote
-- will be either informed or uninformed, whereas the conditionalVote table will contain
-- both an informed_vote and uninformed_vote, to record how users voted before becoming informed. 
create view CurrentConditionalVote as 
  select 
    vote.user_id
    , vote.tag_id
    , vote.post_id
    , descendant_id as note_id
    , 2 as event_type
    -- uninformed vote
    -- , vote
    , case when informed then vote.vote else 0 end as informed_vote
    , case when not informed then vote.vote else 0 end as uninformed_vote
    , informed
from
  vote
  join lineage on lineage.ancestor_id = vote.post_id
  join InformationStatus on 
    InformationStatus.user_id = vote.user_id
    and InformationStatus.tag_id = vote.tag_id
    and InformationStatus.post_id = lineage.descendant_id
;



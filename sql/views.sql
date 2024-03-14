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
select post.id as post_id, tag_id
from leafNode
join post on parent_id = post_id; -- children of item that was voted on


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

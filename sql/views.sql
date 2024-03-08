
create view if not exists DetailedTally as
select
    self.tagId
    , ancestorId   as ancestorId
    , self.parentId as parentId
    , self.postId                    as postId
    , parent.count   as parentCount
    , parent.total   as parentTotal
    , uninformedCount as uninformedCount
    , uninformedTotal as uninformedTotal
    , informedCount   as informedCount
    , informedTotal   as informedTotal
    , self.count       as selfCount
    , self.total       as selfTotal
    -- , ifnull(lineage.separation,0) as separation
from 
    Tally self
    left join Lineage on (lineage.descendantId = self.postId)
    left join ConditionalTally on (ancestorId = ConditionalTally.postId and self.postId = ConditionalTally.noteId and eventType = 2)
    left join Tally parent on (ancestorId = parent.postId and self.tagId = parent.tagId)
;


-- Whenever there is a vote, we need to recalculate scores for 
-- 1) the post that was voted on
-- 2) all ancestors of the post that was voted on (because a post's score depends on children's score)
-- 3) all direct children of the post that was voted on (because a post's score also includes its effect on its parent)
create view NeedsRecalculation as 
-- First, select posts that were voted on since last processedVoteEventId
with leafNode as (
    select postId, tagId
    from tally
    join LastVoteEvent
    on latestVoteEventId > processedVoteEventId  
)
select * from leafNode

union
-- Next, select all ancestors
select 
    ancestorId as postId, tagId
from leafNode join Lineage Ancestor on (postId = descendantId)


union
-- Next, select all children
select 
    post.id as postId, tagId 
from leafNode
join post on parentId = postId; -- children of item that was voted on


create view VoteEventImport as
select 
    0 voteEventId,
    '' userId,
    0 tagId,
    '' parentId,
    0 postId,
    '' noteId,
    0 vote,
    0 createdAt
;

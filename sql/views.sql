
create view if not exists DetailedTally as
with ConditionalTally as (
    select
           uninformedTally.tagId
           , uninformedTally.postId
           , uninformedTally.noteId
           , uninformedTally.eventType
           , informedTally.count as informedCount
           , informedTally.total as informedTotal
           , uninformedTally.count as uninformedCount
           , uninformedTally.total as uninformedTotal
     from 
           uninformedTally
           left join informedTally using (tagId, postId, noteId, eventType)
           where uninformedTally.eventType == 2
           order by uninformedTally.tagId, uninformedTally.postId, uninformedTally.noteId, uninformedTally.eventType
)
select
    self.tagId
    , self.parentId   as parentId
    , self.postId                    as postId
    , parent.count   as parentCount
    , parent.total   as parentTotal
    , uninformedCount as uninformedCount
    , uninformedTotal as uninformedTotal
    , informedCount   as informedCount
    , informedTotal   as informedTotal
    , self.count       as selfCount
    , self.total       as selfTotal
from 
    Tally self
    left join ConditionalTally on (self.parentId = ConditionalTally.postId and self.postId = ConditionalTally.noteId)
    left join Tally parent on (self.parentId = parent.postId and self.tagId = parent.tagId)
;


-- Whenever there is a vote, we need to recalculate scores for 
-- 1) the post that was voted on
-- 2) all ancestors of the post that was voted on (because a post's score depends on children's score)
-- 3) all direct children of the post that was voted on (because a post's score also includes its effect on its parent)
create view NeedsRecalculation as 
with RECURSIVE Ancestors AS (

    with leafNodes as (
        select postId, tagId
        from tally
        join LastVoteEvent
        on latestVoteEventId > processedVoteEventId  
    )
    select id as postId, parentId
    from post
    join leafNodes
    where id = leafNodes.postId
    union
    select p.id, p.parentId
    from post p
    inner join Ancestors a on p.id = a.parentId
)
-- First, select self and all ancestors of posts that were voted on since last processedVoteEventId
select 
    postId, tagId FROM tally join Ancestors using (postId)

union
-- Next, select all children
select 
    post.id, tagId 
    from tally 
    join lastVoteEvent on latestVoteEventId > processedVoteEventId 
    join post on post.parentId = tally.postId; -- children of item that was voted on


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

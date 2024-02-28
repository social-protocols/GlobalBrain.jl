
create view if not exists DetailedTally as
select
       parent.tagId
       , parent.postId
       , uninformedTally.noteId
       , uninformedTally.eventType
       , informedTally.count as informedCount
       , informedTally.total as informedTotal
       , uninformedTally.count as uninformedCount
       , uninformedTally.total as uninformedTotal
       , parent.count as parentCount
       , parent.total as parentTotal
       , note.count as overallCount
       , note.total as overallTotal
 from 
       tally parent
       left join uninformedTally  on (parent.postId = uninformedTally.postId and uninformedTally.eventType == 2)
       left join informedTally on (
            uninformedTally.tagId = informedTally.tagId 
            and uninformedTally.postId = informedTally.postId 
            and uninformedTally.noteId = informedTally.noteId
            and uninformedTally.eventType = informedTally.eventType
        )
       left join tally note on (note.postId = uninformedTally.noteId)
       order by parent.tagId, parent.postId, uninformedTally.noteId, uninformedTally.eventType
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

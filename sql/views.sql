
create view if not exists DetailedTally as
with a as (
       select
               tagId
               , postId
               , noteId
               , eventType

               , count as informedCount
               , total as informedTotal

       from
               informedTally t
       where eventType == 2
)
select
       a.*
       , uninformedTally.count as uninformedCount
       , uninformedTally.total as uninformedTotal
       , overall.count as overallCount
       , overall.total as overallTotal
       , note.count as noteCount
       , note.total as noteTotal
 from a
       left join uninformedTally using (tagId, postId, noteId, eventType)
       left join tally overall on (overall.postId = a.postId)
       left join tally note on (note.postId = a.noteId)
       order by tagId, postId, noteId, eventType
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


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
;

-- Okay where we: DetailedTally needs to be a union. We need the two separate queries like we had before

-- create view if not exists DetailedTally as
-- select 
--     overall.tagId
--     , parentId
--     , id as postId
--     , informed.noteId
--     , informed.count as informedCount
--     , informed.total as informedTotal
--     , uninformed.count as uninformedCount
--     , uninformed.total as uninformedTotal 
--     , overall.count as overallCount
--     , overall.total as overallTotal
--     , note.count as noteCount
--     , note.total as noteTotal
--     , eventType
--  from 
--     Post 
--     join Tally overall on (overall.postId = post.id)
--     left join InformedTally informed on (informed.postId = overall.postId and informed.tagId = overall.tagId)
--     left join UninformedTally uninformed using (tagId, postId, noteId, eventType)
--     left join Tally note on (note.postId = ifnull(informed.noteId, uninformed.noteId))
--     where ifnull(eventType = 1, true) -- important -- only looking at tally's given voted on note
-- ;



create view NeedsRecalculation as 
WITH RECURSIVE Ancestors AS (

    with leafNodes as (
        select postId, tagId
        from tally
        join LastVoteEvent
        where latestVoteEventId > processedVoteEventId  
    )
    SELECT id as postId, parentId
    FROM post
    JOIN leafNodes
    WHERE id = leafNodes.postId
    UNION
    SELECT p.id, p.parentId
    FROM post p
    INNER JOIN Ancestors a ON p.id = a.parentId
)
SELECT postId, tagId FROM tally join Ancestors using (postId);



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

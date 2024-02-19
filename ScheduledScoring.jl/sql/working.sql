update lastVoteEvent set processedVoteEventId = importedVoteEventId;


        -- select
        --     tagId
        --     , ifnull(ScoreData.parentId, 0) parentId
        --     , ScoreData.postId
        --     , ifnull(topNoteId, 0) topNoteId
        --     , ifnull(parentUninformedP, 0) parentUninformedP
        --     , ifnull(parentInformedP, 0) parentInformedP
        --     , ifnull(uninformedP, 0) uninformedP
        --     , ifnull(informedP, 0) informedP
        --     , ifnull(uninformedP, 0) uninformedP
        --     , ifnull(informedP, 0) informedP
        --     , count
        --     , total
        --     , selfP
        --     , OutOfDate.postId is not null as isOutOfDate

        -- from ScoreData
        -- left join OutOfDate using (postId)
        -- where isOutOfDate


-- select
--             tagId
--             , postId                     
--             , ifnull(parentId,0) as parentId
--             , noteId
--             , ifnull(overallCount, 0)    as parentCount
--             , ifnull(overallTotal, 0)    as parentTotal
--             , ifnull(uninformedCount, 0) as uninformedCount
--             , ifnull(uninformedTotal, 0) as uninformedTotal
--             , ifnull(informedCount, 0)   as informedCount
--             , ifnull(informedTotal, 0)   as informedTotal
--             , ifnull(noteCount, 0)       as selfCount
--             , ifnull(noteTotal, 0)       as selfTotal
--         from DetailedTally
--         where ifnull(tagId = 1, true)
--               and case when 1 is null then (parentId is null) else (parentId = 1) end 



        -- select
        --     tagId
        --     , ifnull(parentId, 0) parentId
        --     , postId
        --     , ifnull(topNoteId, 0) topNoteId
        --     , ifnull(parentUninformedP, 0) parentUninformedP
        --     , ifnull(parentInformedP, 0) parentInformedP
        --     , ifnull(uninformedP, 0) uninformedP
        --     , ifnull(informedP, 0) informedP
        --     , ifnull(uninformedP, 0) uninformedP
        --     , ifnull(informedP, 0) informedP
        --     , count
        --     , total
        --     , selfP
        -- from ScoreData
        -- join OutOfDate using (postId)
        -- where 
        --     where ifnull(tagId = :tag_id, true)
        --     and ifnull(parentId = :post_id, parentId is null) -- children of given post if supplied, otherwise top-level posts
        --     and OutOfDate.postId is null;



-- with parameters as (
--     select 
--         5 as post_id
--         , 1 as tag_id
-- )
-- , newVoteEvents as (
--     select 
--         5 as postId
--         , 1 as tagId
-- )
-- , invalidated as (
--     WITH RECURSIVE Ancestors AS (
--         SELECT id as postId, parentId
--         FROM post
--         JOIN newVoteEvents
--         WHERE id = newVoteEvents.postId
--         UNION ALL
--         SELECT p.id, p.parentId
--         FROM post p
--         INNER JOIN Ancestors a ON p.id = a.parentId
--     )
--     SELECT * FROM Ancestors
-- )
-- , scores as (
--         select
--             tagId
--             , ifnull(parentId, 0) parentId
--             , postId
--             , ifnull(topNoteId, 0) topNoteId
--             , ifnull(parentUninformedP, 0) parentUninformedP
--             , ifnull(parentInformedP, 0) parentInformedP
--             , ifnull(uninformedP, 0) uninformedP
--             , ifnull(informedP, 0) informedP
--             , ifnull(uninformedP, 0) uninformedP
--             , ifnull(informedP, 0) informedP
--             , count
--             , total
--             , selfP
--         from ScoreData  
--         join parameters
--             where ifnull(tagId = tag_id, true)
--             and ifnull(parentId = post_id, parentId is null) -- children of given post if supplied, otherwise top-level posts
-- ) 
-- select * from scores
-- left join invalidated using (postId);



-- where not invalidated



-- , tallies as (
--     select
--         tagId
--         , parentId
--         , postId
--         , noteId
--         , ifnull(overallCount, 0)    as parentCount
--         , ifnull(overallTotal, 0)    as parentTotal
--         , ifnull(uninformedCount, 0) as uninformedCount
--         , ifnull(uninformedTotal, 0) as uninformedTotal
--         , ifnull(informedCount, 0)   as informedCount
--         , ifnull(informedTotal, 0)   as informedTotal
--         , ifnull(noteCount, 0)       as selfCount
--         , ifnull(noteTotal, 0)       as selfTotal
--     from DetailedTally
--     join newVoteEvents on
--             tagId = tag_id
--             and postId = post_id

--     -- where tagId = tag_id
--           -- and parentId = post_id


-- )
-- select * from tallies;


-- select
--     scores.*
--     , tallies.*
--     , invalidated.id is not null as invlidated
-- from
--     tallies
--     left join invalidated on (invalidated.id = tallies.postId)
--     left join scores on (scores.postId = tallies.postId)
-- ;

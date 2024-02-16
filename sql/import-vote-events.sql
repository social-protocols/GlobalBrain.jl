drop table if exists temp.VoteEventImport;

.mode csv
.header on
.import --schema temp --csv data/vote-events-dump.csv VoteEventImport

insert into ProcessedVoteEvent(voteEventId, userId, tagId, parentId, postId, noteId, vote, createdAt) select 
	rowid as voteEventId,
	userId,
	tagId,
	case when parentId = '' then null else parentId end as parentId,
	postId,
	case when noteId = '' then null else noteId end as noteId,
	vote,
	createdAt
from voteEventImport;

drop table temp.VoteEventImport;


.mode column

-- select * from Vote limit 10; 
-- select * from Post limit 10; 
select * From voteEvent limit 10;
select * from InformedVote where eventType  =1 limit 10; 
select * from InformedTally where eventType = 1 limit 10;
select * from uninformedTally where eventType = 1 limit 10;
select * from post limit 10;
select * from detailedTally limit 10;


-- -- select * from VoteEvent;
-- select * from lastVoteEvent;
-- select * from voteEvent;

--skip 1 
-- drop table VoteEvent;

-- if it begins with a "|" character, it specifies a command which will be run to produce the input data.

-- insert into voteEventProcessor select * from voteEve0ntsel
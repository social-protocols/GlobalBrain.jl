create table if not exists VoteEvent(
    voteEventId integer not null, 
    userId text not null,
    tagId int not null,
    parentId int,
    postId int not null,
    noteId int,
    vote int not null,
    createdAt int not null,
    processedAt int,
    primary key(voteEventId)
) strict;

create table if not exists Vote (
	userId text,
	tagId integer not null,
	postId integer not null,
	vote integer not null,
	latestVoteEventId integer not null,
	createdAt integer not null,
	updatedAt integer not null,
	primary key(userId, tagId, postId)
) strict;

create table if not exists Tally (
	tagId integer not null,
	postId integer not null,
	count integer not null,
	total integer not null,
	primary key(tagId, postId)
 ) strict;

create table if not exists UninformedVote (
	userId text,
	tagId integer not null,
	postId integer not null,
	noteId integer not null,
	eventType integer not null,
	vote integer not null,
	primary key(userId, tagId, postId, noteId, eventType)
) strict;

create table if not exists UninformedTally (
	tagId integer not null,
	postId integer not null,
	noteId integer not null,
	eventType integer not null,
	count integer not null,
	total integer not null,
	primary key(tagId, postId, noteId, eventType)
) strict;

create table if not exists InformedVote (
	userId text,
	tagId integer not null,
	postId integer not null,
	noteId integer not null,
	eventType integer not null,
	vote integer not null,
	createdAt integer not null,
	primary key(userId, tagId, postId, noteId, eventType)
) strict;

create table if not exists InformedTally (
	tagId Integer not null,
	postId integer not null,
	noteId integer not null,
	eventType integer not null,
	count Integer not null,
	total Integer not null,
	primary key(tagId, postId, noteId, eventType)
) strict;

create table if not exists Post (
	parentId integer,
	id integer not null,
	primary key(id)
) strict;

create index if not exists post_parent on Post(parentId);
create index if not exists Vote_tag_user_post on Vote(tagId, userId, postId);
create index if not exists InformedVote_tag_user_post on InformedVote(tagId, userId, postId);
create index if not exists InformedVote_tag_user_post_note on InformedVote(tagId, userId, postId, noteId);
create index if not exists InformedTally_tag_post on InformedTally(tagId, postId);
create index if not exists InformedTally_tag_post_note on InformedTally(tagId, postId, noteId);

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
	, current.count as currentCount
	, current.total as currentTotal
	, forNote.count as noteCount
	, forNote.total as noteTotal
 from a
	left join uninformedTally using (tagId, postId, noteId, eventType)
	left join tally current on (current.postId = a.postId)
	left join tally forNote on (forNote.postId = a.noteId)
;

create view if not exists ProcessedVoteEvent(
    voteEventId, 
    userId,
    tagId,
    parentId,
    postId,
    noteId,
    vote,
    createdAt
) AS select * from VoteEvent where processedAt is not null;

create table if not exists LastVoteEvent (
	type integer,
	voteEventId integer not null,
	primary key(type)
) strict;

insert into lastVoteEvent values(1,0);



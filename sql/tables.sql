create table if not exists VoteEvent(
    voteEventId integer not null, 
    userId text not null,
    tagId integer not null,
    parentId integer,
    postId integer not null,
    noteId integer,
    vote int not null,
    createdAt int not null,
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
	latestVoteEventId integer not null,
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
	tagId integer not null,
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

create table if not exists ScoreData(
    tagId               integer
    , parentId          integer
    , postId            integer not null
    , topNoteId         integer
    , parentQ           real
    , parentP           real
    , q                 real
    , p                 real
    , count             integer
    , sampleSize        integer
    , updatedAt integer not null default (unixepoch('subsec')*1000)
    , primary key(tagId, postId)
) strict;

create table if not exists LastVoteEvent (
	type integer,
	importedVoteEventId integer not null default 0,
	processedVoteEventId integer not null default 0,
	primary key(type)
) strict;

insert into lastVoteEvent values(1,0,0);

create index if not exists post_parent on Post(parentId);
create index if not exists Vote_tag_user_post on Vote(tagId, userId, postId);
create index if not exists InformedVote_tag_user_post on InformedVote(tagId, userId, postId);
create index if not exists InformedVote_tag_user_post_note on InformedVote(tagId, userId, postId, noteId);
create index if not exists InformedTally_tag_post on InformedTally(tagId, postId);
create index if not exists InformedTally_tag_post_note on InformedTally(tagId, postId, noteId);




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
    parentId integer,
    postId integer not null,
    vote integer not null,
    latestVoteEventId integer not null,
    createdAt integer not null,
    updatedAt integer not null,
    primary key(userId, tagId, postId)
) strict;

create table if not exists Tally (
    tagId integer not null,
    parentId integer,
    postId integer not null,
    latestVoteEventId integer not null,
    count integer not null,
    total integer not null,
    primary key(tagId, postId)
 ) strict;

create table if not exists ConditionalVote (
    userId text,
    tagId integer not null,
    postId integer not null,
    noteId integer not null,
    eventType integer not null,
    informedVote integer not null,
    uninformedVote integer not null,
    primary key(userId, tagId, postId, noteId, eventType)
) strict;

create table if not exists ConditionalTally (
    tagId integer not null,
    postId integer not null,
    noteId integer not null,
    eventType integer not null,
    informedCount integer not null,
    informedTotal integer not null,
    uninformedCount integer not null,
    uninformedTotal integer not null,
    primary key(tagId, postId, noteId, eventType)
) strict;

create table if not exists Post (
    parentId integer,
    id integer not null,
    primary key(id)
) strict;

create table if not exists ScoreEvent(
    voteEventId         integer not null
    , voteEventTime     integer not null
    , tagId             integer
    , parentId          integer
    , postId            integer not null
    , topNoteId         integer
    , parentP           real
    , parentQ           real
    , p                 real
    , q                 real
    , overallP          real
    -- , informedCount         integer
    -- , informedSampleSize    integer
    -- , uninformedCount       integer
    -- , uninformedSampleSize  integer
    -- , overallCount          integer
    -- , overallSampleSize     integer
    , count          integer
    , sampleSize     integer
    , score             real
    , primary key(voteEventId, postId)
) strict;


create table if not exists Score(
    voteEventId         integer not null
    , tagId             integer
    , voteEventTime     integer not null
    , parentId          integer
    , postId            integer not null
    , topNoteId         integer
    , parentP           real
    , parentQ           real
    , p                 real
    , q                 real
    , overallP          real
    -- , informedCount             integer
    -- , informedSampleSize        integer
    -- , uninformedCount             integer
    -- , uninformedSampleSize        integer
    -- , overallCount             integer
    -- , overallSampleSize        integer
    , count             integer
    , sampleSize        integer
    , score             real
    , primary key(tagId, postId)
) strict;


create table if not exists LastVoteEvent (
    type integer,
    importedVoteEventId integer not null default 0,
    processedVoteEventId integer not null default 0,
    primary key(type)
) strict;


insert into LastVoteEvent values(1,0,0);

create index if not exists post_parent on Post(parentId);
create index if not exists Vote_tag_user_post on Vote(tagId, userId, postId);
create index if not exists ConditionalVote_tag_user_post on ConditionalVote(tagId, userId, postId);
create index if not exists ConditionalVote_tag_user_post_note on ConditionalVote(tagId, userId, postId, noteId);




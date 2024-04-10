create table if not exists VoteEvent(
      vote_event_id   integer not null
    , vote_event_time integer not null
    , user_id         text    not null
    , tag_id          integer not null
    , parent_id       integer
    , post_id         integer not null
    , note_id         integer
    , vote            integer not null
    , primary key(vote_event_id)
) strict;

create table if not exists Vote(
      vote_event_id   integer not null
    , vote_event_time integer not null
    , user_id         text not null
    , tag_id          integer not null
    , parent_id       integer
    , post_id         integer not null
    , vote            integer not null
    , primary key(user_id, tag_id, post_id)
) strict;

create table if not exists Tally(
      tag_id               integer not null
    , parent_id            integer
    , post_id              integer not null
    , latest_vote_event_id integer not null
    , count                integer not null
    , total                integer not null
    , primary key(tag_id, post_id)
) strict;

create table if not exists ConditionalVote(
      user_id         text not null
    , tag_id          integer not null
    , post_id         integer not null
    , note_id         integer not null
    , event_type      integer not null
    , informed_vote   integer not null
    , uninformed_vote integer not null
    , is_informed     integer not null
    , primary key(user_id, tag_id, post_id, note_id, event_type)
) strict;

create table if not exists ConditionalTally(
      tag_id           integer not null
    , post_id          integer not null
    , note_id          integer not null
    , event_type       integer not null
    , informed_count   integer not null
    , informed_total   integer not null
    , uninformed_count integer not null
    , uninformed_total integer not null
    , primary key(tag_id, post_id, note_id, event_type)
 ) strict;

create table if not exists Post(
      parent_id  integer
    , id         integer not null
    , content    text default ''
    , primary key(id)
) strict;

create table if not exists Lineage(
      ancestor_id   integer
    , descendant_id integer not null
    , separation    integer not null
    , primary key(ancestor_id, descendant_id)
) strict;

create table if not exists EffectEvent(
      vote_event_id   integer not null
    , vote_event_time integer not null
    , tag_id          integer not null
    , post_id         integer not null 
    , note_id         integer not null
    , p               real    not null
    , p_count         integer not null
    , p_size          integer not null
    , q               real    not null
    , q_count         integer not null
    , q_size          integer not null
    , r               real    not null
    , primary key(vote_event_id, post_id, note_id)
) strict;

create table if not exists Effect(
      vote_event_id   integer not null
    , vote_event_time integer not null
    , tag_id          integer not null
    , post_id         integer not null 
    , note_id         integer not null
    , p               real    not null
    , p_count         integer not null
    , p_size          integer not null
    , q               real    not null
    , q_count         integer not null
    , q_size          integer not null
    , r               real    not null
    , primary key(tag_id, post_id, note_id)
) strict;

create table if not exists ScoreEvent(
      vote_event_id     integer not null
    , vote_event_time   integer not null
    , tag_id            integer not null
    , post_id           integer not null
    , top_note_id       integer
    , o                 real    not null
    , o_count           integer not null
    , o_size            integer not null
    , p                 real    not null
    , score             real    not null
    , primary key(vote_event_id, post_id)
) strict;

create table if not exists Score(
      vote_event_id     integer not null
    , vote_event_time   integer not null
    , tag_id            integer not null
    , post_id           integer not null
    , top_note_id       integer
    , o                 real    not null
    , o_count           integer not null
    , o_size            integer not null
    , p                 real    not null
    , score             real    not null
    , primary key(tag_id, post_id)
) strict;

create table if not exists LastVoteEvent(
      type                    integer
    , imported_vote_event_id  integer not null default 0
    , processed_vote_event_id integer not null default 0
    , primary key(type)
) strict;

insert into LastVoteEvent values(1, 0, 0);

create TABLE Tag (
      id  integer NOT NULL PRIMARY KEY AUTOINCREMENT
    , tag text NOT NULL
) STRICT;

create table Period(tag_id INTEGER not null, step INTEGER not null, description TEXT);

create index if not exists post_parent on Post(parent_id);
create index if not exists Vote_tag_user_post on Vote(tag_id, user_id, post_id);
create index if not exists ConditionalVote_tag_user_post
on ConditionalVote(tag_id, user_id, post_id);
create index if not exists ConditionalVote_tag_user_post_note
on ConditionalVote(tag_id, user_id, post_id, note_id);

function create_tables(db::SQLite.DB)
    stmts = [
        """
        create table VoteEvent(
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
        """,
        """
        create table Vote(
              vote_event_id   integer not null
            , vote_event_time integer not null
            , user_id         text not null
            , tag_id          integer not null
            , parent_id       integer
            , post_id         integer not null
            , vote            integer not null
            , primary key(user_id, tag_id, post_id)
        ) strict;
        """,
        """
        create table Tally(
              tag_id               integer not null
            , parent_id            integer
            , post_id              integer not null
            , latest_vote_event_id integer not null
            , count                integer not null
            , total                integer not null
            , primary key(tag_id, post_id)
        ) strict;
        """,
        """
        create table InformedVote(
          user_id text not null,
          tag_id integer not null,
          post_id integer not null,
          note_id integer not null,
          vote integer not null,
          informed integer not null,
          primary key(user_id, tag_id, post_id, note_id)
        ) strict;
        """,

        # """
        # create index InformedVote_user_tag_post
        # on InformedVote(user_id, tag_id, post_id);
        # """,

        # """
        # create index InformedVote_tag_post
        # on InformedVote(tag_id, post_id);
        # """,

        # """
        # create index InformedVote_tag_post_note
        # on InformedVote(tag_id, post_id, note_id);
        # """,

        """
        create table InformedTally(
              tag_id           integer not null
            , post_id          integer not null
            , note_id          integer not null
            , count   integer not null
            , total   integer not null
            , primary key(tag_id, post_id, note_id)
         ) strict;
        """,
        """
        create table Post(
              parent_id  integer
            , id         integer not null
            , first_vote_event_id integer not null
            , content    text default ''
            , primary key(id)
        ) strict;
        """,
        """
        create index post_parent on Post(parent_id);
        """,
        """
        create table Lineage(
              ancestor_id   integer
            , descendant_id integer not null
            , separation    integer not null
            , primary key(ancestor_id, descendant_id)
        ) strict;
        """,
        """
        create index Lineage_ancestor_id
        on Lineage(ancestor_id);
        """,
        """
        create index Lineage_descendant_id
        on Lineage(descendant_id);
        """,
        """
        create table EffectEvent(
              vote_event_id   integer not null
            , vote_event_time integer not null
            , tag_id          integer not null
            , post_id         integer not null 
            , note_id         integer not null
            , top_subthread_id         integer
            , p               real    not null
            , p_count         integer not null
            , p_size          integer not null
            , q               real    not null
            , q_count         integer not null
            , q_size          integer not null
            , r               real    not null
            , primary key(vote_event_id, post_id, note_id)
        ) strict;
        """,
        """
        create table Effect(
              vote_event_id   integer not null
            , vote_event_time integer not null
            , tag_id          integer not null
            , post_id         integer not null 
            , note_id         integer not null
            , top_subthread_id         integer
            , p               real    not null
            , p_count         integer not null
            , p_size          integer not null
            , q               real    not null
            , q_count         integer not null
            , q_size          integer not null
            , r               real    not null
            , primary key(tag_id, post_id, note_id)
        ) strict;
        """,
        """
        create index Effect_tag_post
        on Effect(tag_id, post_id);
        """,
        """
        create table ScoreEvent(
              vote_event_id     integer not null
            , vote_event_time   integer not null
            , tag_id            integer not null
            , post_id           integer not null
            , top_note_id       integer
            , critical_thread_id       integer
            , o                 real    not null
            , o_count           integer not null
            , o_size            integer not null
            , p                 real    not null
            , score             real    not null
            , primary key(vote_event_id, post_id)
        ) strict;
        """,
        """
        create table Score(
              vote_event_id     integer not null
            , vote_event_time   integer not null
            , tag_id            integer not null
            , post_id           integer not null
            , top_note_id       integer
            , critical_thread_id       integer
            , o                 real    not null
            , o_count           integer not null
            , o_size            integer not null
            , p                 real    not null
            , score             real    not null
            , primary key(tag_id, post_id)
        ) strict;
        """,
        """
        create table LastVoteEvent(
              type                    integer
            , imported_vote_event_id  integer not null default 0
            , processed_vote_event_id integer not null default 0
            , primary key(type)
        ) strict;
        """,
        """
        insert into LastVoteEvent values(1, 0, 0);
        """,
        """
        create TABLE Tag (
              id  integer NOT NULL PRIMARY KEY AUTOINCREMENT
            , tag text NOT NULL
        ) STRICT;
        """,
    ]

    map((stmt) -> DBInterface.execute(db, stmt), stmts)
end

function create_views(db::SQLite.DB)
    stmts = [
        """
        -- Whenever there is a vote, we need to recalculate scores for
        -- 1) the post that was voted on
        -- 2) all ancestors of the post that was voted on (because a post's score depends on the votes on its descendants)
        -- 3) all descendants of the post that was voted on (because a post's score also includes its effect ancestors)
        create view NeedsRecalculation as
        -- First, select posts that were voted on since last processed_vote_event_id
        with leafNode as (
            select post_id, tag_id
            from tally
            join LastVoteEvent
            on latest_vote_event_id > processed_vote_event_id
        )
        select * from leafNode

        union
        -- Next, select all ancestors
        select ancestor_id as post_id, tag_id
        from leafNode join Lineage Ancestor on (post_id = descendant_id)

        union
        -- Next, select all descendants
        select descendant_id as post_id, tag_id
        from leafNode
        join Lineage Descendant on (post_id = ancestor_id); -- descendant of item that was voted on
        """,
        """
        create view VoteEventImport as
        select
            0  as vote_event_id,
            '' as user_id,
            0  as tag_id,
            '' as parent_id,
            0  as post_id,
            '' as note_id,
            0  as vote,
            0  as vote_event_time;
        """,
        """
        create view ImplicitlyInformedVote as 
          select
            iv.user_id
            , iv.tag_id
            , iv.post_id
            , lineage.ancestor_id as note_id
            , iv.vote as vote
            , (iv.informed or ifnull(vote.vote,0) != 0) as informed
            , iv.note_id as informed_by_post_id
          from 
          InformedVote iv
          join lineage
            on lineage.descendant_id = iv.note_id
            and lineage.ancestor_id > iv.post_id
          left join vote 
            on vote.post_id = lineage.ancestor_id
            and vote.tag_id = iv.tag_id
            and vote.user_id = iv.user_id
        ;     
        """,
        """
        create view ConditionalTally as 

        -- this query is somewhat counter-intuitive. The strangeness arises from this rule:
        -- Only count user as uninformed of a post when the user is informed of the parent of the post.
        -- This rule is described here: https://github.com/social-protocols/internal-wiki/blob/main/pages/research-notes/2024-05-24-calculating-tallies.md
        --
        -- The the uninformed tally is just the partially-informed tally minus
        -- the informed tally. The partially-informed tally is the tally of users who are informed
        -- of the parent of the note but not the note itself.

        -- So our first step is to select all partially-informed tallies.
        with PartiallyInformed as (
          -- The partially-informed tally for note C and target A is the
          -- informed tally of the parent of C and target A.
          select * from InformedTally
          UNION ALL
          -- If the note is a direct child of the target then the
          -- partially-informed tally is the overall tally for the target.
          select tag_id, post_id, post_id as note_id, count, total
          from tally
        )
        select
          Informed.tag_id
          , Informed.post_id
          , Informed.note_id
          , Informed.count as informed_count
          , Informed.total as informed_total
          , PartiallyInformed.count - Informed.count + ifnull(Preinformed.count,0) as uninformed_count
          , PartiallyInformed.total - Informed.total + ifnull(Preinformed.total,0) as uninformed_total
        from
          InformedTally Informed 
          join Post on (post.id = Informed.note_id)
          join PartiallyInformed on
            PartiallyInformed.note_id = post.parent_id
            and PartiallyInformed.post_id = informed.post_id
            and PartiallyInformed.tag_id = informed.tag_id
          left join PreinformedTally Preinformed using(tag_id, post_id, note_id)
        ;

        ;
        """,
    ]

    map((stmt) -> DBInterface.execute(db, stmt), stmts)
end

function create_triggers(db::SQLite.DB)

    stmts = [
        """
        create trigger afterInsertEffectEvent after insert on EffectEvent begin
            insert or replace into Effect
            values (
                  new.vote_event_id
                , new.vote_event_time
                , new.tag_id
                , new.post_id
                , new.note_id
                , new.top_subthread_id
                , new.p
                , new.p_count
                , new.p_size
                , new.q
                , new.q_count
                , new.q_size
                , new.r
            );
        end;
        """,
        """
        create trigger afterInsertScoreEvent after insert on ScoreEvent begin
            insert or replace into Score
            values (
                new.vote_event_id
                , new.vote_event_time
                , new.tag_id
                , new.post_id
                , new.top_note_id
                , new.critical_thread_id
                , new.o
                , new.o_count
                , new.o_size
                , new.p
                , new.score
            );
        end;
        """,
        """
        -- Inserting into ProcessVoteEvent will "process" the event and update the tallies, but only if the event hasn't been processed
        -- that is, if the vote_event_id is greater than lastVoteEvent.vote_event_id
        create trigger afterInsertOnInsertVoteEventImport instead of insert on VoteEventImport
        begin

            insert into VoteEvent(
                  vote_event_id
                , vote_event_time
                , user_id
                , tag_id
                , parent_id
                , post_id
                , note_id
                , vote
            ) 
            select
                  new.vote_event_id
                , new.vote_event_time
                , new.user_id
                , new.tag_id
                , case when new.parent_id = '' then null else new.parent_id end as parent_id
                , new.post_id
                , case when new.note_id = '' then null else new.note_id end as note_id
                , new.vote
            where new.vote_event_id > (select imported_vote_event_id from lastVoteEvent)
            on conflict do nothing;
            -- We don't actually have keep vote events in this database once the triggers have updated the tallies.
            -- delete from voteEvent where vote_event_id = new.vote_event_id;
        end;
        """,
        """
        create trigger afterInsertPost after insert on Post
        when new.parent_id is not null
        begin

            -- Insert a lineage record for parent
            insert into Lineage(ancestor_id, descendant_id, separation)
            values(new.parent_id, new.id, 1) on conflict do nothing;

            -- Insert a lineage record for all ancestors of this parent
            insert into Lineage
            select 
                  ancestor_id
                , new.id as descendant_id
                , 1 + separation as separation
            from lineage ancestor 
            where ancestor.descendant_id = new.parent_id;
        end;
        """,


        # These SQL statements calculate the conditional tallies. These give us the tallies of votes on a post given users were or were not informed of the note.
        # The logic and reasoning behind these calculations is discussed here:
        # https://github.com/social-protocols/internal-wiki/blob/main/pages/research-notes/2024-05-24-calculating-tallies.md
        #
        # The informed tally table is an aggregate of the **informed vote**
        # table. The informed vote table tells has an entry for every informed vote
        # e.g. for every post-note combination a user has voted on. Since a
        # a user can become-uninformed by clearing votes, the "informed" field 
        # in this table can be zero.
        #
        # TODO:
        #  -- test case voting on the grandchild creates an informed vote for the child
        #  -- test case of clearing vote on note causing informed vote on post to be cleared.

        """
        create trigger afterInsertOnVoteEvent after insert on VoteEvent
        begin

            -- Insert/update the vote record
            insert into Vote(
                  vote_event_id
                , vote_event_time
                , user_id
                , tag_id
                , parent_id
                , post_id
                , vote
            ) 
            values(
                  new.vote_event_id
                , new.vote_event_time
                , new.user_id
                , new.tag_id
                , new.parent_id
                , new.post_id
                , new.vote
            ) on conflict(user_id, tag_id, post_id) do update set
                  vote            = new.vote
                , vote_event_id   = new.vote_event_id
                , vote_event_time = new.vote_event_time
            ;

            -- Insert a record for the post the first time we see this post id.
            insert into Post(parent_id, id, first_vote_event_id)
            values(new.parent_id, new.post_id, new.vote_event_id) on conflict do nothing;

            insert into InformedVote
            select
              new.user_id
              , new.tag_id
              , targetVote.post_id as post_id
              , new.post_id as note_id
              , targetVote.vote as vote
              , new.vote != 0 as informed
            from 
              lineage
              join vote targetVote 
              on targetVote.post_id = lineage.ancestor_id
            where 
              lineage.descendant_id = new.post_id
              and targetVote.tag_id = new.tag_id
              and targetVote.user_id = new.user_id
            on conflict(user_id, tag_id, post_id, note_id) do update set
              informed = excluded.informed
              , vote = excluded.vote
            ;

            insert into InformedVote
            select
              new.user_id
              , new.tag_id
              , new.post_id as post_id
              , noteVote.post_id as note_id
              , new.vote as vote
              , noteVote.vote != 0 as informed
            from 
              lineage
              join vote noteVote 
              on noteVote.post_id = lineage.descendant_id
            where 
              lineage.ancestor_id = new.post_id
              and noteVote.tag_id = new.tag_id
              and noteVote.user_id = new.user_id
            on conflict(user_id, tag_id, post_id, note_id) do update set
              informed = excluded.informed
              , vote = excluded.vote
            ;

            insert into InformedVote
            select user_id, tag_id, post_id, note_id, vote, informed
            from ImplicitlyInformedVote
            where informed_by_post_id = new.post_id
            on conflict(user_id, tag_id, post_id, note_id) do update set
              informed = excluded.informed
              , vote = excluded.vote
            ;

        end;
        """,
        """
        create trigger afterInsertVote after insert on Vote begin

            insert into Tally(
                  tag_id
                , parent_id
                , post_id
                , latest_vote_event_id
                , count
                , total
            )
            values (
                  new.tag_id
                , new.parent_id
                , new.post_id
                , new.vote_event_id
                , (new.vote == 1)
                , (new.vote != 0)
            ) on conflict(tag_id, post_id) do update 
            set 
                  total                = total + (new.vote != 0)
                , count                = count + (new.vote == 1)
                , latest_vote_event_id = new.vote_event_id
            ;

        end;
        """,
        """
        create trigger afterUpdateVote after update on Vote begin
            update Tally
            set 
                total                  = total + (new.vote != 0) - (old.vote != 0)
                , count                = count + (new.vote == 1) - (old.vote == 1)
                , latest_vote_event_id = new.vote_event_id
            where tag_id = new.tag_id
            and post_id = new.post_id
            ;

        end;
        """,
        """
        create trigger afterInsertInformedVote after insert on InformedVote 
        when new.informed = 1 
        begin
           insert into InformedTally(
                  tag_id
                , post_id
                , note_id
                , count
                , total
            ) 
            values (
                new.tag_id
                , new.post_id
                , new.note_id
                , (new.vote = 1)
                , (new.vote != 0)
            ) 
            on conflict(tag_id, post_id, note_id) do update
            set
                  count   = count + (new.vote = 1)
                , total   = total + (new.vote != 0)
            ;

        end;
        """,
        """
        create trigger afterUpdateInformedVote after update on InformedVote begin
            update InformedTally
            set
                count     = count + ((new.vote = 1 and new.informed) - (old.vote = 1 and old.informed))
                , total   = total + ((new.vote != 0 and new.informed) - (old.vote != 0 and old.informed))
            where
            tag_id = new.tag_id
            and post_id = new.post_id
            and note_id = new.note_id
            ;
        end;
        """,
        """
        create view PreinformedVote as 
            select
                informedVote.tag_id
                , informedVote.post_id
                , informedVote.note_id
                , informedVote.user_id 
                , voteEvent.vote
                , max(vote_event_id) as last_vote_event_id 
            from 
            informedVote
            join post note on note.id = informedVote.note_id
            join voteEvent using (tag_id, post_id, user_id)
            where vote_event_id <= note.first_vote_event_id
            and informed = 1
            group by 1,2,3,4;
        """,
        """
        create view PreinformedTally as 
          select
            tag_id
            , post_id
            , note_id
            , sum(vote == 1) as count
            , sum(vote != 0) as total
          from PreinformedVote
          group by 1, 2, 3
        ;
        """,
    ]

    map((stmt) -> DBInterface.execute(db, stmt), stmts)
end

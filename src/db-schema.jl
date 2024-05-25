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
            , informed_count   integer not null
            , informed_total   integer not null
            , primary key(tag_id, post_id, note_id)
         ) strict;
        """,

        """
        create table Post(
              parent_id  integer
            , id         integer not null
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

        """
        create table Period(tag_id INTEGER not null, step INTEGER not null, description TEXT);
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
        with overall as (
          select * from InformedTally
          UNION ALL
          select tag_id, post_id, post_id, count, total
          from tally
        )
        select
          informed.tag_id
          , informed.post_id
          , informed.note_id
          , informed.informed_count
          , informed.informed_total
          , overall.informed_count - informed.informed_count as uninformed_count
          , overall.informed_total - informed.informed_total as uninformed_total
        from
          -- this join is very counter-intuitive. The strangeness arises from this rule:
          -- 2. Only count user as uninformed of a post when the user is informed of the parent of the post.
          -- The way to think of this is that the informed tally is just the "overall" tally minus
          -- the informed tally. But the "overall" tally is the tally of users who are informed
          -- of the parent of the note -- not the tally of all users who voted on the target post.
          overall
          join post on (post.parent_id = overall.note_id)
          join InformedTally informed on informed.note_id = post.id
        where
          overall.post_id = informed.post_id
          and overall.tag_id = informed.tag_id
        ;
        """,
    ]

    map((stmt) -> DBInterface.execute(db, stmt), stmts)
end

function create_triggers(db::SQLite.DB)
        # todo: 
        #  -- don't output effects if there is p_count and q_count are zero 
        #         > {"vote_event_id":24,"vote_event_time":1709893374865,"effect":{"tag_id":1,"post_id":1,"note_id":9,"p":0.5684,"p_count":0,"p_size":0,"q":0.5684,"q_count":0,"q_size":0}}
        # TODO:
        #  -- test case voting on the grandchild creates an informed vote for the child
        #  -- test case of clearing vote on note causing informed vote on post to be cleared.

        # These SQL statements calculate the conditional tallies. These give us the tallies of votes on a post given users were or were not informed of the note.

        # The first thing to understand about these tallies is that they can "double count". If 10 users vote on a post without being informed of the note, and then they all
        # were later informed of the note, then both the uninformed tally and the informed tally will have a sample size of 10. Even though there are only 10 actual users.

        # On the other hand, it's possible for there to be no overlap, for example if 5 users voted on a post and were never informed of the note, and the other fiver voted
        # on the post only after being informed (they were never uninformed).

        # Another important thing to understand is that, currently, being included in the informed tally doesn't require users to change their vote. If all 10 users initially upvote a post, then all 10 users are informed,
        # and none of them change their vote, then the informed vote and the uninformed tallies are both 10/10.

        # The conditional tallies are simple aggregates of the **conditional vote**. table The conditional vote table tells us both the uninformed and informed vote of a user on a post/note combination.
        # The uninformed_vote or informed_vote fields can be zero if there is no uninformed or informed vote, respectively.

        # There are (at least theoretically) different ways that users can be informed. Our originally idea was that we consider a vote to be informed if the note was
        # shown below the post at the time the user voted on the post. But as discussed in [this research note](https://github.com/social-protocols/internal-wiki/blob/main/pages/research-notes/2024-02-06-informed-probability.md), the fact
        # of actually voting on a note is probably a better for proxy for whether the user has actually **considered** the note, which is really what we care about when talking
        # about users being "informed". 

        # So the event_type field is used to designate the way in which users are informed. event_type=1 means "voted on post while note was shown below post" and event_type=2 means
        # "voted on post and voted on note". For event_type=2, the order doesn't matter. If at any time the user voted on the post without having voted on the note, there is an uninformed vote. 
        # If at any time the user has voted on the post and the note there is an informed vote. This is why the same user can be counted twice, even if they only voted on the post once. 

        # Since a note can be any descendent of the post, another important rule to underatand is that a conditional vote is only counted if the user also voted on the parent of the note.
        # For example, if we have posts A→B→C, then the conditional votes for post A given informed/uninformed of note C only include users who also voted on B. So the uninformed votes are votes where user
        # was informed of B but not C. And the informed votes are votes where the user was informed of B and C. But, since voting on a post implies considering its parent, the informed votes
        # can be defined simply as votes where the user was informed of C.

        # So a conditional vote on a post requires a vote on the parent of the note. If the note is a direct child of the vote, this is trivially true (we only count conditional votes on the post given
        # the user has voted on the post). But in the case of *clearing* votes it creates some subtleties in the logic we have to think through (if a user clears their vote on a post, we set the
        # vote value to zero and then update the informed or uninformed vote to be zero as appropriate. We should make sure *not* to update conditional votes only if the value of the vote on the parent of the note is not zero). 

        # A finally thing to understand is that being uninformed is "sticky". You can't undo the fact that a user was once uninformed. Once the user becomes informed, then any changes
        # to their vote changes their informed vote, not their uninformed vote.

        # However, a user can become un-informed. This doesn't sound like it makes sense but we do allow users to clear their vote on the note. The semanitics of voting and then
        # clearing a vote should pretty much be the same as never having voted. So both clearing their vote on the post and clearing their vote on the note should result in the uninformed
        # vote being cleared. If the user clears their vote on the note but leaves their vote on the post, the uninformed vote should be updated.

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
            insert into Lineage(ancestor_id, descendant_id, separation)
            values(new.parent_id, new.id, 1) on conflict do nothing;
        end;
        """,

        """
        create trigger afterInsertLineage after insert on Lineage
        begin
            -- Insert a record for all ancestors of this ancestor
            insert into Lineage
            select 
                  ancestor.ancestor_id                 as ancestor_id
                , new.descendant_id                    as descendant_id
                , new.separation + ancestor.separation as separation
            from lineage ancestor 
            where ancestor.descendant_id = new.ancestor_id
            on conflict do nothing;
        end;
        """,


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
            insert into Post(parent_id, id)
            values(new.parent_id, new.post_id) on conflict do nothing;

 
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
                  , informed_count
                  , informed_total
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
                    informed_count   = informed_count + (new.vote = 1)
                  , informed_total   = informed_total + (new.vote != 0) 
              ;
          end;
        """,

        """
        create trigger afterUpdateInformedVote after update on InformedVote begin
            update InformedTally
            set
                informed_count     = informed_count + ((new.vote = 1) - (old.vote = 1))
                , informed_total   = informed_total + ((new.vote != 0) - (old.vote != 0))
            where
            tag_id = new.tag_id
            and post_id = new.post_id
            and note_id = new.note_id
            and new.informed = 1
            ;
        end;
        """,


    ]

    map((stmt) -> DBInterface.execute(db, stmt), stmts)
end

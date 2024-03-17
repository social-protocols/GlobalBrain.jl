-- todo: 
    -- don't output effects if there is p_count and q_count are zero 
--         > {"vote_event_id":24,"vote_event_time":1709893374865,"effect":{"tag_id":1,"post_id":1,"note_id":9,"p":0.5684,"p_count":0,"p_size":0,"q":0.5684,"q_count":0,"q_size":0}}
-- TODO:
    -- test case voting on the grandchild creates an informed vote for the child
    -- test case of clearing vote on note causing informed vote on post to be cleared.

-- These SQL statements calculate the conditional tallies. These give us the tallies of votes on a post given users were or were not informed of the note.

-- The first thing to understand about these tallies is that they can "double count". If 10 users vote on a post without being informed of the note, and then they all
-- were later informed of the note, then both the uninformed tally and the informed tally will have a sample size of 10. Even though there are only 10 actual users.

-- On the other hand, it's possible for there to be no overlap, for example if 5 users voted on a post and were never informed of the note, and the other fiver voted
-- on the post only after being informed (they were never uninformed).

-- Another important thing to understand is that, currently, being included in the informed tally doesn't require users to change their vote. If all 10 users initially upvote a post, then all 10 users are informed,
-- and none of them change their vote, then the informed vote and the uninformed tallies are both 10/10.

-- The conditional tallies are simple aggregates of the **conditional vote**. table The conditional vote table tells us both the uninformed and informed vote of a user on a post/note combination.
-- The uninformed_vote or informed_vote fields can be zero if there is no uninformed or informed vote, respectively.

-- There are (at least theoretically) different ways that users can be informed. Our originally idea was that we consider a vote to be informed if the note was
-- shown below the post at the time the user voted on the post. But as discussed in [this research note](https://github.com/social-protocols/internal-wiki/blob/main/pages/research-notes/2024-02-06-informed-probability.md), the fact
-- of actually voting on a note is probably a better for proxy for whether the user has actually **considered** the note, which is really what we care about when talking
-- about users being "informed". 

-- So the event_type field is used to designate the way in which users are informed. event_type=1 means "voted on post while note was shown below post" and event_type=2 means
-- "voted on post and voted on note". For event_type=2, the order doesn't matter. If at any time the user voted on the post without having voted on the note, there is an uninformed vote. 
-- If at any time the user has voted on the post and the note there is an informed vote. This is why the same user can be counted twice, even if they only voted on the post once. 

-- Since a note can be any descendent of the post, another important rule to underatand is that a conditional vote is only counted if the user also voted on the parent of the note.
-- For example, if we have posts A→B→C, then the conditional votes for post A given informed/uninformed of note C only include users who also voted on B. So the uninformed votes are votes where user
-- was informed of B but not C. And the informed votes are votes where the user was informed of B and C. But, since voting on a post implies considering its parent, the informed votes
-- can be defined simply as votes where the user was informed of C.

-- So a conditional vote on a post requires a vote on the parent of the note. If the note is a direct child of the vote, this is trivially true (we only count conditional votes on the post given
-- the user has voted on the post). But in the case of *clearing* votes it creates some subtleties in the logic we have to think through (if a user clears their vote on a post, we set the
-- vote value to zero and then update the informed or uninformed vote to be zero as appropriate. We should make sure *not* to update conditional votes only if the value of the vote on the parent of the note is not zero). 

-- A finally thing to understand is that being uninformed is "sticky". You can't undo the fact that a user was once uninformed. Once the user becomes informed, then any changes
-- to their vote changes their informed vote, not their uninformed vote.

-- However, a user can become un-informed. This doesn't sound like it makes sense but we do allow users to clear their vote on the note. The semanitics of voting and then
-- clearing a vote should pretty much be the same as never having voted. So both clearing their vote on the post and clearing their vote on the note should result in the uninformed
-- vote being cleared. If the user clears their vote on the note but leaves their vote on the post, the uninformed vote should be updated.

create trigger afterInsertEffectEvent after insert on EffectEvent begin

    insert or replace into Effect
    values (
          new.vote_event_id
        , new.vote_event_time
        , new.tag_id
        , new.post_id
        , new.note_id
        , new.p
        , new.p_count
        , new.p_size
        , new.q
        , new.q_count
        , new.q_size
        , new.r
    );

end;

create trigger afterInsertScoreEvent after insert on ScoreEvent begin

    insert or replace into Score
    values (
        new.vote_event_id
        , new.vote_event_time
        , new.tag_id
        , new.post_id
        , new.top_note_id
        , new.o
        , new.o_count
        , new.o_size
        , new.p
        , new.score
    );

end;

-- Inserting into ProcessVoteEvent will "process" the event and update the tallies, but only if the event hasn't been processed
-- that is, if the vote_event_id is greater than lastVoteEvent.vote_event_id

drop trigger if exists afterInsertOnInsertVoteEventImport;
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


create trigger afterInsertPost after insert on Post
when new.parent_id is not null
begin
    insert into Lineage(ancestor_id, descendant_id, separation)
    values(new.parent_id, new.id, 1) on conflict do nothing;
end;

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

create trigger afterInsertLineage2 after insert on Lineage
begin


    -- When there is a new post, we need to record an uninformed vote for every user who has voted on an ancestor of the post
    -- The triggers above don't take care of this, because they only insert/update ConditionalVote records for the
    -- current user, not *all* users who have voted on the parent.

    insert into ConditionalVote
    select
          user_id
        , tag_id
        , post_id
        , note_id
        , event_type
        , 0
        -- for the user who first voted on the note, the CurrentConditionalVote view will show the user as been informed
        -- but we want to record an uninformed vote for this user here.
        , case when informed then informed_vote else uninformed_vote end
        , 0
    from CurrentConditionalVote
    where 
         CurrentConditionalVote.post_id = new.ancestor_id
         and CurrentConditionalVote.note_id = new.descendant_id
     ;

end;

drop trigger if exists afterInsertOnVoteEvent;
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

    insert into Post(parent_id, id)
    values(new.parent_id, new.post_id) on conflict do nothing;


    -- Record conditional vote for all descendants of the post that was voted on, setting the informed_vote or uninformed_vote
    -- field depending on whether the user has voted on the descendant
    insert into ConditionalVote
    select * from CurrentConditionalVote 
    where 
         ( new.post_id = CurrentConditionalVote.post_id or new.post_id = CurrentConditionalVote.note_id )
         and new.user_id = CurrentConditionalVote.user_id
         and new.tag_id = CurrentConditionalVote.tag_id
    on conflict(user_id, tag_id, post_id, note_id, event_type) do update set
        -- Uninformed vote "sticks". When the user becomes uninformed we keep the value of the vote as it was before
        -- the user was informed. Informed vote does not stick, because a user clearing their vote on the note doesn't
        -- imply they become uninformed (which can't really happen), but rather made a mistake about their vote and hand't
        -- really considered the note.
        uninformed_vote = case when not excluded.is_informed then excluded.uninformed_vote else uninformed_vote end
        , informed_vote = excluded.informed_vote
        , is_informed = excluded.is_informed
    ;


    -- when the vote on the note is cleared, clear the informed_vote, and set the uninformed_vote to the previous value of the informed_vote
    update ConditionalVote 
    set 
          uninformed_vote = informed_vote
        , informed_vote = 0
        , is_informed = 0
    where new.vote = 0
    and user_id = new.user_id
    and tag_id = new.tag_id
    and note_id = new.post_id
    and event_type = 2
    ;

    insert into lastVoteEvent(type, imported_vote_event_id)
    values(1, new.vote_event_id) 
    on conflict do update set imported_vote_event_id = new.vote_event_id;

end;


drop trigger if exists afterInsertVote;
create trigger afterInsertVote after insert on Vote begin

    -- update ConditionalVote set informed_vote = new.vote where user_id = new.user_id and tag_id = new.tag_id and post_id = new.post_id;

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

drop trigger if exists afterUpdateVote;
create trigger afterUpdateVote after update on Vote begin

    -- update ConditionalVote set informed_vote = new.vote where user_id = new.user_id and tag_id = new.tag_id and post_id = new.post_id ;

    update Tally
    set 
        total                  = total + (new.vote != 0) - (old.vote != 0)
        , count                = count + (new.vote == 1) - (old.vote == 1)
        , latest_vote_event_id = new.vote_event_id
    where tag_id = new.tag_id
    and post_id = new.post_id
    ;
end;


create trigger afterInsertConditionalVote after insert on ConditionalVote begin

    insert into ConditionalTally(
          tag_id
        , post_id
        , note_id
        , event_type
        , informed_count
        , informed_total
        , uninformed_count
        , uninformed_total
    ) 
    values (
        new.tag_id
        , new.post_id
        , new.note_id
        , new.event_type
        , (new.informed_vote == 1)
        , (new.informed_vote != 0)
        , (new.uninformed_vote == 1)
        , (new.uninformed_vote != 0)
    ) on conflict(tag_id, post_id, note_id, event_type) do update
    set
          informed_count   = informed_count + (new.informed_vote == 1)
        , informed_total   = informed_total + (new.informed_vote != 0) 
        , uninformed_count = uninformed_count + (new.uninformed_vote == 1)
        , uninformed_total = uninformed_total + (new.uninformed_vote != 0) 
    ;
end;

drop trigger if exists afterUpdateConditionalVote;
create trigger afterUpdateConditionalVote after update on ConditionalVote begin
    update ConditionalTally
    set
        informed_count     = informed_count + ((new.informed_vote == 1) - (old.informed_vote == 1))
        , informed_total   = informed_total + ((new.informed_vote != 0) - (old.informed_vote != 0))
        , uninformed_count = uninformed_count + ((new.uninformed_vote == 1) - (old.uninformed_vote == 1))
        , uninformed_total = uninformed_total + ((new.uninformed_vote != 0) - (old.uninformed_vote != 0))
    where
    tag_id = new.tag_id
    and post_id = new.post_id
    and note_id = new.note_id
    and event_type = new.event_type
    ;
end;


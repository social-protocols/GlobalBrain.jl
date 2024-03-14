create trigger afterInsertEffectEvent after insert on EffectEvent begin
    insert or replace into Effect(
          vote_event_id
        , vote_event_time
        , tag_id
        , post_id
        , note_id
        , p
        , p_count
        , p_size
        , q
        , q_count
        , q_size
    ) values (
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
    ) on conflict(tag_id, post_id, note_id) do update set
          vote_event_id   = new.vote_event_id
        , vote_event_time = new.vote_event_time
        , p               = new.p
        , p_count         = new.p_count
        , p_size          = new.p_size
        , q               = new.q
        , q_count         = new.q_count
        , q_size          = new.q_size
    ;
end;


-- Inserting into ProcessVoteEvent will "process" the event and update the
-- tallies, but only if the event hasn't been processed that is, if the
-- vote_event_id is greater than lastVoteEvent.vote_event_id

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
          ancestor.ancestor_id as ancestor_id
        , new.descendant_id    as descendant_id
        , new.separation + ancestor.separation
    from lineage ancestor 
    where ancestor.descendant_id = new.ancestor_id
    on conflict do nothing;

    -- When there is a new post, we need to record an uninformed vote for every user who has voted on the parent
    -- The triggers above don't take care of this, because they only insert/update ConditionalVote records for the
    -- current user, not *all* users who have voted on the parent.
    insert into ConditionalVote(user_id, tag_id, post_id, note_id, event_type, informed_vote, uninformed_vote) 
    select
          vote.user_id
        , vote.tag_id
        , vote.post_id
        , new.descendant_id as note_id
        , 2
        , 0
        , vote.vote
        from vote
        where vote.post_id = new.ancestor_id
        and vote.vote != 0
    ;
end;




drop trigger if exists afterInsertOnVoteEvent;
create trigger afterInsertOnVoteEvent after insert on VoteEvent begin

    -- Insert/update the vote record
    insert into Vote(
          vote_event_id
        , vote_event_time
        , user_id
        , tag_id
        , parent_id
        , post_id
        , vote
    ) values(
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


    -- Record an informed_vote for all children of this post where the user is informed of the child
    -- Insert or update conditional vote on this post given voted on (each child of this post)
    -- 1. find all children of this post that the user has voted on
    -- 2. insert or update ConditionalVote record
    insert into ConditionalVote(
          user_id
        , tag_id
        , post_id
        , note_id
        , event_type
        , uninformed_vote
        , informed_vote
    )
    select
          new.user_id
        , new.tag_id
        , new.post_id
        , VoteOnNote.post_id
        , 2 -- 2 means voted on note
        , 0 
        , new.vote
    from Vote VoteOnNote
    where
    VoteOnNote.user_id = new.user_id
    and VoteOnNote.tag_id = new.tag_id 
    and VoteOnNote.post_id in (
        select descendant_id
        from lineage
        where lineage.ancestor_id = new.post_id
    )
    and VoteOnNote.vote != 0
    on conflict(user_id, tag_id, post_id, note_id, event_type) do update set
    informed_vote = new.vote
    ;


    -- Record an informed_vote for all children of this post where the user is NOT informed of the child
    -- The uninformed_vote field
    -- of this record will contain the latest uninformed vote. 
    -- 1. Find all children of this post that the user has NOT voted on
    -- 2. Insert or update ConditionalVote record
    insert into ConditionalVote(
          user_id
        , tag_id
        , post_id
        , note_id
        , event_type
        , uninformed_vote
        , informed_vote
    )
    select
          new.user_id
        , new.tag_id
        , new.post_id
        , descendant.descendant_id as note_id
        , 2
        , new.vote
        , 0
    from Lineage descendant
    left join Vote on (
        vote.user_id = new.user_id
        and vote.tag_id = new.tag_id
        and vote.post_id = descendant.descendant_id
        and vote.vote != 0
    )
    where
    descendant.ancestor_id = new.post_id
    and Vote.user_id is null
    on conflict(user_id, tag_id, post_id, note_id, event_type) do update set
    uninformed_vote = new.vote
    ;

    -- insert or update informed vote on parent of post that was voted on, given voted on this note
    -- 1. get parent of post that was voted on
    -- 2. insert or update record by joining to current vote
    insert into ConditionalVote(
          user_id
        , tag_id
        , post_id
        , note_id
        , event_type
        , uninformed_vote
        , informed_vote
    )
    select
          user_id
        , tag_id
        , AncestorVote.post_id -- the parent of the new.post_id
        , new.post_id -- the note that was voted on
        , 2 
        , 0 
        , ifnull(AncestorVote.vote,0)
    from Lineage Descendant
    left join Vote AncestorVote
    where
    Descendant.descendant_id = new.post_id 
    and AncestorVote.post_id = Descendant.ancestor_id
    and AncestorVote.user_id = new.user_id
    and AncestorVote.tag_id = new.tag_id 

    -- only do this if the vote is not being cleared
    and new.vote != 0
    on conflict(user_id, tag_id, post_id, note_id, event_type) do update set
    -- get the parent vote again. In this onConflict clause, post_id will be the parent because that's the record we tried to insert
    informed_vote = excluded.informed_vote
    ;


    -- when the vote on the note is cleared, clear the informed_vote, and set the uninformed_vote to the previous value of the informed_vote
    update ConditionalVote 
    set 
          uninformed_vote = informed_vote
        , informed_vote = 0
    where new.vote = 0
    and user_id = new.user_id
    and tag_id = new.tag_id
    and note_id = new.post_id
    and event_type = 2
    ;


    -- -- Do the same update for event_type 1 -- look for users who have not been shown note.
    -- insert into ConditionalVote(user_id, tag_id, post_id, note_id, event_type, uninformed_vote, informed_vote) 
    -- select
    -- 	new.user_id,
    -- 	new.tag_id,
    -- 	new.post_id, 
    -- 	note.id as note_id,
    -- 	1,
    -- 	new.vote,
    -- 	0
    -- from
    -- 	Post note 
    -- 	left join ConditionalVote on (
    -- 		ConditionalVote.user_id = new.user_id
    -- 		and ConditionalVote.tag_id = new.tag_id
    -- 		and ConditionalVote.post_id = new.post_id
    -- 		and ConditionalVote.note_id = note.id
    -- 		and ConditionalVote.event_type = 1
    -- 		and ConditionalVote.informed_vote != 0
    -- 	)
    -- 	where
    -- 		note.parent_id = new.post_id     -- all notes under the post that was voted on
    -- 		and note.id != ifnull(new.note_id,0)
    -- 		and ConditionalVote.user_id is null  -- that haven't been shown to this user
    -- on conflict(user_id, tag_id, post_id, note_id, event_type) do update set
    -- 	uninformed_vote = new.vote
    -- ;


    -- insert into ConditionalVote(user_id, tag_id, post_id, note_id, event_type, uninformed_vote, informed_vote) 
    -- select 		
    -- 	new.user_id,
    -- 	new.tag_id,
    -- 	new.post_id,
    -- 	new.note_id,
    -- 	1, -- 1 means "shown note"
    -- 	0,
    -- 	new.vote
    -- where new.note_id is not null
    -- on conflict(user_id, tag_id, post_id, note_id, event_type) do update set
    -- 	informed_vote = new.vote
    -- ;


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
          total                = total + (new.vote != 0) - (old.vote != 0)
        , count                = count + (new.vote == 1) - (old.vote == 1)
        , latest_vote_event_id = new.vote_event_id
    where tag_id = new.tag_id
    and post_id = new.post_id
    ;
end;

drop trigger if exists afterInsertConditional;
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
    values(
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
        informed_count   = informed_count + ((new.informed_vote == 1) - (old.informed_vote == 1)),
        informed_total   = informed_total + ((new.informed_vote != 0) - (old.informed_vote != 0)),
        uninformed_count = uninformed_count + ((new.uninformed_vote == 1) - (old.uninformed_vote == 1)),
        uninformed_total = uninformed_total + ((new.uninformed_vote != 0) - (old.uninformed_vote != 0))
    where
    tag_id = new.tag_id
    and post_id = new.post_id
    and note_id = new.note_id
    and event_type = new.event_type
    ;
end;

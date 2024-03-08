
create trigger after insert on ScoreEvent begin
    insert or replace into Score(
        voteEventId,
        voteEventTime,
        tagId,
        parentId,
        postId,
        topNoteId,
        parentP,
        parentQ,
        p,
        q,
        overallProb,
        parentPSampleSize,
        parentQSampleSize,
        -- informedCount,
        pSampleSize,
        qSampleSize,
        -- uninformedCount,
        -- overallCount,
        -- overallSampleSize,
        count,
        sampleSize,
        score
    ) values (
        new.voteEventId,
        new.voteEventTime,
        new.tagId,
        new.parentId,
        new.postId,
        new.topNoteId,
        new.parentP,
        new.parentQ,
        new.p,
        new.q,
        new.overallProb,
        new.parentPSampleSize,
        new.parentQSampleSize,
        new.pSampleSize,
        new.qSampleSize,
        -- new.informedCount,
        -- new.uninformedCount,
        -- new.overallCount,
        -- new.overallSampleSize,
        new.count,
        new.sampleSize,
        new.score
    ) on conflict(tagId, postId) do update set
        voteEventId = new.voteEventId,
        voteEventTime = new.voteEventTime,
        topNoteId = new.topNoteId,
        parentP = new.parentP,
        parentQ = new.parentQ,
        p = new.p,
        q = new.q,
        overallProb = new.overallProb,
        parentPSampleSize = new.parentPSampleSize,
        parentQSampleSize = new.parentQSampleSize,
        pSampleSize = new.pSampleSize,
        qSampleSize = new.qSampleSize,
        -- informedCount = new.informedCount,
        -- uninformedCount = new.uninformedCount,
        -- overallCount = new.overallCount,
        -- overallSampleSize = new.overallSampleSize,
        count = new.count,
        sampleSize = new.sampleSize,
        score = new.score
    ;
end;


-- Inserting into ProcessVoteEvent will "process" the event and update the tallies, but only if the event hasn't been processed
-- that is, if the voteEventId is greater than lastVoteEvent.voteEventId

drop trigger if exists afterInsertOnInsertVoteEventImport;
create trigger afterInsertOnInsertVoteEventImport instead of insert on VoteEventImport
begin

	insert into VoteEvent(voteEventId, userId, tagId, parentId, postId, noteId, vote, createdAt) 
	select 
		new.voteEventId,
		new.userId,
		new.tagId,
		case when new.parentId = '' then null else new.parentId end as parentId,
		new.postId,
		case when new.noteId = '' then null else new.noteId end as noteId,
		new.vote,
		new.createdAt
	where new.voteEventId > (select importedVoteEventId from lastVoteEvent)
	on conflict do nothing;

	-- We don't actually have keep vote events in this database once the triggers have updated the tallies.
	-- delete from voteEvent where voteEventId = new.voteEventId;
end;



create trigger afterInsertPost after insert on Post when new.parentId is not null begin
	insert into Lineage(ancestorId, descendantId, separation) values(new.parentId, new.id, 1) on conflict do nothing;
end;

create trigger afterInsertLineage after insert on Lineage
begin
	-- Insert a record for all ancestors of this ancestor
	insert into Lineage
		select 
			ancestor.ancestorId as ancestorId,
			new.descendantId as descendantId,
			new.separation + 1
		from lineage ancestor 
		where ancestor.descendantId = new.ancestorId
	on conflict do nothing;

end;

drop trigger if exists afterInsertOnVoteEvent;
create trigger afterInsertOnVoteEvent after insert on VoteEvent
begin
	insert into Post(parentId, id) values(new.parentId, new.postId) on conflict do nothing;


	-- Insert/update the vote record
	insert into Vote(userId, tagId, parentId, postId, vote, latestVoteEventId, createdAt, updatedAt) values (
		new.userId,
		new.tagId,
		new.parentId,
		new.postId,
		new.vote,
		new.voteEventId,
		new.createdAt,
		new.createdAt
	) on conflict(userId, tagId, postId) do update set
		vote = new.vote
		, latestVoteEventId = new.voteEventId
		, updatedAt = new.createdAt
	;



	-- Record an informedVote for all children of this post where the user is informed of the child
	-- Insert or update conditional vote on this post given voted on (each child of this post)
	-- 1. find all children of this post that the user has voted on
	-- 2. insert or update ConditionalVote record
	insert into ConditionalVote(userId, tagId, postId, noteId, eventType, uninformedVote, informedVote) 
	select
		new.userId,
		new.tagId,
		new.postId, 
		VoteOnNote.postId,
		2, -- 2 means voted on note
		0, 
		new.vote
	from Vote VoteOnNote
	where
		VoteOnNote.userId = new.userId
		and VoteOnNote.tagId = new.tagId 
		and VoteOnNote.postId in (select id from post where post.parentId = new.postId)	
		and VoteOnNote.vote != 0
	on conflict(userId, tagId, postId, noteId, eventType) do update set
		informedVote = new.vote
	;


	-- Record an informedVote for all children of this post where the user is NOT informed of the child
    -- The uninformedVote field
	-- of this record will contain the latest uninformed vote. 
	-- 1. Find all children of this post that the user has NOT voted on
	-- 2. Insert or update ConditionalVote record
	insert into ConditionalVote(userId, tagId, postId, noteId, eventType, uninformedVote, informedVote) 
	select
		new.userId,
		new.tagId,
		new.postId, 
		note.id as noteId,
		2,
		new.vote,
		0
	from Post note 
	left join Vote on (
		vote.userId = new.userId
		and vote.tagId = new.tagId
		and vote.postId = note.id
		and vote.vote != 0
	)
	where
		note.parentId = new.postId
		and Vote.userId is null

	on conflict(userId, tagId, postId, noteId, eventType) do update set
		uninformedVote = new.vote
	;

	-- insert or update informed vote on parent of post that was voted on, given voted on this note
	-- 1. get parent of post that was voted on
	-- 2. insert or update record by joining to current vote
	insert into ConditionalVote(userId, tagId, postId, noteId, eventType, uninformedVote, informedVote) 
	select
		userId,
		tagId,
		ParentVote.postId, -- the parent of the new.postId
		new.postId, -- the note that was voted on
		2, 
		0, 
		ifnull(ParentVote.vote,0)
	from Post
	left join Vote ParentVote
	where
		Post.id = new.postId 
		and ParentVote.postId = Post.parentId
		and ParentVote.userId = new.userId
		and ParentVote.tagId = new.tagId 

		-- only do this if the vote is not being cleared
		and new.vote != 0
	on conflict(userId, tagId, postId, noteId, eventType) do update set
		-- get the parent vote again. In this onConflict clause, postId will be the parent because that's the record we tried to insert
		informedVote = excluded.informedVote
	;


	-- when the vote on the note is cleared, clear the informedVote, and set the uninformedVote to the previous value of the informedVote
	update ConditionalVote 
		set 
			uninformedVote = informedVote
			, informedVote = 0
	where
		new.vote = 0
		and userId = new.userId
		and tagId = new.tagId
		and noteId = new.postId
		and eventType = 2
	;


	-- -- Do the same update for eventType 1 -- look for users who have not been shown note.
	-- insert into ConditionalVote(userId, tagId, postId, noteId, eventType, uninformedVote, informedVote) 
	-- select
	-- 	new.userId,
	-- 	new.tagId,
	-- 	new.postId, 
	-- 	note.id as noteId,
	-- 	1,
	-- 	new.vote,
	-- 	0
	-- from
	-- 	Post note 
	-- 	left join ConditionalVote on (
	-- 		ConditionalVote.userId = new.userId
	-- 		and ConditionalVote.tagId = new.tagId
	-- 		and ConditionalVote.postId = new.postId
	-- 		and ConditionalVote.noteId = note.id
	-- 		and ConditionalVote.eventType = 1
	-- 		and ConditionalVote.informedVote != 0
	-- 	)
	-- 	where
	-- 		note.parentId = new.postId     -- all notes under the post that was voted on
	-- 		and note.id != ifnull(new.noteId,0)
	-- 		and ConditionalVote.userId is null  -- that haven't been shown to this user
	-- on conflict(userId, tagId, postId, noteId, eventType) do update set
	-- 	uninformedVote = new.vote
	-- ;


	-- insert into ConditionalVote(userId, tagId, postId, noteId, eventType, uninformedVote, informedVote) 
	-- select 		
	-- 	new.userId,
	-- 	new.tagId,
	-- 	new.postId,
	-- 	new.noteId,
	-- 	1, -- 1 means "shown note"
	-- 	0,
	-- 	new.vote
	-- where new.noteId is not null
	-- on conflict(userId, tagId, postId, noteId, eventType) do update set
	-- 	informedVote = new.vote
	-- ;



	insert into lastVoteEvent(type, importedVoteEventId) values (1, new.voteEventId) on conflict do update set importedVoteEventId = new.voteEventId;

end;

drop trigger if exists afterInsertVote;
create trigger afterInsertVote after insert on Vote begin

	-- update ConditionalVote set informedVote = new.vote where userId = new.userId and tagId = new.tagId and postId = new.postId;

	insert into Tally(tagId, parentId, postId, latestVoteEventId, count, total) values (
		new.tagId,
		new.parentId,
		new.postId,
		new.latestVoteEventId,
		(new.vote == 1),
		new.vote != 0
	) on conflict(tagId, postId) do update 
		set 
			total = total + (new.vote != 0),
			count = count + (new.vote == 1),
			latestVoteEventId = new.latestVoteEventId
	;
end;

drop trigger if exists afterUpdateVote;
create trigger afterUpdateVote after update on Vote begin

	-- update ConditionalVote set informedVote = new.vote where userId = new.userId and tagId = new.tagId and postId = new.postId ;

	update Tally
		set 
			total = total + (new.vote != 0) - (old.vote != 0),
			count = count + (new.vote == 1) - (old.vote == 1),
			latestVoteEventId = new.latestVoteEventId
	where
		tagId = new.tagId
		and postId = new.postId
	;
end;

drop trigger if exists afterInsertConditional;
create trigger afterInsertConditionalVote after insert on ConditionalVote begin

	insert into ConditionalTally(tagId, postId, noteId, eventType, informedCount, informedTotal, uninformedCount, uninformedTotal) values (
		new.tagId,
		new.postId,
		new.noteId,
		new.eventType,
		(new.informedVote == 1),
		(new.informedVote != 0),
		(new.uninformedVote == 1),
		(new.uninformedVote != 0)
	) on conflict(tagId, postId, noteId, eventType) do update
		set
			informedCount = informedCount + (new.informedVote == 1),
			informedTotal = informedTotal + (new.informedVote != 0) ,
			uninformedCount = uninformedCount + (new.uninformedVote == 1),
			uninformedTotal = uninformedTotal + (new.uninformedVote != 0) 
	;

end;

drop trigger if exists afterUpdateConditionalVote;
create trigger afterUpdateConditionalVote after update on ConditionalVote begin
	update ConditionalTally
		set
			informedCount = informedCount + ((new.informedVote == 1) - (old.informedVote == 1)),
			informedTotal = informedTotal + ((new.informedVote != 0) - (old.informedVote != 0)),
			uninformedCount = uninformedCount + ((new.uninformedVote == 1) - (old.uninformedVote == 1)),
			uninformedTotal = uninformedTotal + ((new.uninformedVote != 0) - (old.uninformedVote != 0))
	where
		tagId = new.tagId
		and postId = new.postId
		and noteId = new.noteId
		and eventType = new.eventType
	;
end;


drop trigger if exists afterInsertOnPost;
create trigger afterInsertOnPost after insert on Post begin

	-- When there is a new note, we need to record an uninformed vote for every user who has voted on the parent
	-- The triggers above don't take care of this, because they only insert/update ConditionalVote records for the
	-- current user, not *all* users who have voted on the parent.
	insert into ConditionalVote(userId, tagId, postId, noteId, eventType, informedVote, uninformedVote) 
	select
		vote.userId,
		vote.tagId,
		vote.postId, 
		new.id as noteId,
		2,
		0,
		vote.vote
	from
		vote
		where vote.postId = new.parentId		
	;

end;


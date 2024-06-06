-- Use the queries below to debug the tallies logic. Update the values of
-- Params to include the post, user, and user_id you want to focus on, or
-- null for all. The query will then show you the corresponding values of the
-- tables used to calculate tallies, from granular to high level. For
-- example, if you choose post_id=1, comment_id=2, user_id=null, it will show
-- you

-- 1. VoteEvent: All votes events for all users for post_id=1 or post_id=2 2.
-- 
-- 2. Vote: The latest vote for all users for post_id = 1 3. InformedVote: The
-- 
-- 3. InformedVote: Latest informed vote for users who voted on post_id=1 and were informed of comment_id=2. Note: 
--	  - the user may have cleared their vote on the post (the value of the vote will be zero). 
--    - the user may have cleared their vote on the comment (the value of informed column may be 0). 4. PreinformedVote 
--
-- 4. PreinformedVote: Latest pre-informed vote for users who voted on post_id=1 before comment_id was posted, and then later changed their vote.
--
-- 5. InformedTally: The tally of informed votes for post_id=1 and comment_id=2
--
-- 6. PreinformedTally: The tally of pre-informed votes for post_id=1 and comment_id=2
--
-- 7. ConditionalTally: The final informed and uninformed tallies for post_id=1 and comment_id=2


drop table if exists Params;
create temporary table if not exists Params(
	post_id	integer,
	comment_id id,
	user_id	string,
	rownum int default 0,
	primary key (rownum)
);

-- insert or replace into Params(post_id, comment_id, user_id) values (16, 17, null);
-- insert or replace into Params(user_id) values (null);

insert or replace into Params(post_id, comment_id, user_id) values (1, 3, null);
-- insert or replace into Params(post_id, comment_id, user_id) values (108, 359, null);
-- insert or replace into Params(post_id, comment_id, user_id) values (294, 359, null);
-- insert or replace into Params(post_id, comment_id, user_id) values (294, 294, null);

-- insert or replace into Params(post_id, comment_id, user_id) values (1, 2, null);


-- insert or replace into Params(post_id) values (359);



select
	'VoteEvent' as table_name
	, t.*
from Params
left join VoteEvent t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.user_id=Params.user_id, true);

select
	'Vote' as table_name
	, t.*
from Params
left join Vote t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.user_id=Params.user_id, true);
;

select
	'InformedVote' as table_name
	, t.*
from Params
left join InformedVote t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
	and ifnull(t.user_id=Params.user_id, true);

select
	'InformedVoteView' as table_name
	, t.*
from Params
left join InformedVoteView t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
	and ifnull(t.user_id=Params.user_id, true);

select
	'InformedVoteView Grouped' as table_name
	, t.user_id
	, t.post_id
	, t.comment_id
	, vote
	, max(informed)
	, informed_by_comment_id
from Params
left join InformedVoteView t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
	and ifnull(t.user_id=Params.user_id, true)
group by 1,2,3,4
;

select
	'DirectlyInformedVote' as table_name
	, t.*
from Params
left join DirectlyInformedVote t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
	and ifnull(t.user_id=Params.user_id, true);

select
	'IndirectlyInformedVote' as table_name
	, t.*
from Params
left join IndirectlyInformedVote t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
	and ifnull(t.user_id=Params.user_id, true);



select
	'PreinformedVote' as table_name
	, t.*
from Params
left join PreinformedVote t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
	and ifnull(t.user_id=Params.user_id, true);

select
	'InformedTally' as table_name
	, t.*
from Params
left join InformedTally t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
;

select
	'PreinformedTally' as table_name
	, t.*
from Params
left join PreinformedTally t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
;

select
	'Tally' as table_name
	, t.*
from Params
left join Tally t on
	ifnull(t.post_id = Params.post_id,true)
;


select
	'ConditionalTally' as table_name
	, t.*
from Params
left join ConditionalTally t on
	ifnull(t.post_id = Params.post_id,true)
	and ifnull(t.comment_id=Params.comment_id, true)
;


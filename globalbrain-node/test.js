const bindingPath = require.resolve(`./build/Release/binding`);
const global_brain = require(bindingPath);


// global_brain.init_julia(0, "");


const test_db_path = process.argv[2] || 'test.db'
console.log("Using test db ", test_db_path)

const fs = require('fs');
if (fs.existsSync(test_db_path)) {
	fs.unlinkSync(test_db_path);
}

const test_vote_event = `{"user_id":"100","tag_id":1,"parent_id":null,"post_id":1,"note_id":null,"vote":1,"vote_event_time":1708772663570,"vote_event_id":1}`
console.log(global_brain.processVoteEventJsonC(test_db_path, test_vote_event));

const test_vote_event2 = `{"user_id":"101","tag_id":1,"parent_id":1,"post_id":2,"note_id":null,"vote":1,"vote_event_time":1708772663573,"vote_event_id":2}`
console.log(global_brain.processVoteEventJsonC(test_db_path, test_vote_event2));

const test_vote_event3 = `{"user_id":"101","tag_id":1,"parent_id":null,"post_id":1,"note_id":2,"vote":-1,"vote_event_time":1708772663575,"vote_event_id":3}`
console.log(global_brain.processVoteEventJsonC(test_db_path, test_vote_event3));

if (fs.existsSync(test_db_path)) {
       fs.unlinkSync(test_db_path);
}

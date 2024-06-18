const bindingPath = require.resolve(`./build/Release/binding`);
const addon = require(bindingPath);

function process_vote_event_json(databasePath, voteEvent) {
  // Directly call and return the result from the native function.
  // No try-catch block is necessary unless you want to handle exceptions from the native code in a specific way.
  return addon.processVoteEventJsonC(databasePath, voteEvent);
}

function process_post_creation_event_json(databasePath, postCreationEvent) {
  // Directly call and return the result from the native function.
  // No try-catch block is necessary unless you want to handle exceptions from the native code in a specific way.
  addon.processPostCreationEventJsonC(databasePath, postCreationEvent);
}

module.exports = {
  process_vote_event_json,
  process_post_creation_event_json,
};

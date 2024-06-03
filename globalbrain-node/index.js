const bindingPath = require.resolve(`./build/Release/binding`);
const addon = require(bindingPath);

function process_vote_event_json(databasePath, voteEvent) {
  // Directly call and return the result from the native function.
  // No try-catch block is necessary unless you want to handle exceptions from the native code in a specific way.
  return addon.processVoteEventJsonC(databasePath, voteEvent);
}

module.exports = {
  process_vote_event_json,
};

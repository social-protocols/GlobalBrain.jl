const addon = require('./build/Release/addon.node');

/**
 * Calls the native `processVoteEventJsonC` function.
 * @param {string} databasePath - The path to the database.
 * @param {string} voteEvent - The vote event in JSON format.
 * @returns {string} - The result string from the native function.
 */
function processVoteEventJsonC(databasePath, voteEvent) {
  // Directly call and return the result from the native function.
  // No try-catch block is necessary unless you want to handle exceptions from the native code in a specific way.
  return addon.processVoteEventJsonC(databasePath, voteEvent);
}

module.exports = {
  processVoteEventJsonC,
};

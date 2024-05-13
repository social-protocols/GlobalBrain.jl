#include "./globalbrain-compiled/include/globalbrain.h"
#include "./globalbrain-compiled/include/julia_init.h"
#include <cstring>
#include <node_api.h>

void Cleanup(void *data);

napi_value ProcessVoteEventJsonCWrapper(napi_env env, napi_callback_info info) {
  size_t argc = 3;
  napi_value args[3];
  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

  // Assuming the parameters are passed as strings from Node.js
  size_t str_len;
  char *database_path, *voteEvent, *resultBuffer;
  size_t bufferSize = 1024; // Example buffer size, adjust as needed

  // Extract strings from arguments
  napi_get_value_string_utf8(env, args[0], nullptr, 0, &str_len);
  database_path = new char[str_len + 1];
  napi_get_value_string_utf8(env, args[0], database_path, str_len + 1,
                             &str_len);

  napi_get_value_string_utf8(env, args[1], nullptr, 0, &str_len);
  voteEvent = new char[str_len + 1];
  napi_get_value_string_utf8(env, args[1], voteEvent, str_len + 1, &str_len);

  resultBuffer = new char[bufferSize];
  memset(resultBuffer, 0, bufferSize);

  // Call the C function
  process_vote_event_json_c(database_path, voteEvent, resultBuffer, bufferSize);

  // Convert result to a Node.js string
  napi_value result;
  napi_create_string_utf8(env, resultBuffer, NAPI_AUTO_LENGTH, &result);

  // Cleanup
  delete[] database_path;
  delete[] voteEvent;
  delete[] resultBuffer;

  return result;
}

napi_value Init(napi_env env, napi_value exports) {
  // Initialize Julia before anything else
  // Note: You might need to adjust arguments based on your application's needs
  int argc = 1;
  char *argv[] = {"julia_init", NULL};
  init_julia(argc, argv);

  // Register your function as before
  napi_value fn;
  napi_create_function(env, nullptr, 0, ProcessVoteEventJsonCWrapper, nullptr,
                       &fn);
  napi_set_named_property(env, exports, "processVoteEventJsonC", fn);

  // Register cleanup hook to shutdown Julia when the module is unloaded
  napi_add_env_cleanup_hook(env, Cleanup, nullptr);

  return exports;
}

void Cleanup(void *data) {
  // Shutdown Julia
  shutdown_julia(0);
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)

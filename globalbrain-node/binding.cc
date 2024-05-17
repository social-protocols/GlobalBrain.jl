#include "./julia/build/include/globalbrain.h"

#include <cstring>
#include <node_api.h>
#include <cstdlib> // Include this for `free`

void Cleanup(void *data);

napi_value ProcessVoteEventJsonCWrapper(napi_env env, napi_callback_info info) {
  size_t argc = 3;
  napi_value args[3];
  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

  size_t str_len;
  char *database_path = nullptr, *voteEvent = nullptr, *resultBuffer = nullptr;
  size_t bufferSize = 2048;
  napi_value result;

  napi_get_value_string_utf8(env, args[0], nullptr, 0, &str_len);
  database_path = new char[str_len + 1];
  napi_get_value_string_utf8(env, args[0], database_path, str_len + 1, &str_len);

  napi_get_value_string_utf8(env, args[1], nullptr, 0, &str_len);
  voteEvent = new char[str_len + 1];
  napi_get_value_string_utf8(env, args[1], voteEvent, str_len + 1, &str_len);

  resultBuffer = new char[bufferSize];
  memset(resultBuffer, 0, bufferSize);

  process_vote_event_json_c(database_path, voteEvent, resultBuffer, bufferSize);

  napi_create_string_utf8(env, resultBuffer, NAPI_AUTO_LENGTH, &result);

  delete[] database_path;
  delete[] voteEvent;
  delete[] resultBuffer;

  return result;
}

napi_value Init(napi_env env, napi_value exports) {
  int argc = 1;
  char *argv[] = {strdup("julia_init"), NULL};
  init_julia(argc, argv);
  free(argv[0]);

  napi_value fn;
  napi_create_function(env, nullptr, 0, ProcessVoteEventJsonCWrapper, nullptr, &fn);
  napi_set_named_property(env, exports, "processVoteEventJsonC", fn);

  napi_add_env_cleanup_hook(env, Cleanup, nullptr);

  return exports;
}

void Cleanup(void *data) {
  shutdown_julia(0);
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)

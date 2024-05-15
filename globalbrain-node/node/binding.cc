#include <julia.h>
#include <napi.h>

#include <algorithm>

#include "./extra.h"
#include "./init.h"

// `Init` and `NODE_API_MODULE` comments are from
// https://github.com/nodejs/node-addon-api/blob/master/doc/node-gyp.md.

using namespace Napi;

void rethrow_julia_exception(Env env) {
  if (jl_exception_occurred()) {
    jl_function_t *showerror = jl_get_function(jl_base_module, "showerror");
    jl_function_t *sprint = jl_get_function(jl_base_module, "sprint");
    jl_value_t *err = jl_call2(sprint, showerror, jl_exception_occurred());
    Napi::Error::New(env, jl_string_data(err));

  }
}

Value process_vote_event_json(const CallbackInfo &info) {
  Env env = info.Env();

  if (info.Length() != 2) {
    Napi::TypeError::New(env, "process_vote_event_json(database_path: String, vote_event: String)");
  }

  // (1) Extract JS arguments
  String database_path = info[0].As<String>();
  String vote_event = info[1].As<String>();

  // (2) Wrap in Julia types
  jl_value_t *jl_database_path = jl_cstr_to_string(database_path.Utf8Value().c_str());
  jl_value_t *jl_vote_event = jl_cstr_to_string(vote_event.Utf8Value().c_str());
  
  // (3) Load Julia module
  jl_module_t *jl_globalbrain = jl_require(jl_main_module, "GlobalBrain");
  rethrow_julia_exception(env);
  jl_function_t *jl_globalbrain_process_vote_event_json =
      jl_get_function(jl_globalbrain, "process_vote_event_json");

  // (4) Call Julia function
  jl_value_t *jl_result =
      jl_call2(jl_globalbrain_process_vote_event_json, jl_database_path, jl_vote_event);
  rethrow_julia_exception(env);

  jl_value_t *jl_score_events = jl_get_field(jl_result, "scoreEvents");

  // now copy score_events, which is a Julia string, to a node string
  String score_events = String::New(env, jl_string_data(jl_score_events));

  Object obj = Object::New(env);
  obj.Set("score_events", score_events);
  return obj;
}

/**
 * This code is our entry-point. We receive two arguments here, the first is the
 * environment that represent an independent instance of the JavaScript runtime,
 * the second is exports, the same as module.exports in a .js file.
 * You can either add properties to the exports object passed in or create your
 * own exports object. In either case you must return the object to be used as
 * the exports for the module when you return from the Init function.
 */
Object Init(Env env, Object exports) {
  init_julia();

  // TODO: exit_julia()
  // Not implemented (yet), see
  // https://github.com/nodejs/node-addon-api/pull/397.

  exports.Set(String::New(env, "process_vote_event_json"), Function::New(env, process_vote_event_json));

  return exports;
}

/**
 * This code defines the entry-point for the Node addon, it tells Node where to
 * go once the library has been loaded into active memory. The first argument
 * must match the "target" in our *binding.gyp*. Using NODE_GYP_MODULE_NAME
 * ensures that the argument will be correct, as long as the module is built
 * with node-gyp (which is the usual way of building modules). The second
 * argument points to the function to invoke. The function must not be
 * namespaced.
 */
NODE_API_MODULE(NODE_GYP_MODULE_NAME, Init)






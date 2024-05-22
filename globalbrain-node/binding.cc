#include "./julia/build/include/globalbrain.h"

#include <cstring>
#include <node.h>
#include <cstdlib> // Include this for `free`
#include <v8.h>

void Cleanup(void *data);


using namespace v8;


void ProcessVoteEventJsonCWrapper(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate();
    HandleScope scope(isolate);

    // Check the number of arguments passed
    if (args.Length() < 2) {
        isolate->ThrowException(Exception::TypeError(String::NewFromUtf8(isolate, "Wrong number of arguments").ToLocalChecked()));
        return;
    }

    // Check the argument types
    if (!args[0]->IsString() || !args[1]->IsString()) {
        isolate->ThrowException(Exception::TypeError(String::NewFromUtf8(isolate, "Wrong arguments").ToLocalChecked()));
        return;
    }

    // Convert the arguments to C strings
    String::Utf8Value database_path(isolate, args[0]);
    String::Utf8Value voteEvent(isolate, args[1]);

    // Call the dummy process_vote_event_json_c function
    char* resultString = process_vote_event_json_c(*database_path, *voteEvent);

    // Convert resultString into a V8 string and return it. The v8 string is now owned by the
    // Javascript code and should be deallocated when it is no longer needed.
    Local<String> result = String::NewFromUtf8(isolate, resultString).ToLocalChecked();

    // We are responsible for deallocating this string, which was malloc'd in process_vote_event_json_c
    delete[] resultString;

    args.GetReturnValue().Set(result);
}

void Cleanup(void *data) {
  shutdown_julia(0);
}

void Init(Local<Object> exports, Local<Value> module, void* priv) {
    Isolate* isolate = exports->GetIsolate();
    NODE_SET_METHOD(exports, "processVoteEventJsonC", ProcessVoteEventJsonCWrapper);

    int argc = 1;
    char *argv[] = {strdup("julia_init"), NULL};
    init_julia(argc, argv);
    free(argv[0]);

    // Register cleanup hook
    node::AddEnvironmentCleanupHook(isolate, Cleanup, nullptr);
}

NODE_MODULE(NODE_GYP_MODULE_NAME, Init)


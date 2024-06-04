#include <stdio.h>

#include "globalbrain.h"
#include "julia_init.h"
#include <string.h>

#define BUFFER_SIZE 1024

int main(int argc, char *argv[]) {

  init_julia(argc, argv);
  char *resultBuffer = process_vote_event_json_c(
      "test.db",
      "{\"user_id\":\"100\",\"parent_id\":null,\"post_id\":1,"
      "\"comment_id\":null,\"vote\":1,\"vote_event_time\":1708772663570,\"vote_"
      "event_id\":1}");
  shutdown_julia(0);

  const char *targetResult =
      "{\"vote_event_id\":1,\"vote_event_time\":1708772663570,\"score\":{"
      "\"post_id\":1,\"top_comment_id\":null,\"critical_thread_id\":null,"
      "\"o\":0.8333,\"o_count\":1,"
      "\"o_size\":1,\"p\":0.8333,\"score\":0.6141}}\n";

  if (strcmp(resultBuffer, targetResult) != 0) {
    fprintf(stderr,
            "Error: Result does not match the expected output:\nresult: "
            "%s\ntarget: %s",
            resultBuffer, targetResult);
    return 1;
  } else {
    printf("Calling julia function from C successful!");
  }

  return 0;
}

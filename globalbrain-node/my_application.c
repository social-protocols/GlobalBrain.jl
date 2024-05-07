#include <stdio.h>

#include "julia_init.h"
#include "mylib.h"
#include <string.h>

// Define a buffer size
#define BUFFER_SIZE 1024

int main(int argc, char *argv[])
{
    init_julia(argc, argv);

    // Allocate a buffer in C
    char resultBuffer[BUFFER_SIZE];

    // Ensure the buffer is initialized to avoid undefined behavior
    memset(resultBuffer, 0, BUFFER_SIZE);

    int incremented = increment32(3);
    printf("Incremented value: %i\n", incremented);
    process_vote_event_json_c("test.db", "{\"user_id\":\"100\",\"tag_id\":1,\"parent_id\":null,\"post_id\":1,\"note_id\":null,\"vote\":1,\"vote_event_time\":1708772663570,\"vote_event_id\":1}", resultBuffer, BUFFER_SIZE);

    const char* targetResult = "{\"vote_event_id\":1,\"vote_event_time\":1708772663570,\"score\":{\"tag_id\":1,\"post_id\":1,\"top_note_id\":null,\"o\":0.9129,\"o_count\":1,\"o_size\":1,\"p\":0.9129,\"score\":0.7928}}\n";
    // printf("result:   %s\nexpected: %s\n", resultBuffer, targetResult);
    //
    // printf("Lengths: result = %lu, expected = %lu\n", strlen(resultBuffer), strlen(targetResult));

    // Compare the obtained result with the target result
    if (strcmp(resultBuffer, targetResult) != 0) {
        // If not equal, print an error message and exit with status code 1
        fprintf(stderr, "Error: Result does not match the expected output.\n");
        return 1; // Exit with error code
    } else {
        printf("Calling julia function successful!");
    }

    shutdown_julia(0);
    return 0;
}



#include <stddef.h>

#ifdef __cplusplus
// prevent C++ name mangling
extern "C" {
#endif

void process_vote_event_json_c(const char *database_path, const char *voteEvent,
                               char *resultBuffer, size_t bufferSize);

void init_julia(int argc, char *argv[]);
void shutdown_julia(int status);

#ifdef __cplusplus
}
#endif

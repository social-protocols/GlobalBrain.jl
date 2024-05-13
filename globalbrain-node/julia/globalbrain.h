#include <stddef.h>

#ifdef __cplusplus
// prevent C++ name mangling
extern "C" {
#endif

void process_vote_event_json_c(char *database_path, char *voteEvent,
                               char *resultBuffer, size_t bufferSize);
#ifdef __cplusplus
}
#endif

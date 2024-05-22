#include <stddef.h>

#ifdef __cplusplus
// prevent C++ name mangling
extern "C" {
#endif

char* process_vote_event_json_c(const char *database_path, const char *voteEvent);

// Define these here instead of including julia_init.h (provided in the Julia
// build by PackageCompiler) to prevent name mangling
void init_julia(int argc, char *argv[]);
void shutdown_julia(int status);

#ifdef __cplusplus
}
#endif

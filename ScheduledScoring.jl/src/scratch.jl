file = open(csv_file_path, "r")
database_path = "data/vote-data.db"
vote_events_file_path = "data/vote-events-dump.csv"

csv_file_path = vote_events_file_path

            seek(file, last_size)

x = read(file, String)


type MyType


# # function watch_file(file_path::String)
# function watch_and_process_vote_events(vote_database_filename::String, vote_events_file_path::String)
#     last_modified = mtime(vote_events_file_path)

#     if !isfile(vote_database_filename)
#         error("Database file does not exist: $vote_database_filename")    
#     end

#     process_vote_events(vote_database_filename, vote_events_file_path)

#     while true
#         sleep(1)  # Check every second
#         current_modified = mtime(vote_events_file_path)
#         # println("Mtime of $vote_events_file_path: $current_modified")
#         if current_modified != last_modified         
#             last_modified = current_modified
#             println("Modified")
#             process_vote_events(vote_database_filename, vote_events_file_path)

#         end
#     end
# end

# watch_and_process_vote_events(vote_database_filename)



# # using GlobalBrain

# function process_vote_events(vote_database_filename, vote_events_file_path)

#     function process_csv_data(df::DataFrame)
#         now = Dates.now()
#         try
#             n = nrow(df)

#             println("Inserting vote events", df)
#             results = SQLite.load!(df, db, "InsertVoteEvent")

#             @info "Processed $n vote events at $now."
#         catch e
#             @error "Error processing vote event: $e. At $now."
#         end
#     end

#     db = get_score_db(vote_database_filename)

#     @info("Watching for vote events in $vote_events_file_path")
#     tail_csv(vote_events_file_path, process_csv_data)
# end

# process_vote_events(vote_database_filename, vote_events_file_path)




# todo:
#   - reply events (sepearte reply field)
#   - don't write vote events to Tables
#   - 'shown' events should be shown and not voted/replied
#   - "exists" and not shown event?
#   - json
#   - tests for aggregates. SQL alternative?
# lawn care


     

# for line in eachline(file)
#     println("LIne: $line")
# end


# function process_vote_events(vote_database_filename::String, vote_events_file_path::String)

#     commands = """.mode column
# .header on
# .import --skip 1 --csv $vote_events_file_path VoteEventImport"""

#     cmd = `echo "$commands"`
#     run(pipeline(cmd, `sqlite3 $vote_database_filename`))
#     println("Imported vote events")

#     db = get_score_db(vote_database_filename)

#     process_vote_events_stream(db)

#     close(db)
# end


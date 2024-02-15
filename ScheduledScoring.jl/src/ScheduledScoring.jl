module ScheduledScoring

using GlobalBrain
using SQLite
import Dates

function julia_main()::Cint
    @info "Starting scheduled scorer..."

    database_path = ARGS[1]
    if !isfile(database_path)
        create_score_db_tables(database_path)
    end

    while true
        now = Dates.now()
        try
            db = get_score_db(database_path)

            # TODO: optimize so that it doesn't score ALL tallies ALL the time
            detailed_tallies = get_detailed_tallies(db, nothing, nothing)
            snapshot_timestamp = Dates.now() |> Dates.datetime2unix |> (x -> trunc(Int, x))
            score_data_db_writer = get_score_data_db_writer(db, snapshot_timestamp)
            score_tree(detailed_tallies, score_data_db_writer)
            close(db)

            @info "Scored tallies at $now."
        catch e
            @error "Error scoring tallies: $e. At $now."
        end
        sleep(60)
    end

    return 0
end

end

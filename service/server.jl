using Genie, Genie.Renderer.Json, Genie.Requests
using HTTP
using JSON

include("../src/GlobalBrain.jl")
using Main.GlobalBrain

Genie.Configuration.config!(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  # log_level                       = Logging.Info,
  # log_to_file                     = false,
  # server_handle_static_files      = true,
  # path_build                      = "build",
  # format_julia_builds             = true,
  # format_html_output              = true,
  # watch                           = true
)

db = get_score_db("global-brain.db")

route("/", method = POST) do
    message = rawpayload()
    parsed_message = JSON.parse(message)
    vote_events = map(parse_vote_event, parsed_message["payload"])

    results = ""
    n = 0

    map(vote_events) do vote_event
        emit_event =
            (score_or_effect) -> begin
                e = as_event(vote_event.vote_event_id, vote_event.vote_event_time, score_or_effect)
                insert_event(db, e)
                json_data = JSON.json(e)
                results *= json_data * "\n"
                n += 1
            end
        process_vote_event(emit_event, db, vote_event)
    end

    return results
end

route("/send") do
    response = HTTP.request(
        "POST",
        "http://127.0.0.1:8000",
        [("Content-Type", "application/json")],
        """
        {
            "payload": [
                {"user_id":"100","tag_id":1,"parent_id":null,"post_id":1,"comment_id":null,"vote":1,"vote_event_time":1708772663570,"vote_event_id":1},
                {"user_id":"101","tag_id":1,"parent_id":1,"post_id":2,"comment_id":null,"vote":1,"vote_event_time":1708772663573,"vote_event_id":2},
                {"user_id":"101","tag_id":1,"parent_id":null,"post_id":1,"comment_id":2,"vote":-1,"vote_event_time":1708772663575,"vote_event_id":3},
                {"user_id":"100","tag_id":1,"parent_id":2,"post_id":3,"comment_id":null,"vote":1,"vote_event_time":1708772663576,"vote_event_id":4}
            ]
        }
        """
    )
    response.body |> String |> Json.json
end

up(async = false)


INPUT_STREAM_VOTE_EVENT_SCHEMA = Set([
    "vote_event_id",
    "user_id",
    "tag_id",
    "parent_id",
    "post_id",
    "note_id",
    "vote",
    "vote_event_time",
])


function check_schema_or_throw(input::Dict{String,Any}, required_schema::Set)::Bool
    is_valid_schema = issubset(required_schema, collect(keys(input)))
    if is_valid_schema
        return true
    else
        error("Invalid JSON for VoteEvent: $input")
    end
end


function parse_vote_event(input::Dict{String,Any})::VoteEvent
    return VoteEvent(
        vote_event_id = input["vote_event_id"],
        vote_event_time = input["vote_event_time"],
        user_id = input["user_id"],
        tag_id = input["tag_id"],
        parent_id = input["parent_id"],
        post_id = input["post_id"],
        note_id = input["note_id"],
        vote = input["vote"],
    )
end


function as_vote_event_or_throw(line::IOBuffer)::VoteEvent
    json = JSON.parse(line)
    try
        check_schema_or_throw(json, INPUT_STREAM_VOTE_EVENT_SCHEMA)
        vote_event = parse_vote_event(json)
        return vote_event
    catch e
        error(e)
    end
end

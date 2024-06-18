INPUT_STREAM_VOTE_EVENT_SCHEMA =
    Set(["vote_event_id", "user_id", "parent_id", "post_id", "vote", "vote_event_time"])
    # TODO: no more parent_id needed?

INPUT_STREAM_POST_CREATION_EVENT_SCHEMA =
    Set(["post_id", "parent_id"])

function check_schema_or_throw(input::Dict{String,Any}, required_schema::Set)::Bool
    is_valid_schema = issubset(required_schema, collect(keys(input)))
    if is_valid_schema
        return true
    else
        error("Invalid JSON for VoteEvent: $input")
    end
end


function as_vote_event_or_throw(line::IOBuffer)::VoteEvent
    json = JSON.parse(line)
    try
        check_schema_or_throw(json, INPUT_STREAM_VOTE_EVENT_SCHEMA)
        vote_event = VoteEvent(
            vote_event_id = json["vote_event_id"],
            vote_event_time = json["vote_event_time"],
            user_id = json["user_id"],
            parent_id = json["parent_id"],
            post_id = json["post_id"],
            vote = json["vote"],
        )
        return vote_event
    catch e
        error(e)
    end
end

function as_post_creation_event_or_throw(line::IOBuffer)::PostCreationEvent
    json = JSON.parse(line)
    try
        check_schema_or_throw(json, INPUT_STREAM_POST_CREATION_EVENT_SCHEMA)
        post_creation_event = PostCreationEvent(
            post_id = json["post_id"],
            parent_id = json["parent_id"],
        )
        return post_creation_event
    catch e
        error(e)
    end
end

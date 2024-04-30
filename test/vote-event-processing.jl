@testset "JSON API" begin

    ENV["DATABASE_PATH"] = joinpath(ENV["SOCIAL_PROTOCOLS_DATADIR"],"test-vote-event-processing.db")
    if isfile(ENV["DATABASE_PATH"])
        rm(ENV["DATABASE_PATH"])
    end

    test_vote_event = """{"user_id":"100","tag_id":1,"parent_id":null,"post_id":1,"note_id":null,"vote":1,"vote_event_time":1708772663570,"vote_event_id":1}"""
    result = process_vote_event_json(test_vote_event)
    @info result
    @test result.scoreEvents == """{\"vote_event_id\":1,\"vote_event_time\":1708772663570,\"score\":{\"tag_id\":1,\"post_id\":1,\"top_note_id\":null,\"o\":0.9129,\"o_count\":1,\"o_size\":1,\"p\":0.9129,\"score\":0.7928}}\n"""
end

@testset "JSON API" begin

    ENV["DATABASE_PATH"] = joinpath(ENV["SOCIAL_PROTOCOLS_DATADIR"],"test-vote-event-processing.db")
    if isfile(ENV["DATABASE_PATH"])
        rm(ENV["DATABASE_PATH"])
    end

    test_vote_event = """{"user_id":"100","parent_id":null,"post_id":1,"comment_id":null,"vote":1,"vote_event_time":1708772663570,"vote_event_id":1}"""
    result = process_vote_event_json(ENV["DATABASE_PATH"], test_vote_event)
    @info result
    @test result == """{\"vote_event_id\":1,\"vote_event_time\":1708772663570,\"score\":{"post_id\":1,\"o\":0.8333,\"o_count\":1,\"o_size\":1,\"p\":0.8333,\"score\":0.6141}}\n"""

    if isfile(ENV["DATABASE_PATH"])
        rm(ENV["DATABASE_PATH"])
    end

end

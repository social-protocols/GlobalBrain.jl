library(DBI)
library(dplyr)

simulation_db <- function() {
  dbConnect(RSQLite::SQLite(), SIM_DATABASE_PATH)
}

# table defined in: ../sql/tables.sql:1
get_simulation_choices <- function() {
  con <- simulation_db()
  simulation_choices <-
    dbGetQuery(
      con,
      "
        SELECT DISTINCT tag_id
        FROM VoteEvent
        ORDER BY tag_id
      "
    ) %>%
    data.frame() %>%
    pull()
  dbDisconnect(con)
  return(simulation_choices)
}

# table defined in: ../sql/tables.sql:102
get_score_events <- function() {
  con <- simulation_db()
  data <- dbGetQuery(con, "SELECT * FROM ScoreEvent") %>%
    data.frame() %>%
    rename(
      voteEventId = vote_event_id,
      voteEventTime = vote_event_time,
      tagId = tag_id,
      postId = post_id,
      topNoteId = top_note_id,
      o = o,
      oCount = o_count,
      oSize = o_size,
      p = p,
      score = score,
    )
  dbDisconnect(con)
  return(data)
}

# table defined in: ../sql/tables.sql:1
get_vote_events <- function() {
  con <- simulation_db()
  data <- dbGetQuery(con, "SELECT * FROM VoteEvent") %>%
    data.frame() %>%
    rename(
      voteEventId = vote_event_id,
      voteEventTime = vote_event_time,
      userId = user_id,
      tagId = tag_id,
      parentId = parent_id,
      postId = post_id,
      noteId = note_id,
      vote = vote,
    )
  dbDisconnect(con)
  return(data)
}

# table defined in: ../sql/tables.sql:72
get_effect_events <- function() {
  con <- simulation_db()
  data <- dbGetQuery(con, "SELECT * FROM EffectEvent") %>%
    data.frame() %>%
    mutate(magnitude = relative_entropy(p, q)) %>%
    rename(
      voteEventId = vote_event_id,
      voteEventTime = vote_event_time,
      tagId = tag_id,
      postId = post_id,
      noteId = note_id,
      p = p,
      pCount = p_count,
      pSize = p_size,
      q = q,
      qCount = q_count,
      qSize = q_size,
    )
  dbDisconnect(con)
  return(data)
}

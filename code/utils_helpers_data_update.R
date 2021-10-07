#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This is a utility script that holds custom functions that help update data
#
# By: mike gaunt, michael.gaunt@wsp.com
#
# README: script defines custom functions
#-------- script defines custom functions
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#SECTION========================================================================

#description
#description
#description
function_name <- function(input_1, input_2) {
}


#this function updates daily batter data
#it does not load the data
update_daily_batter = function(){

  tmp = readRDS(here("data/daily_batter_data.RDS"))

  last_date = tmp$as_of %>%
    max()

  # tmp = tmp %>%
  #   filter(as_of %nin% seq(last_date-7, last_date, 1))

  if (last_date < Sys.time()) {
    print("update_daily_batter::> Data requires updating!")

    start_date = "2021-04-01"

    date_list = seq(from = last_date+1, to = Sys.Date(), by = 1) %>%
      map(~.x %>%  as.character)

    daily_batter_data = date_list %>%
      future_map(~daily_batter_bref(start_date, .x ) %>%
            data.table()) %>%
        list(., date_list) %>%
        pmap(~.x %>%
               .[,`:=`(as_of = .y %>%
                         as.Date())] %>%
               woba_plus() %>%
               data.table()) %>%
        rbindlist() %>%
        .[,`:=`(date_acquired = Sys.Date())] %>%
      .[order(Team, Name, PA)]

    daily_batter_data %>%
      bind_rows(tmp, .) %>%
      .[, .SD[1], by = .(Name, G)] %>%
      unique() %>%
      saveRDS(., here::here("data/daily_batter_data.RDS"))

    print("Data updated and saved!")
  } else {
    print("update_daily_batter::> Data does not need to be updated!")
  }
}

#scraping and updating team stats===============================================
##this function updates daily batter data
#it does not load the data
get_team_stats = function(){
  0:6 %>%
    future_map(~str_glue("https://www.fangraphs.com/leaders.aspx?pos=all&stats=bat&lg=all&qual=0&type={.x}&season=2021&month=0&season1=2021&ind=0&team=0,ts&rost=0&age=0&filter=&players=0&startdate=2021-01-01&enddate=2021-12-31") %>%
                 xml2::read_html(.) %>%
                 rvest::html_nodes("table") %>%
                 .[17]  %>%
                 rvest::html_table() %>%
                 .[[1]] %>%
                 data.table() %>%
                 janitor::row_to_names(2) %>%
                 .[-1,-1]
    ) %>%
    reduce(merge, by = "Team") %>%
    .[,`:=`(as_of = Sys.Date())]
}

update_team_data = function(){

  tmp = readRDS(here("data/team_stats.rds"))

  last_date = tmp$as_of %>%
    max()

  if (last_date < Sys.Date()){
    print("update_team_data::> Data requires updating!")

    bind_rows(tmp, get_team_stats()) %>%
      unique() %>%
      saveRDS(., here("data/team_stats.rds"))

    print("Data updated and saved!")
  } else {
    print("update_team_data::> Data does not need to be updated!")
  }
}

#queries and gets park and basic weather data===================================
##this function updates daily batter data
update_game_data = function(){

  tmp = readRDS(here("data/complete_game_data.rds"))

  last_date = tmp$as_of %>%
    max()

  if (last_date < Sys.Date()){
    print("update_game_data::> Data requires updating!")
    date_list = seq(from = last_date+1, to = Sys.Date(), by = 1) %>%
      map(~.x %>%  as.character)

    safe_get_game_pks_mlb = safely(get_game_pks_mlb)

    games_overview = date_list %>%
      map(~safe_get_game_pks_mlb(.x) %>%
            .["result"] %>%
            .[[1]]) %>%
      compact() %>%
      data.table::rbindlist(fill = T) %>%
      .[,.(game_pk, venue.id, season, gameDate, officialDate, gameNumber, dayNight, seriesGameNumber,
           teams.away.team.name, teams.away.score, teams.away.leagueRecord.wins, teams.away.leagueRecord.losses, teams.away.leagueRecord.pct, teams.away.team.id,
           teams.home.team.name, teams.home.score, teams.home.leagueRecord.wins, teams.home.leagueRecord.losses, teams.home.leagueRecord.pct, teams.home.team.id)]

    safe_get_game_info_mlb = safely(get_game_info_mlb)

    games_overview_with_weather = games_overview$game_pk %>%
      future_map(~safe_get_game_info_mlb(.x) %>%
            .["result"] %>%
            .[[1]]) %>%
      compact() %>%
      data.table::rbindlist() %>%
      .[, .(game_pk, temperature, other_weather, wind)] %>%
      data.table::merge.data.table(games_overview, ., by = "game_pk", all.x = T)  %>%
      .[,`:=`(as_of = Sys.Date())]

    bind_rows(
      games_overview_with_weather,
      tmp
    ) %>%
    saveRDS(., here::here("data/complete_game_data.rds"))

    print("Data updated and saved!")
  } else {
    print("update_game_data::> Data does not need to be updated!")
  }
}


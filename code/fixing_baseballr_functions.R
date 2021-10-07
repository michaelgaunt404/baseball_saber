
# yolo = getwd()
# cat("Current WD is ", getwd())
library(tidyverse)
library(baseballr)
milb_batter_game_logs_fg(playerid = "14344", 2020)
https://www.fangraphs.com/players/matt-olson/14344/stats?position=1B
playerid = "sa917940"
year = 2018
playerid = "sa917940", 2018
url_basic <- paste0("http://www.fangraphs.com/statsd-legacy.aspx?playerid=",
                    playerid,
                    "&season=",
                    year,
                    "&position=PB","&type=-1")

url_adv <- paste0("http://www.fangraphs.com/statsd-legacy.aspx?playerid=",
                  playerid,
                  "&season=",
                  year,
                  "&position=PB","&type=-2")
playerid_lookup("Olson", "Matt")



###looking at more==============================================================
baseballr::pitcher_boxscore()

baseballr::scrape_statcast_savant(start_date = "2016-04-06",
                                  end_date = "2016-04-15", playerid = 621043)

baseballr::scrape_statcast_savant_pitcher(start_date = "2016-04-06",
                                          end_date = "2016-04-15", pitcherid = 592789)

#different then my scaping function
#both of these give what a players performance was for a particular game
baseballr::pitcher_game_logs_fg(playerid = 19755, year = 2021)
baseballr::batter_game_logs_fg(playerid = 10059, year = 2021)




###scrape_player_data===========================================================

big_batter_data_names = readRDS(here("data/daily_batter_data.RDS")) %>%
  data.table()


big_batter_data_names = big_batter_data_names %>%
  .[, .SD[1], by = .(Name, G)] %>%
  # filter(Team == "Oakland") %>%
  select(Name) %>%
  unique() %>%
  tidyr::separate(col = "Name", sep = " ", into = c("first", "last"), extra = "merge")


big_batter_data_names = list(big_batter_data_names$first, big_batter_data_names$last) %>%
  future_pmap(~safe_playerid_lookup(.y, .x)%>%
                .["result"] %>%
                .[[1]]) %>%
  compact() %>%
  data.table::rbindlist()


big_batter_data_names %>%
  filter(!is.na(fangraphs_id))

tmp = readRDS(here("data/daily_batter_data.RDS")) %>%
  data.table()
tictoc::tic()
c(1:25) %>%
  map(~{
    print(.x)
    Sys.sleep(5)
  })

tictoc::toc()





###scrape_player_data===========================================================
#TODO a lot.......
#needs a pause so that it doesn't overload the system
#-------> put in a 4 second sleep, probs overkill especially on days where they're aren't that many game
#should check and only get data for players who have played since the previous scrape
#-------> only scrapes players that have new data in daily_batter_data.RDS
#still not getting all the players which means not every player's IDs have been retreived
#-------> this needs a whole other scrape process
#-------> unresolved needs own script to solve
#needs to figure out a way to resolve if someone is a batter or pitcher - stats overlap and are not good
#-------> either be split or something else



#make some functions that i will need---
scrape_player_data = function(player){
  #scrapes stats given for a single day
  scrape_object = str_glue("https://www.fangraphs.com/statss-legacy.aspx?playerid={player}") %>%
    xml2::read_html(.) %>%
    rvest::html_nodes("table")

  c(14, 15, 31) %>%
    map(~ scrape_object %>%
          .[[.x]] %>%
          rvest::html_table() %>%
          data.table()) %>%
    reduce(full_join, by = c("Season", "Team")) %>%
    .[, .SD[1], by = .(Season, Team)] %>%
    .[,`:=`(date_acquired = Sys.Date(),
            player_id = player)]
}

safe_scrape_player_data = safely(scrape_player_data)
safe_playerid_lookup = safely(playerid_lookup)

#get player catalogue need for fangraphs data---
player_catalogue = readRDS("data/player_catalogue.rds") %>%
  filter(!is.na(fangraphs_id))

tmp = readRDS(here("data/daily_batter_data.RDS")) %>%
  filter(as_of == max(as_of)) %>%
  select(Name) %>%
  unique() %>%
  tidyr::separate(col = "Name", sep = " ", into = c("first", "last"), extra = "merge")

#names for players that have played since datail_batter was last updated---
#removes players that I dont already have in player catalogue
names_to_retreive = readRDS(here("data/daily_batter_data.RDS")) %>%
  filter(as_of == max(as_of)) %>%
  select(Name) %>%
  unique() %>%
  tidyr::separate(col = "Name", sep = " ", into = c("first", "last"), extra = "merge") %>%
  anti_join(., player_catalogue %>%
              arrange(first_name) %>%
              filter(str_detect(last_name, "Gos")),
            by = c("first" = "first_name", "last" = "last_name"))

#updates only if it needs to
if (nrow(names_to_retreive)>0) {
  print("Getting fangraphs ids for players.")

  big_batter_data_names = list(names_to_retreive$first, names_to_retreive$last) %>%
    future_pmap(~safe_playerid_lookup(.y, .x)%>%
                  .["result"] %>%
                  .[[1]]) %>%
    compact() %>%
    data.table::rbindlist()

  big_batter_data_names_scraped  = big_batter_data_names %>%
    filter(!is.na(fangraphs_id),
           mlb_played_first > 1990)

  print(str_glue("Was able to get {nrow(big_batter_data_names_scraped)}/{nrow(big_batter_data_names)} player fangraph ids."))

  player_catalogue = big_batter_data_names_scraped %>%
    bind_rows(player_catalogue, .) %>%
    filter(!is.na(fangraphs_id),
           mlb_played_first > 1990)


  player_catalogue %>%
    saveRDS("data/player_catalogue.rds")

  print("Player catalogue containing fangraphs IDs updated.")
} else {
  print("Player catalogue does not need to be updated. All players are present.")
}

big_batter_data_names = tmp %>%
  merge.data.table(player_catalogue, by.x = c("first", "last"), by.y = c("first_name", "last_name")) %>%
  unique()

tictoc::tic()
scraped_date = big_batter_data_names %>%
  head(5) %>%
  filter(!is.na(fangraphs_id)) %>%
  .$fangraphs_id %>%
  as.integer() %>%
  future_map(~{
    Sys.sleep(10)

    safe_scrape_player_data(.x) %>%
      .["result"] %>%
      .[[1]]

  }
  ) %>%
  rbindlist(fill = T)
tictoc::toc()

safe_scrape_player_data

scraped_date %>%
  saveRDS(here(str_glue("data/tmp_data_{Sys.Date()-1}.rds")))
scraped_date %>%
  write.csv(here(str_glue("data/tmp_data_{Sys.Date()-1}.rds")))

###end==========================================================================

###saving player data ==========================================================

big_batter_data_names

player_catalogue = readRDS("data/player_catalogue.rds") %>%
  filter(!is.na(fangraphs_id))

names_to_retreive = readRDS(here("data/daily_batter_data.RDS")) %>%
  filter(as_of == max(as_of)) %>%
  select(Name) %>%
  unique() %>%
  tidyr::separate(col = "Name", sep = " ", into = c("first", "last"), extra = "merge") %>%
  anti_join(player_catalogue %>%
              arrange(first_name),
            by = c("first" = "first_name", "last" = "last_name"))

if (nrow(big_batter_data_names)>0) {

  big_batter_data_names = list(names_to_retreive$first, names_to_retreive$last) %>%
    future_pmap(~safe_playerid_lookup(.y, .x)%>%
                  .["result"] %>%
                  .[[1]]) %>%
    compact() %>%
    data.table::rbindlist()
}


# big_batter_data_names %>%
#   saveRDS("data/player_catalogue.rds")


###end==========================================================================

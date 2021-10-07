

write_out_data = "./data/gym_scrape_data.csv"

archived = fread(write_out_data) %>%
  mutate_at(c("Timeslot", "Obtained"), as_datetime, tz = "US/Pacific")

#SECTION: Set 

#note: how to kill port 
#https://stackoverflow.com/questions/39632667/how-do-i-kill-the-process-currently-using-a-port-on-localhost-in-windows
#netstat -ano | findstr :4567
#taskkill /PID 33880 /F

#start driver
rD <- rsDriver(browser=c("chrome"), port = 4444L)
rD <- rsDriver(browser=c("firefox"))
rD <- rsDriver(browser=c("chrome"), chromever="85.0.4183.87")
# Assign the client
remDr <- rD$client

#open client
# remDr$open()

# remDr$findElements("id", "btnSub")[[1]]$clickElement()

# Navigate to website
appurl <- "https://app.rockgympro.com/b/widget/?a=offering&offering_guid=e696ff3f80fd4280bc868e6974173b11&random=5fd55a2fa2660&iframeid=&mode=p"
appurl <- "https://www.fangraphs.com/players/matt-olson/14344/stats?position=1B"
appurl = "http://www.fangraphs.com/statsd-legacy.aspx?playerid=sa917940&season=2018&position=PB&type=-1"
appurl = "https://www.fangraphs.com/statss-legacy.aspx?playerid=14344&position=1B"


https://www.fangraphs.com/statss-legacy.aspx?playerid=20126&position=OF
https://www.fangraphs.com/statss-legacy.aspx?playerid=14344&position=1B

https://www.fangraphs.com/players/matt-olson/14344/stats?position=1B

remDr$navigate(appurl)

#get list of availiable date widgets
d = remDr$findElements(using="class name", 'datepicker-available-day')

#set up loop to get open spots per day
# i = 2 #for dev 
days_to_scrape = 7
scraped = data.table()
for (i in 1:days_to_scrape){
  
  remDr$findElements(using="class name", 'datepicker-available-day')[[i]]$findChildElement("class name", "ui-state-default")$clickElement()
  
  scraped = remDr$getPageSource()[[1]] %>%  
    read_html() %>%  
    html_nodes("table") %>%  
    .[[4]] %>%  
    html_table() %>% 
    data.table() %>% 
    bind_rows(scraped, .)
  
  Sys.sleep(1)
}

archived = scraped %>% 
  mutate(X1 = str_remove(X1, "to.*") %>%  
           str_trim() %>%  
           parse_date_time(., c("aBdIp", "aBdIMp"), tz = "US/Pacific"),
         X2 = str_replace(X2, "Full", "0") %>%  
           str_remove_all("[:alpha:]") %>%  
           str_remove_all("[:punct:]") %>% 
           str_trim() %>%  
           as.numeric()) %>%  
  select(X1, X2) %>%  
  set_names(c("Timeslot", "Spaces")) %>%  
  mutate(Obtained = Sys.time() %>%  
           floor_date("hour")) %>% 
  data.table() %>% 
  bind_rows(archived, .) %>% 
  unique() 

fwrite(archived, write_out_data)

billboarder() %>%
  bb_linechart(
    data = archived,
    mapping = bbaes(Obtained, Spaces, group = Timeslot),
    show_point = F,
    type = "spline"
  ) %>%
  bb_subchart(show = TRUE, size = list(height = 30))

billboarder() %>%
  bb_barchart(
    data = archived,
    mapping = bbaes(Timeslot, 
                    Spaces, 
                    group = Timeslot %>%  
                      floor_date(unit = "day") %>%  
                      as.factor())
  ) %>%  
  bb_x_axis(tick = list(format = "%Y-%m", fit = FALSE)) %>% 
  bb_subchart(show = TRUE, size = list(height = 30))



# 
# 
# remDr$findElement(using = "xpath",
#                    '//*[contains(concat( " ", @class, " " ), concat( " ", "ui-state-default", " " ))]')$clickElement()
# 
# 
# 
# #read the html
# html = remDr$getPageSource()[[1]] %>%  
#   read_html()
# html %>%  
#   html_nodes("[class=' ui-datepicker-unselectable ui-state-disabled datepicker-unavailable-day']")
# 
# 
# scraped = html %>%  
#   html_nodes("table") %>%  
#   .[[3]] %>%  
#   html_table() %>%  
#   mutate(X1 = str_remove(X1, "to.*") %>%  
#            str_trim() %>%  
#            parse_date_time("aBdIp", tz = "US/Pacific"),
#          X2 = str_replace(X2, "Full", "0") %>%  
#            str_remove_all("[:alpha:]") %>%  
#            str_remove_all("[:punct:]") %>% 
#            str_trim() %>%  
#            as.numeric()) %>%  
#   select(X1, X2) %>%  
#   set_names(c("Timeslot", "Spaces")) %>%  
#   mutate(Obtained = Sys.time() %>%  
#           floor_date("hour")) %>% 
#   data.table()
# 
# remDr$close()
# rD$server$stop()
# rm(rD)
# gc()
# 
# scraped$Obtained %>%  with_tz()
# 
# archived %>%  
#   bind_rows(scraped) %>%  
#   unique() %>%  
#   mutate(Spaces = Spaces %>%  
#            as.integer()) %>% 
#   # mutate_at(c("Timeslot", "Obtained"), as_date) %>% 
#   ggplot() +
#   geom_point(aes(Obtained, Spaces, group = Timeslot)) 
# 
# set_theme("graph")
# data1 = archived %>%  
#   bind_rows(scraped) %>%  
#   unique() %>%  
#   mutate(Spaces = Spaces %>%  
#            as.integer())
# 
# 
# billboarder() %>% 
#   bb_linechart(
#     data = data1, 
#     mapping = bbaes(Obtained, Spaces, group = Timeslot),
#     show_point = TRUE
#     ) %>%  
#   bb_scatterplot(
#     data = data1, 
#     mapping = bbaes(Obtained, Spaces, group = Timeslot)
#   )
# 
# billboarder() %>% 
#   bb_scatterplot(
#     data = iris, 
#     mapping = bbaes(Sepal.Length, Sepal.Width, group = Species, size = Petal.Width)
#   )
# 
# prod_par_filiere[, c("annee", "prod_hydraulique", "prod_eolien", "prod_solaire")]
# equilibre_mensuel[, c("date", "consommation", "production")]
# 
# 
# 
# 
# fwrite(scraped, write_out_data, append = F)
# 
# tmp = "Sun, November 8, 2 PM"
# tmp %>%  
#   parse_date_time("aBdIp")
# 
# 
# # remDr <- rD$client
# # remDr$close()
# # rD$server$stop() 
# # rm(mybrowser)
# # gc()
# library(robotstxt)
# binman::list_versions("chromedriver")
# 
# rD <- rsDriver(verbose = FALSE,port=4444L)
# remDr <- rD$client
# remDr$close()
# rD$server$stop()
# 
# checkForServer()
# 
# 
# 
# 
# 
# 
# 
# 
# rD <- rsDriver(browser=c("chrome"), chromever="85.0.4183.87")
# 
# remDr <- rD$client
# 
# 
# 
# remDr$navigate("https://app.rockgympro.com/b/widget/?a=offering&offering_guid=6f4cca6df22d4e9dbec6ec7293006703&random=5f71fd810b576&iframeid=&mode=p")
# 
# d = remDr$findElements(using="class name", 'datepicker-available-day')
# 
# 
# i = 5
# scraped = data.table()
# for (i in 1:length(d)){
#   
#   remDr$findElements(using="class name", 'datepicker-available-day')[[i]]$findChildElement("class name", "ui-state-default")$clickElement()
#   
#   scraped = html %>%  
#     html_nodes("table") %>%  
#     .[[3]] %>%  
#     html_table() %>% 
#     data.table() %>% 
#   bind_rows(scraped, .)
#   
#   Sys.sleep(1)
# }
# 
# archived = scraped %>% 
# mutate(X1 = str_remove(X1, "to.*") %>%  
#          str_trim() %>%  
#          parse_date_time("aBdIp", tz = "US/Pacific"),
#        X2 = str_replace(X2, "Full", "0") %>%  
#          str_remove_all("[:alpha:]") %>%  
#          str_remove_all("[:punct:]") %>% 
#          str_trim() %>%  
#          as.numeric()) %>%  
#   select(X1, X2) %>%  
#   set_names(c("Timeslot", "Spaces")) %>%  
#   mutate(Obtained = Sys.time() %>%  
#            floor_date("hour")) %>% 
#   data.table() %>% 
#   bind_rows(archived, .) %>% 
#   unique() 
#   
# 
# 
# 
# 
# archived %>%  
#   bind_rows(scraped) %>%  
#   unique() %>%  
#   mutate(Spaces = Spaces %>%  
#            as.integer()) %>% 
#   # mutate_at(c("Timeslot", "Obtained"), as_date) %>% 
#   ggplot() +
#   geom_point(aes(Obtained, Spaces, group = Timeslot)) 
# 
# set_theme("graph")
# data1 = archived %>%  
#   bind_rows(scraped) %>%  
#   unique() %>%  
#   mutate(Spaces = Spaces %>%  
#            as.integer())
# 
# 
# billboarder() %>% 
#   bb_linechart(
#     data = data1, 
#     mapping = bbaes(Obtained, Spaces, group = Timeslot),
#     show_point = TRUE
#   ) %>%  
#   bb_scatterplot(
#     data = data1, 
#     mapping = bbaes(Obtained, Spaces, group = Timeslot)
#   )
# 
# 
# 
# 
# remDr$close()
# rD$server$stop()

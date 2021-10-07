#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This script sends an email.
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(gmailr)
library(tidyverse)
library(jsonlite)

gm_auth_configure(path = "./docs/secret/domorewithr.json")
use_secret_file("./docs/secret/domorewithr.json")

email_body = paste0(
  "Hello, this is an automated response from your friendly person. This message was sent out on ", 
  Sys.time(), 
  "."
)
  
# file_attach = file_directory %>%
#   filter(str_detect(name, "html")) %>%
#   tail(1) %>%
#   .[,"name"]


my_email_message = gm_mime() %>% 
  gm_to("mike.gaunt.404@gmail.com") %>% 
  gm_from("mike.gaunt.404@gmail.com") %>% 
  gm_subject(paste("hello",format(Sys.time(), '%Y%m%d'), sep = "_")) %>% 
  gm_text_body(email_body) #%>%  
  # gm_attach_file(file_attach) %>% 
  # gm_html_body(paste(readLines(file_attach), collapse = ""))
  # gm_html_body(file_attach)
  # # gm_attach_file(file_attach[2]) %>% 
  # gm_attach_file(file_attach[1])

gm_create_draft(my_email_message)
# gm_html_body(paste(readLines(file_attach), collapse = ""))

                 
gm_send_message(my_email_message)
  #sets suffix for file name
#generally best if this is 'system date/time'
# suffix = format(Sys.time(), '%Y%m%d_%H%M%S')
# 
# #section calls script to run, provides filename suffix, and location
# #for terminal usage
# 
# gmailr::gmai
# 
# ezknit(file = "yolo.rmd",
#        out_suffix = suffix,
#        out_dir = "../output",
#        fig_dir = "../myfigs")
# 
# #for internal script usage
# #needs to be different than terminal version
# # ezknit(file = "r/yolo.rmd",
# #        out_suffix = suffix,
# #        out_dir = "output",
# #        fig_dir = "myfigs")


print("R script successfully ran from terminal.")

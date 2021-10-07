#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This is code updates specific data
#
# By: mike gaunt, michael.gaunt@wsp.com
#
# README: this script can be ran alone or automatically
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#library set-up=================================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# install.packages("devtools")
library(baseballr)
library(tidyverse)
library(lubridate)
library(data.table)
library(furrr)
library(here)
plan(multisession, workers = 4)


#path set-up====================================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#project file performs this task - section is not required

#source helpers/utilities=======================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#zz_localG performs this task - section is not required
source(here("code/utils_helpers_data_update.R"))

#source helpers/utilities=======================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#zz_localG performs this task - section is not required
big_batter_data = readRDS(here("data//daily_batter_data.rds"))

#CODE BODY START================================================================

big_batter_data %>%
  ggplot() +
  geom_line(aes(G, AB, group = Name))

big_batter_data %>%
  ggplot(aes(PA, BA)) +
  geom_line(aes(group = Name)) +
  geom_smooth()

big_batter_data %>%
  ggplot(aes(PA, BA)) +
  geom_line(aes(group = Name)) +
  geom_smooth()



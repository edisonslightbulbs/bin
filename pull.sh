#!/usr/bin/env bash

# pull
#  Git pull all git repositories in working directory (depth = 1)
#
# author: Everett
# created: 2021-09-16 14:06
# Github: https://github.com/antiqueeverett/

ls | xargs -P10 -I{} git -C {} pull

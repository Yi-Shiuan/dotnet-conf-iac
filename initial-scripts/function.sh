#!/bin/bash -xe
timespan(){
  date +"%Y-%m-%d %T.%3N"
}

log(){
  echo "$(timespan) $*"
}
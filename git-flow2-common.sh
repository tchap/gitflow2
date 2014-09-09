#!/bin/bash

__bold=`tput bold`
__normal=`tput sgr0`

function flush_stdio {
  while read -e -t 1; do : ; done
}

function source_config {
  dir=$1
  # Load PROJECT_ID.
  [[ -e ${PWD}/.workflowrc ]] || {
    echo "Could not find \"${PWD}/.workflowrc\" file."
    echo "Please create it and write PROJECT_ID=\"<your PT project id>\" into it."
    exit 1
  }
  . ${PWD}/.workflowrc
}

function generate_rb_summary {
  local story_id="${1}"
  local story_title="${2}"
  echo "#${story_id}: ${story_title}"
}

GIT_LOG_FORMAT="--pretty=format:\"%h - %an, %ad : %s %b\""

function print_scream {
  echo -e "     .----------.   " 
  echo -e "    /  .-.  .-.  \  "
  echo -e "   /   | |  | |   \ "
  echo -e "   \   \`-'  \`-'  _/ "
  echo -e "   /\     .--.  / | "
  echo -e "   \ |   /  /  / /  "
  echo -e "   / |  \`--'  /\ \  "
  echo -e "    /\`-------'  \ \ "
}


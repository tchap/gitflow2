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

function ensure_pt_project_id {
  if [[ -z ${PROJECT_ID} ]]; then
    echo "Please specify Pivotal Tracker's PROJECT_ID in '.workflowrc' file"
    exit 1
  fi
}

function generate_rb_summary {
  local story_id="${1}"
  local story_title="${2}"
  echo "#${story_id}: ${story_title}"
}

# Lowercase and dasherize string.
function slugify_string {
  echo -e $1 | awk '{print tolower($0)}' | tr " " "-" | tr "\t" "-"
}

function check_bounds {
  local selected_index=$1
  local upper_bound=$2
  local lower_bound=$3

  [[ -n "${lower_bound}" ]] || lower_bound=0

  if [[ "${selected_index}" -lt "${lower_bound}" ]] || [[ "${selected_index}" -ge "${upper_bound}" ]]; then
    return 1
  else
    return 0
  fi
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


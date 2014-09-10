#!/bin/bash
set -o pipefail

__bold=`tput bold`
__normal=`tput sgr0`

function flush_stdio {
  while read -e -t 1; do : ; done
}

function ensure_pt_project_id {
  pid=$(git show gitflow-config:gitflow.yml | shyaml get-value "pivotaltracker.projectid") || {
    echo "${__bold}Oh noes! No gitflow config found!${__normal}"
    print_scream
    echo "So listen...we kinda expect you to have this ${__bold}gitflow.yml${__normal} file in a branch called "
    echo "${__bold}gitflow-config${__normal} in your repo. And you don't seem to have it. So please add it."
    echo "And specify 'pivotaltracker' field with 'projectid: <YOUR PT PROJECT ID>' in that file."
    echo
    echo "Have a nice day!"
    return 1
  }
  echo ${pid}
  return 0
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


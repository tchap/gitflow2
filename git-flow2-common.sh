#!/bin/bash
set -o pipefail

__bold=`tput bold`
__normal=`tput sgr0`

function flush_stdio {
  while read -e -t 1; do : ; done
}

function handle_missing_config {
  echo "${__bold}Oh noes! Missing gitflow config!${__normal}"
  print_scream
  echo "So listen...we kinda expect you to have a ${__bold}gitflow.yml${__normal} file in a branch called "
  echo "${__bold}gitflow-config${__normal} in your repo. And you don't seem to have it. So please add it."
  echo
  echo "Have a nice day!"
  return 1
}

function ensure_pt {
  local field="$1"
  local global="$2"

  local global_cfg=""
  
  if [[ -f "${HOME}/.gitflow.yml" ]]; then
    global_cfg=$(cat "${HOME}/.gitflow.yml")
  fi

  local local_cfg=$(git show gitflow-config:gitflow.yml) || {
    handle_missing_config
  }

  local value=$(echo "${local_cfg}" | shyaml get-value "pivotal_tracker.${field}")

  if [[ -z "${value}" ]]; then
    value=$(echo "${global_cfg}" | shyaml get-value "pivotal_tracker.${field}")
  fi

  if [[ -z "${value}" ]]; then
    echo "${__bold}Oh noes! Missing gitflow config '${field}'!${__normal}"
    print_scream
    if [[ -z "${global}" ]]; then
      echo "Add '${field}' to the 'pivotal_tracker' section of your gitflow.yml file in the gitflow-config branch!"
    else
      echo "Add '${field}' to the 'pivotal_tracker' section of ${HOME}/.gitflow.yml file!"
    fi
    exit 1
  fi

  echo ${value}

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


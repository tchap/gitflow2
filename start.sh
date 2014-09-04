#!/bin/bash
set -e;

source rainbow.sh
source spinner.sh

# Load PROJECT_ID.
source .workflowrc

trap cleanup EXIT

function cleanup {
  if [[ "$?" -ne "0" ]]; then
    echo "Oops, sorry, something went wrong so I'm bailing out."
  fi
  stop_spinner 0
}

# Lowercase and dasherize string.
function slugify_string {
  echo -e $1 | awk '{print tolower($0)}' | tr " " "-" | tr "\t" "-"
}

function flush_stdio {
  while read -e -t 1; do : ; done
}

if [[ -z ${PROJECT_ID} ]]; then
  echo "Please specify Pivotal Tracker's PROJECT_ID in '.workflowrc' file"
  exit 1
fi

# Make sure we're spliting strings by newlines.
export IFS=$'\n'

echogreen "Choosing the Story"

start_spinner "Loading stories from Pivotal tracker"
# Get all relevant stories from PT.
stories=$(pivotal_tools show stories --number 100  --project-id ${PROJECT_ID}) || {
  # Handle failure.
  echo -e "\n${stories}"
  exit 1
}
stop_spinner 0

stories_array=($(echo -e "${stories}" | grep "feature\|bug[\s]+started\|unstarted[^[]+\[" | grep -v "unscheduled[^[]*\["))

echo "I will now list all the suitable stories in Pivotal Tracker I've found."

for i in "${!stories_array[@]}"; do
  if [ "$i" -le "9" ]; then
    # OCD padding.
    echo "[$i]:  ${stories_array[$i]} [$i]";
  else
    echo "[$i]: ${stories_array[$i]} [$i]";
  fi;
done

flush_stdio

# Prompt user to select a story.
read -p "Please choose a story to start: " story_index
case $story_index in
  [0-9]* ) echo "You chose story number ${story_index}. Thank you.";;
  * ) echo "Non-numeric value detected. Exiting now."; exit 0;;
esac

# Parse story string to get the story id.
story_id=`echo ${stories_array[$story_index]} | cut -d' ' -f1 | tr -d \#`

[[ -n "${DEBUG}" ]] && echo -e "matching branches:\n `git branch -a | grep ${story_id}`"

matching_branches=$(\
  git branch -a | grep ${story_id} | \
  sed 's~^\*\ ~  ~;s~^[ ]*~~'| sed "s~remotes/[^/]*/~~" | \
  uniq
) || echo ""

[[ -n "${DEBUG}" ]] && echo -e "matches:" ${matching_branches}

if [[ -n "${matching_branches}" ]]; then
  echo
  echo "Wait wait wait. Existing branch(es) found for story ${story_id}."
  for branch in "${matching_branches}"; do echo " - ${branch}"; done
  echo
  echo "Just checkout one of them and work there."
  echo "I wish you a good day."
  exit 0
fi

echogreen "Creating The Feature Branch"

flush_stdio

echo "I'll ask you to input a human readable slug now."
echo "It will be used to create the feature branch."
read -p "Please insert the slug: " human_name

story_slug=`slugify_string "${human_name}"`
new_branch="story/${story_slug}/${story_id}"

echo "This will create a branch called '${new_branch}'"
read -p "You cool with that? [y/n] " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo
  echo "I will exit now. If you want to try again, just run me again."
  echo "Have a nice day."
  exit 0
fi

echo "I will now checkout develop..."
git checkout develop

echo

echo "Creating branch '${new_branch}' now..."
git checkout -b ${new_branch}

echo

# Instruct PT backend to update the story.
start_spinner "Setting story #${story_id} state to 'started'"
echo
pivotal_tools start story ${story_id} --project-id ${PROJECT_ID}
stop_spinner 0

echo; echogreen "Done"

echo "Well done! Story is started and branch is created. And you're on it."
echo "Have a nice day!"

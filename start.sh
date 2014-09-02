set -e

source rainbow.sh
source spinner.sh

# Load PROJECT_ID.
source .workflowrc

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
  stop_spinner 0
  exit 1
}
stop_spinner 0
stories=$(echo "${stories}" | grep "feature\|bug[\s]+started\|unstarted[^[]+\[" | grep -v "unscheduled[^[]*\[")

echo "I will now list all the suitable stories in Pivotal Tracker I've found."

line_index=0;
for line in $stories; do
  if [ "$line_index" -le "9" ]; then
    # Add OCD padding.
    echo "[$line_index]:  $line [$line_index]";
  else
    echo "[$line_index]: $line [$line_index]";
  fi;
  line_index=`expr $line_index + 1`
done

# Prompt user to select a story.
while read -e -t 1; do : ; done
read -p "Please choose a story to start: " story_index
case $story_index in
  [0-9]* ) echo "You chose story number ${story_index}. Thank you. ";;
  * ) echo "Non numeric value detected. Exiting now."; exit 0;;
esac

# Find story with selected index.
line_index=0;
for line in $stories; do
  if [ "${line_index}" -eq "${story_index}" ]; then
    story=${line}
  fi
  line_index=`expr $line_index + 1`
done

# Parse story string to get the story id.
story_id=`echo ${story} | cut -d' ' -f1 | tr -d \#`

branch_exists=`git branch -a | grep ${story_id}`
if [[ ! -z "${branch_exists}" ]]; then
  echo
  echo -e "Wait wait wait. Existing branch found for story ${story_id} -> ${branch_exists}"
  echo -e "Just checkout branch ${branch_exists} and you'll be alright."
  exit 0
fi

echo; echogreen "Creating The Feature Branch"

echo "I'll ask you to input a human readable slug now."
echo "It will be used to create the feature branch."
read -p "Please insert the slug: " story_slug

story_slug=`echo -e ${story_slug} | awk '{print tolower($0)}' | tr " " "-" | tr "\t" "-"`

NEW_BRANCH="story/${story_slug}/${story_id}"

echo "This will create a branch called '${NEW_BRANCH}'"
read -p "You cool with that? [y/n] " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

echo "I will now checkout develop..."
git checkout develop

echo

echo "Creating branch story/${story_slug}/${story_id} now..."
git checkout -b "story/${story_slug}/${story_id}" 

echo

# Instruct PT backend to update the story.
start_spinner "Setting story #${story_id} state to 'started'"
pivotal_tools start story ${story_id} --project-id ${PROJECT_ID} || {
  stop_spinner 0
}
echo
stop_spinner 0

echo; echogreen "Done"

echo "Well done! Story is started and branch is created. And you're on it."
echo "Have a nice day!"

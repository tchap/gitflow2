set -e;

source spinner.sh
source rainbow.sh

# Load PROJECT_ID.
source .workflowrc 

# Make sure we're spliting strings by newlines.
export IFS=$'\n'

BRANCH=`git branch | sed -n '/\* /s///p'`
STORY_ID=`echo ${BRANCH} | rev | cut -d"/" -f 1 | rev`

if [[ ! "${BRANCH}" == story/* ]]; then
  echo "I'm sorry Dave, I can't let you do that. You don't seem to be on a story branch."
  echo "Your branch is '${BRANCH}'. You have to checkout a story branch."
  echo "I will cowardly exit now. Have a good day."
  exit 1
fi

echo "You are finishing story ${STORY_ID}. Swell!"
echo
echo "Here's what's going to happen:"
echo -e "\t 1) We'll rebase branch '${BRANCH}' on top of branch 'develop'"
echo -e "\t 2) We'll try to find an existing review request draft for story ${STORY_ID}"
echo -e "\t 3) We'll update the review request with all your new commits on this branch."
echo -e "\t    If we can't find an existing review request, we'll just create a new one."

echo; echo "Alright. Let's get on with it then!"

echo; echogreen "Enter GitHub"
start_spinner "Fetching origin to get latest develop..."
git fetch origin -a
stop_spinner 0

SHOULD_UPDATE_REVIEW=false

echo; echogreen "Enter ReviewBoard"

start_spinner "Loading data from ReviewBoard... (might take a moment or two)"
review_drafts=`rbt status | grep -e '^[ \t]*\*' | grep ${STORY_ID} &` || `echo ''`
stop_spinner 0
echo -e "Jolly good, I got them data."

# How many review drafts do I have in RB?
count=`echo ${review_drafts} | sed '/^\s*$/d' | wc -l`
if [ "${count}" -gt "1" ]; then
  echo
  echo -e "I have found more than one review request candidate to update. Here they are:"
  echo -e ${review_drafts}
  SHOULD_UPDATE_REVIEW=true;
  #echo -e "I can't decide between them so I will cowardly quit now. Sorry!"
  #echo -e "Please sort it out (discard some of them, maybe?) and run me again!"
  #echo -e "Have a good day now."
  #exit 1
elif [ "${count}" -eq "1" ]; then
  #review_id=`echo ${review_drafts} | sed -E 's/[^r]+r\/([0-9]+).*/\1/'`
  SHOULD_UPDATE_REVIEW=true;
else
  echo -e "No suitable review request found."
fi

echo; echogreen "Enter Pivotal Tracker"

start_spinner "Now I'm loading your story (${STORY_ID}) details from Pivotal Tracker..."
stories=$(pivotal_tools show stories --number 100 --project-id ${PROJECT_ID}) || {
  echo -e "\n${stories}"
  stop_spinner 0
  exit 1
}
stop_spinner 0

story_title=$(echo "${stories}" | grep ${STORY_ID} | sed -E 's/^.*\[[* ]+\][ ]*(.+)/\1/')

echo -e "Story info loaded (story title is: \"${story_title}\")"

echo; echogreen "Enter Rebase"

echo -e "Rebasing ${BRANCH} on top of develop..."
echo -e "I just want to point out I haven't done any changes to your repository up to this point."
echo -e "But I will now because rebasing obviously is a change."
echo -e "If you get yourself into conflicts, resolve them and just run me again, yeees?\n"
git rebase develop

echo -e "Sweet, ${BRANCH} is now totally rebased on top of develop!"

echo; echogreen "Posting Review"

if [ ${SHOULD_UPDATE_REVIEW} = true ]; then
  echo -e "Yo dawg, I herd U like review requests so I will try to update your review request with a review request!"
  update="-u"
else
  echo -e "Posting a new review request..."
fi

descr=`git log --pretty=format:"%h - %an, %ad : %s" develop..`

rbt post --parent develop ${update} --description "${descr}" --summary "${STORY_ID}: ${story_title}"

echo; echogreen "Next Steps"
echo "Please go through the review and annotate it. If you find any issues you want to fix, do it and run me again."
echo; echored "####################################################"
echored "IMPORTANT: Your code has not been merged and pushed."
echored "####################################################"
echo;
echo "NEXT STEPS:"
echo -e "\t 1) When you think the review is ready to be published, publish it in ReviewBoard."
echo -e "\t 2) Rebase on top of develop with 'git rebase develop'"
echo -e "\t 3) Merge into develop with 'git checkout develop && git merge ${BRANCH}'"
echo -e "\t 4) Push to GitHub with 'git push origin develop'"
echo
echo "Now have a good day!"

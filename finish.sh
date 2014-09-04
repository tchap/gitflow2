set -e;

source spinner.sh
source rainbow.sh

# Load PROJECT_ID.
source .workflowrc 

trap cleanup EXIT

function cleanup {
  stop_spinner 0
}

__bold=`tput bold`
__normal=`tput sgr0`

# Make sure we're spliting strings by newlines.
export IFS=$'\n'

BRANCH=`git branch | sed -n '/\* /s///p'`
STORY_ID=`echo ${BRANCH} | rev | cut -d"/" -f 1 | rev`

# Check whether we're on a story branch.
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
echo -e "\t    If we can't find an existing review request, we'll create a new one."
echo
echo "Alright."
echo
echo "    ,-~~-.___.          "
echo "   / |  '     \         " 
echo "  (  )         0    Let's do this!"
echo "   \_/-, ,----'         "
echo "      ====           // "
echo "     /  \-'~;    /~~~(O)"
echo "    /  __/~|   /       |"
echo "  =(  _____| (_________|"
echo
echo; echogreen "Enter GitHub"

start_spinner "Fetching origin to get latest develop..."
git fetch origin -a
stop_spinner 0

SHOULD_UPDATE_REVIEW=false

echo; echogreen "Enter Pivotal Tracker"

start_spinner "Loading story #${STORY_ID} details from Pivotal Tracker..."
stories=$(pivotal_tools show stories --number 100 --project-id ${PROJECT_ID}) || {
  echo -e "\n${stories}"
  exit 1
}
stop_spinner 0

story_title=$(echo "${stories}" | grep ${STORY_ID} | sed -E 's/^.*\[[* ]+\][ ]*(.+)/\1/')

[[ -n ${DEBUG} ]] && echo -e "Story info loaded (story title is: \"${story_title}\")"

echo; echogreen "Enter Rebase"

echo -e "Rebasing ${BRANCH} on top of develop..."
git rebase develop || {
  echo -e "${__bold}Oh noes! Looks like rebase failed.${__normal}\n"
  echo -e "     .----------.   " 
  echo -e "    /  .-.  .-.  \  "
  echo -e "   /   | |  | |   \ "
  echo -e "   \   \`-'  \`-'  _/ "
  echo -e "   /\     .--.  / | "
  echo -e "   \ |   /  /  / /  "
  echo -e "   / |  \`--'  /\ \  "
  echo -e "    /\`-------'  \ \ "
  echo -e "\nBut you'll be fine. Really.\n${__bold}Follow git's instructions above \
and when you're done, just run me again.${__normal}"
  exit 1
}

echo; echo -e "Sweet, ${BRANCH} is now totally rebased on top of develop!"

echo; echogreen "Enter ReviewBoard"

start_spinner "Loading data from ReviewBoard... (might take a moment or two)"
reviews=$(rbt status | grep ${STORY_ID} || echo)
stop_spinner 0

[[ -n "${DEBUG}" ]] && echo -e "Jolly good, I got them data."

# How many review drafts do I have in RB?
count=`echo "${reviews}" | wc -l`
if [ "${count}" -gt "1" ]; then
  SHOULD_UPDATE_REVIEW=true;
  echo -e "\nI have found more than one review request candidate to update. Here they are:"
  echo -e "${reviews}"
  echo -e "Note: '*' means it's a draft (or there's an unpublished new update)."
elif [ "${count}" -eq "1" ]; then
  SHOULD_UPDATE_REVIEW=true;
else
  echo -e "No suitable review request found. Will create a shiny new one."
fi

echo; echogreen "Posting Review"

if [ ${SHOULD_UPDATE_REVIEW} = true ]; then
  echo -e "Yo dawg, I herd U like review requests so I will try to update your review request with a review request!"
  echo -e "If I can't decide for sures which review is the ONE, I will give you a choice."
  update="-u"
else
  echo -e "Posting a new review request..."
fi

descr=`git log --pretty=format:"%h - %an, %ad : %s" develop..`

rbt post --parent develop ${update} --description "${descr}" --summary "${STORY_ID}: ${story_title}"

echo; echogreen "Next Steps"
echo "Please go through the review and annotate it. If you find any issues you want to fix, do it and run me again."
echo; echored "#######################################################"
echored "IMPORTANT: Your code has not been merged and/or pushed."
echored "#######################################################"
echo;
echo "NEXT STEPS:"
echo -e "\t 1) When you think the review is ready to be published, publish it in ReviewBoard."
echo -e "\t 2) Rebase on top of develop with ${__bold}'git rebase develop'${__normal}"
echo -e "\t 3) Merge into develop with ${__bold}'git checkout develop && git merge \
${BRANCH}'${__normal}"
echo -e "\t 4) Push to GitHub with ${__bold}'git push origin develop'${__normal}"
echo
echo "Now have a good day!"

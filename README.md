# GitFlow Mark 2 (Commands)

## Installation

 * Clone this repository.
 * `pip install -r requirements.txt --allow-unverified RBTools --allow-external RBTools`
 * Update your system PATH to include this repo contents.

Then

 * Set `PIVOTAL_TOKEN` env var to your PT API token.
 * Create a `.workflowrc` file in your project's directory root and add: `PROJECT_ID='<your PR project id>'.`


## Commands
start.sh -> start a story
finish.sh -> rebase and post a review

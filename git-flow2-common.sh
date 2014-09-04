#!/bin/bash

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

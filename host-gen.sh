#!/usr/bin/env bash

CURRENT_PATH=$(pwd)
COMMAND=${1/--/''}

print_meta() {
  echo ''
}

print_help() {
  echo ''
}

main() {
  print_meta
  if [ -z "$COMMAND" ]
    then
      echo "Nothing specified. Please specify one of these"
      print_help
  elif [[ "check-update|configure" == *"$COMMAND"* ]]
    then
      ./$COMMAND.sh
  elif [[ "-help" == *"$COMMAND"* ]]
    then
      print_help
  else
    echo "$COMMAND option doesn't exist. Here are all the options:"
    print_help
  fi
}

main
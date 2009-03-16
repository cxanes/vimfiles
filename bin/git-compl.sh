#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "${0##/*/} <COMP_WORDS> <COMP_CWORD>"
    exit
fi

if ! type "git" > /dev/null 2>&1; then
    echo "${0##/*/}: git: Not found"
    exit
fi

GIT_COMPL=${GIT_COMPL:-/etc/bash_completion.d/git}
if [ -e "$GIT_COMPL" ]; then
    source "$GIT_COMPL"
else
    echo "${0##/*/}: $GIT_COMPL: No such file for git completion"
    exit
fi

eval COMP_WORDS=($1)
COMP_CWORD=$2 _git
for i in "${COMPREPLY[@]}"; do
    echo $i
done


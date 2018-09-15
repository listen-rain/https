#!/usr/bin/env bash

# The specified directory
read -p 'please input the work dir, default is [./keys]: ' -a workDir

if [ -z "$workDir" ]; then
    workDir=./keys
fi

if [ ! -d "$workDir" ]; then
    mkdir "$workDir"
fi

export GENERATE_WORKDIR="$workDir"

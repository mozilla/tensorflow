#!/bin/bash

set -ex

curdir=$(dirname "$0")

pip3 install --quiet --user --upgrade pip

curl -L --silent https://raw.githubusercontent.com/lissyx/taskcluster-github-decision/42212007ae8b416944fcf579cf884f11bafd00d3/requirements.txt | pip3 install --quiet --user --upgrade -r /dev/stdin
curl -L --silent https://raw.githubusercontent.com/lissyx/taskcluster-github-decision/42212007ae8b416944fcf579cf884f11bafd00d3/tc-decision.py > ${curdir}/tc-decision.py
python3 ${curdir}/tc-decision.py

#!/bin/bash

# Get yesterday's date in ISO format (or Friday if today is Monday)
DAY_OF_WEEK=$(date +%u)
if [[ "$DAY_OF_WEEK" == "1" ]]; then
    # Monday - grab Friday's PRs instead of Sunday's
    DAYS_AGO=3
else
    DAYS_AGO=1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    YESTERDAY=$(date -v-${DAYS_AGO}d +%Y-%m-%d)
else
    YESTERDAY=$(date -d "$DAYS_AGO days ago" +%Y-%m-%d)
fi

# Get the current GitHub user
GH_USER=$(gh api user --jq '.login')

# Fetch PRs authored by user, updated since yesterday
gh search prs --author="$GH_USER" --updated=">=$YESTERDAY" --json title,url,state,updatedAt --limit 100 | \
    jq -r --arg yesterday "$YESTERDAY" '
        .[] |
        select(.updatedAt | startswith($yesterday)) |
        (if .state == "merged" then ":pr-merged:"
         elif .state == "closed" then ":pr-closed:"
         else ":pr-open:" end) + " " + .title + " (" + (.url | split("/") | .[-3] + "/" + .[-2] + "/" + .[-1]) + ")"
    '

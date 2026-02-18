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
    # Fetch one extra day back to account for UTC offset
    QUERY_SINCE=$(date -v-$((DAYS_AGO + 1))d +%Y-%m-%d)
    YESTERDAY_START=$(date -jf "%Y-%m-%d %H:%M:%S" "$YESTERDAY 00:00:00" +%s)
    YESTERDAY_END=$(date -jf "%Y-%m-%d %H:%M:%S" "$YESTERDAY 23:59:59" +%s)
else
    YESTERDAY=$(date -d "$DAYS_AGO days ago" +%Y-%m-%d)
    QUERY_SINCE=$(date -d "$((DAYS_AGO + 1)) days ago" +%Y-%m-%d)
    YESTERDAY_START=$(date -d "$YESTERDAY 00:00:00" +%s)
    YESTERDAY_END=$(date -d "$YESTERDAY 23:59:59" +%s)
fi

# Get the current GitHub user
GH_USER=$(gh api user --jq '.login')

# Query with an extra day buffer since GitHub uses UTC, then filter by local time.
# Match PRs that were either created OR updated yesterday (local time).
gh search prs --author="$GH_USER" --updated=">=$QUERY_SINCE" --json title,url,state,updatedAt,createdAt --limit 100 | \
    jq -r --arg start "$YESTERDAY_START" --arg end "$YESTERDAY_END" '
        def in_range: (sub("\\.[0-9]+"; "") | fromdate) as $ts |
            ($ts >= ($start | tonumber)) and ($ts <= ($end | tonumber));
        .[] |
        select((.updatedAt | in_range) or (.createdAt | in_range)) |
        (if .state == "merged" then ":pr-merged:"
         elif .state == "closed" then ":pr-closed:"
         else ":pr-open:" end) + " " + .title + " (" + (.url | split("/") | .[-3] + "/" + .[-2] + "/" + .[-1]) + ")"
    '

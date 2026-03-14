#!/bin/bash

# Determine how many days back to look
DAY_OF_WEEK=$(date +%u)
if [[ "$DAY_OF_WEEK" == "1" ]]; then
    # Monday - grab Friday through Sunday
    DAYS_AGO=3
else
    DAYS_AGO=1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    RANGE_START_DATE=$(date -v-${DAYS_AGO}d +%Y-%m-%d)
    RANGE_END_DATE=$(date -v-1d +%Y-%m-%d)
    # Fetch one extra day back to account for UTC offset
    QUERY_SINCE=$(date -v-$((DAYS_AGO + 1))d +%Y-%m-%d)
    RANGE_START=$(date -jf "%Y-%m-%d %H:%M:%S" "$RANGE_START_DATE 00:00:00" +%s)
    RANGE_END=$(date -jf "%Y-%m-%d %H:%M:%S" "$RANGE_END_DATE 23:59:59" +%s)
else
    RANGE_START_DATE=$(date -d "$DAYS_AGO days ago" +%Y-%m-%d)
    RANGE_END_DATE=$(date -d "1 day ago" +%Y-%m-%d)
    QUERY_SINCE=$(date -d "$((DAYS_AGO + 1)) days ago" +%Y-%m-%d)
    RANGE_START=$(date -d "$RANGE_START_DATE 00:00:00" +%s)
    RANGE_END=$(date -d "$RANGE_END_DATE 23:59:59" +%s)
fi

# Get the current GitHub user
GH_USER=$(gh api user --jq '.login')

# Query with an extra day buffer since GitHub uses UTC, then filter by local time.
# Match PRs that were either created OR updated within the date range (local time).
gh search prs --author="$GH_USER" --updated=">=$QUERY_SINCE" --json title,url,state,updatedAt,createdAt --limit 100 | \
    jq -r --arg start "$RANGE_START" --arg end "$RANGE_END" '
        def in_range: (sub("\\.[0-9]+"; "") | fromdate) as $ts |
            ($ts >= ($start | tonumber)) and ($ts <= ($end | tonumber));
        .[] |
        select((.updatedAt | in_range) or (.createdAt | in_range)) |
        (if .state == "merged" then ":pr-merged:"
         elif .state == "closed" then ":pr-closed:"
         else ":pr-open:" end) + " " + .title + " (" + (.url | split("/") | .[-3] + "/" + .[-2] + "/" + .[-1]) + ")"
    '

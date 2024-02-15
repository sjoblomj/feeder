#!/bin/bash
url="$1"

function perform_query() {
  uri="$1"
  command="$2"
  curl -sL \
   -H "Accept: application/vnd.github.raw+json" \
   -H "X-GitHub-Api-Version: 2022-11-28" \
   "$uri" |
   jq "${command}" | \
   jq '. | map(select(.event as $e | ["assigned", "labeled"] | index($e) | not))' | \
   jq '. | map({"id": (.id // .source.issue.id // .sha), "text": (.body // .commit.message), "user": (.user.login // .actor.login // .author.name // .author.login), "userPicture": (.user.avatar_url // .actor.avatar_url // .author.avatar_url), "title": (.title // .source.issue.title // .milestone.title // .message // .name), "url": (.html_url // .url // .source.issue.html_url), "event": .event, "pull_request": (if .source.issue.pull_request == null then null else {"url": .source.issue.pull_request.html_url, "merged": .source.issue.pull_request.merged_at} end), "state": .state, "created": (.created_at // .author.date // .commit.author.date), "updated": .updated_at})' | \
   jq '. | map({"id": .id, "text": (if (.event == "cross-referenced") or (.event == "committed") then "[" + .title + "](" + .url + ")" + (if .pull_request.merged != null then " (merged " + .pull_request.merged + ")" else "" end) else .text end), "user": .user, "userPicture": .userPicture, "title": (if (.title != null) and (.event == null) then .title else (if .event == "commented" then null else .event end) end), "url": .url, "created": .created, "updated": (if .created != .updated then .updated else null end)}) | sort_by(.created)'
}

if (echo "$url" | grep -Eq  ^.*/issues/[0-9]+/?$); then
    base=$(perform_query "$url" "[.]")
    tl=$(perform_query "$url/timeline" ".")
    jq --argjson arr1 "$base" --argjson arr2 "$tl" -n '$arr1 + $arr2'
else
    perform_query "$url" "."
fi

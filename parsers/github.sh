#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

if [[ $url =~ ^https://(api\.|www\.)?github.com/(repos/)?([^/]+)/([^/]+)/(.*)$ ]]; then
    rep="${BASH_REMATCH[3]}/${BASH_REMATCH[4]}/${BASH_REMATCH[5]}"
    url="https://api.github.com/repos/$rep"
    url=$(echo $url | sed "s|/$||")
    if [[ $url =~ ^.*/pull/[0-9]+$ ]]; then
        url=$(echo $url | sed -r "s|pull/([0-9]+)|issues/\1|")
    fi
else
    echo "Could not understand URL '$url'"
    exit 1
fi

function perform_query() {
    local uri="$1"
    local cmd="$2"
    local sitedata="[]"
    if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
        sitedata=$(curl --connect-timeout 10 -sL \
            -H "Accept: application/vnd.github.raw+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "$uri")
    else
        sitedata=$(curl --connect-timeout 10 -sL \
            -H "Authorization: Bearer $GITHUB_ACCESS_TOKEN" \
            -H "Accept: application/vnd.github.raw+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "$uri")
    fi
    if [ -z "$sitedata" ]; then
        sitedata="[]"
    fi
    echo "$sitedata" | \
        jq "${cmd}" | \
        jq '. | map(select(.event? as $e | ["assigned", "labeled"] | index($e) | not))' | \
        jq '. | map({"id": (.id // .source.issue.id // .sha), "text": (.body // .commit.message), "user": (.user.login // .actor.login // .author.name // .author.login), "userPicture": (.user.avatar_url // .actor.avatar_url // .author.avatar_url), "title": (.title // .source.issue.title // .milestone.title // .message // (if (.name != null and .name != "") then .name elif (.commit) then "Committed" else .tag_name end)), "url": (.html_url // .url // .source.issue.html_url), "event": .event, "pull_request": (if .source.issue.pull_request == null then null else {"url": .source.issue.pull_request.html_url, "merged": .source.issue.pull_request.merged_at} end), "state": .state, "created": (.created_at // .author.date // .commit.author.date), "updated": .updated_at})' | \
        jq '. | map({"id": .id, "text": (if (.event == "cross-referenced") or (.event == "committed") then "[" + .title + "](" + .url + ")" + (if .pull_request.merged != null then " (merged " + .pull_request.merged + ")" else "" end) else .text end), "user": .user, "userPicture": .userPicture, "title": (.title // .event), "url": .url, "created": .created, "updated": (if .created != .updated then .updated else null end)})' | \
        filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
}

if (echo "$url" | grep -Eq ^.*/issues/[0-9]+/?$); then
    base=$(perform_query "$url" "[.]")
    tl=$(perform_query "$url/timeline" ".")
    jq --argjson arr1 "$base" --argjson arr2 "$tl" -n '$arr1 + $arr2 | sort_by(.created) | reverse'
else
    perform_query "$url" "."
fi

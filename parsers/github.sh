#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

if [[ $url =~ ^https://(api\.|www\.)?github.com/(repos/)?([^/]+)/([^/]+)/(.*)$ ]]; then
    rep="${BASH_REMATCH[3]}/${BASH_REMATCH[4]}/${BASH_REMATCH[5]}"
    url="https://api.github.com/repos/${rep%/}"
    if [[ $url =~ ^.*/pull/[0-9]+$ ]]; then
        url=$(echo "$url" | sed -r "s|pull/([0-9]+)|issues/\1|")
    fi
else
    echo "Could not understand URL '$url'"
    exit 1
fi

function perform_query() {
    local uri="$1"
    local cmd="$2"
    local authorization="${GITHUB_ACCESS_TOKEN:+Authorization: Bearer $GITHUB_ACCESS_TOKEN}" # Empty if GITHUB_ACCESS_TOKEN is unset
    get_json "$uri" "[]" "Accept: application/vnd.github.raw+json" "X-GitHub-Api-Version: 2022-11-28" "$authorization" | \
        jq "${cmd}" | \
        jq '. | map(select(.event? as $e | ["assigned", "labeled"] | index($e) | not))' | \
        jq '. | map({"id": (.id // .source.issue.id // .sha), "text": (.body // .commit.message), "user": (.user.login // .actor.login // .author.name // .author.login), "userPicture": (.user.avatar_url // .actor.avatar_url // .author.avatar_url), "title": (.title // .source.issue.title // .milestone.title // .message // (if (.name != null and .name != "") then .name elif (.commit) then "Committed" else .tag_name end)), "url": (.html_url // .url // .source.issue.html_url), "event": .event, "pull_request": (if .source.issue.pull_request == null then null else {"url": .source.issue.pull_request.html_url, "merged": .source.issue.pull_request.merged_at} end), "state": .state, "created": (.created_at // .author.date // .commit.author.date // .submitted_at), "updated": .updated_at})' | \
        jq '. | map({"id": .id, "text": (if (.event == "cross-referenced") or (.event == "committed") then "[" + .title + "](" + .url + ")" + (if .pull_request.merged != null then " (merged " + .pull_request.merged + ")" else "" end) else .text end), "user": .user, "userPicture": .userPicture, "title": (.title // .event), "url": .url, "created": .created, "updated": (if .created != .updated then .updated else null end)})'
}

function get_last_timeline_page_number() {
    # Given a issue URL, this function will query the GitHub pagination API and
    # return the  page number of  the last result page.  If there are no pages,
    # 0 will be returned. The returned page number can be used to query the API
    # for content.
    local authorization="${GITHUB_ACCESS_TOKEN:+Authorization: Bearer $GITHUB_ACCESS_TOKEN}" # Empty if GITHUB_ACCESS_TOKEN is unset
    resp=$(curl -Is \
      -H "Accept: application/vnd.github+json" ${authorization:+-H "$authorization"} \
      "$1/timeline?per_page=$maxelems&page=1" | \
        grep -P '^link:' | \
        sed -e 's/,/\n/g' | \
        sed -E 's/.*<(.*)>; rel="(.*)"/\2 \1/g')

    if [[ -z $resp ]]; then
        echo "0"
    else
        lastpageurl=$(echo "$resp" | grep -Po '^last (\K.*)')
        echo "$lastpageurl" | grep -Po '.*/timeline\?per_page=\d*&page=(\K\d+)'
    fi
}

function get_timeline() {
    local uri="$1"
    local pagenum
    local tl

    tl="[]"
    pagenum=$(get_last_timeline_page_number "$uri")

    # No pagination, just fetch the timeline without pages
    if [[ "$pagenum" -eq 0 ]]; then
        tl=$(perform_query "$url/timeline" "." | filter_and_shrink "$filter" "$maxelems" "$maxtextlen")
    fi

    # Loop over pages until we have maxelems or there are no more pages
    while [[ "$pagenum" -gt 0 ]]; do
        tlres=$(perform_query "$url/timeline?per_page=$maxelems&page=$pagenum" ".")
        tl=$(jq --argjson l1 "$tl" --argjson l2 "$tlres" -n '$l1 + $l2' | filter_and_shrink "$filter" "$maxelems" "$maxtextlen")

        pagenum=$((pagenum - 1))
        if [[ $(jq --argjson list "$tl" -n '$list | length') -eq "$maxelems" ]]; then
            break
        fi
    done
    echo "$tl"
}

if [[ $url =~ ^.*/issues/[0-9]+/?$ ]]; then
    tl=$(get_timeline "$url")
    base=$(perform_query "$url" "[.]" | filter_and_shrink "$filter" "$maxelems" "$maxtextlen")
    jq --argjson base "$base" --argjson tl "$tl" -n '$tl + $base'
else
    perform_query "$url" "." | \
        filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi

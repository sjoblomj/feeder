#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

if [[ $url =~ ^https://youtrack.jetbrains.com/(api/issues|issue)/(JBR-[0-9]+)/?$ ]]; then
    issuenumber="${BASH_REMATCH[2]}"
    url="https://youtrack.jetbrains.com/api/issues/$issuenumber"
else
    echo "Could not understand URL '$url'"
    exit 1
fi

sitedata=$(get_json "${url}?%24top=-1&fields=wikifiedDescription,id,created,updated,summary,reporter(%40user),updater(%40user)%3B%40user%3AfullName,avatarUrl" "{}" "Accept: application/json")
base=$(echo "$sitedata" | \
    jq '{"id": .id, "title": .summary, "text": .wikifiedDescription, "created": (if .created == null then null else .created / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "updated": (if .updated == null then null else .updated / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "user": .reporter.fullName, "userPicture": .reporter.avatarUrl}' | \
    jq '[.]' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
)

sitedata=$(get_json "${url}/activitiesPage?categories=CommentsCategory&reverse=true&fields=activities(added(author(name,avatarUrl),id,updated,created,text),timestamp)" "{}" "Accept: application/json")
comments=$(echo "$sitedata" | \
    jq '.activities? // []' | \
    jq 'map(.added[])'      | \
    jq 'map({"id": .id, "user": .author.name, "userPicture": .author.avatarUrl, "text": .text, "created": (if .created == null then null else .created / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "updated": (if .updated == null then null else .updated / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "title": "Comment"})' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
)

jq --argjson base "$base" --argjson comments "$comments" -n '$comments + $base'

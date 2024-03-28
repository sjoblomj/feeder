#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="${2:-.*}"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

if [[ $url =~ ^https://youtrack.jetbrains.com/(api/issues|issue)/(JBR-[0-9]+)/?$ ]]; then
    issuenumber="${BASH_REMATCH[2]}"
    url="https://youtrack.jetbrains.com/api/issues/$issuenumber"
else
    echo "Could not understand URL '$url'"
    exit 1
fi

sitedata=$(curl --connect-timeout 10 -s "${url}?%24top=-1&fields=description,id,usesMarkdown,created,updated,summary,reporter(%40user),updater(%40user)%3B%40user%3AfullName,avatarUrl" --compressed -H "Accept: application/json")
if [ -z "$sitedata" ]; then
    sitedata="{}"
fi
base=$(echo "$sitedata" | \
    jq '{"id": .id, "title": .summary, "text": .description, "created": (if .created == null then null else .created / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "updated": (if .updated == null then null else .updated / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "user": .reporter.fullName, "userPicture": .reporter.avatarUrl}' | \
    jq '[.]' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
)

sitedata=$(curl --connect-timeout 10 -s "${url}/activitiesPage?categories=CommentsCategory&reverse=true&fields=activities(added(author(name,avatarUrl),id,updated,created,text,usesMarkdown,files),timestamp)" -H "Accept: application/json")
if [ -z "$sitedata" ]; then
    sitedata="{}"
fi
comments=$(echo "$sitedata"  | \
    jq '.activities? // []'  | \
    jq 'map(.added.[])'      | \
    jq 'map({"id": .id, "user": .author.name, "userPicture": .author.avatarUrl, "text": .text, "created": (if .created == null then null else .created / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "updated": (if .updated == null then null else .updated / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "title": null})' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
)

jq --argjson base "$base" --argjson comments "$comments" -n '$comments + $base'

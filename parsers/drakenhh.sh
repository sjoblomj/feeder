#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

sitedata=$(curl --connect-timeout 10 -sL "$url")
if [ -z "$sitedata" ]; then
  echo "[]"
else
  echo "$sitedata" |
    yq --xml-skip-directives --xml-skip-proc-inst --xml-raw-token=false -p xml -o json '.' |
    jq '.html.body.div | .[] | select(."+@class" == "Site") | .div | .[] | select(."+@class" == "Site-inner") | .div.main.section.div.div.div.div | .[] | select(."+@class" | contains("row")) | .div | .[] | .div | .[] | select(."+@class" | contains("summary")) | .div.div.div.div.div' |
    jq '. | map({"url": (.div | .[] | select(."+@class" | contains("summary-content")) | .div | .[] | select(."+@class" == "summary-title") | .a."+@href"), "title": ((.div | .[] | select(."+@class" | contains("summary-content")) | .div | .[] | select(."+@class" == "summary-title") | .a."+content")), "created": ((.div | .[] | select(."+@class" | contains("summary-content")) | .div | .[] | select(."+@class" | contains("summary-metadata")) | .div | .[] | select(."+@class" | contains("summary-metadata--primary")) | .time."+@datetime"))})' |
    jq '. | unique | sort_by(.created) | reverse' |
    jq '. | map(. + {"id": .url, "updated": null, "created": (.created + "T00:00:00.000Z"), "url": ("https://www.drakenhh.com" + .url)})' |
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi

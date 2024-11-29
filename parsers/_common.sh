#!/bin/bash

function filter_and_shrink() {
  local filter="${1:-test(\".*\")}"
  local maxelems="$2"
  local maxtextlen="$3"

  local text
  text=$(</dev/stdin)
  if [ -z "$text" ]; then
    text="[]"
  fi
  filter=$(echo "$filter" | tr '[:upper:]' '[:lower:]')

  echo "$text" |
    jq "map(select(.title + \" \" + .text | ascii_downcase | $filter ))" |
    jq --arg maxtextlen "$maxtextlen" 'map(. += {"text": (if ((.text | length) > ($maxtextlen | tonumber)) then .text[:($maxtextlen | tonumber)] + " ..." else .text end)})' |
    jq --arg maxelems "$maxelems" 'sort_by(.created) | reverse | [limit($maxelems | tonumber; .[])]'
}

function get_json() {
  local url="$1"
  local fallback="${2:-[]}"
  local header0="$3"
  local header1="$4"
  local header2="$5"
  local sitedata

  sitedata=$(download_data "$url" "$header0" "$header1" "$header2")
  if [ -z "$sitedata" ] || ! echo "$sitedata" | jq -e . >/dev/null 2>&1; then
    sitedata="$fallback"
  fi
  echo "$sitedata"
}

function get_xml_as_json() {
  local url="$1"
  local sed_cleanup="$2"
  local header0="$3"
  local header1="$4"
  local header2="$5"
  local sitedata

  sitedata=$(download_data "$url" "$header0" "$header1" "$header2" | sed "$sed_cleanup")
  if [ -z "$sitedata" ] || ! echo "$sitedata" | yq -e -px . >/dev/null 2>&1; then
    sitedata=""
  fi
  echo "$sitedata" | yq --xml-skip-directives --xml-skip-proc-inst --xml-raw-token=false -p xml -o json '. // {}'
}

function download_data() {
  local url="$1"
  local header0="$2"
  local header1="$3"
  local header2="$4"

  curl --connect-timeout 10 -sL --compressed "$url" ${header0:+-H "$header0"} ${header1:+-H "$header1"} ${header2:+-H "$header2"}
}

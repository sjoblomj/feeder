#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="${2:-.*}"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

curl --connect-timeout 10 -sL "$url" | awk '
BEGIN {
    Debug = 0

    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month)
    for (i in month) {
        month_nums[month[i]] = i
    }

    Title     = ""
    Published = ""
    Item      = ""
    Items     = ""

    Is_reading_article = 0
    Is_reading_item    = 0
}
{
    if ($0 ~ "<section class=\"main\"")
        Is_reading_article = 1
    if (!Is_reading_article)
        next

    match($0, /<h3>(.*)&bull;(.*)<\/h3>/, a)
    if (RSTART != 0 && !Is_reading_item) {
        Is_reading_item = 1

        Title = trim(a[1])
        pub   = trim(a[2])
        gsub(/"/, "\\\"", Title) # Escape quotes
        gsub(/&ndash;/,  "—", Title)
        gsub(/&aacute;/, "á", Title)

        split(pub, puba)
        y = puba[3]
        m = int(month_nums[substr(puba[2], 1, 3)])
        if (m < 10)
            m = "0" m
        d = puba[1]
        if (d < 10)
            d = "0" d
        Published = y "-" m "-" d "T00:00:00.000Z"

        $0 = ""
        if (Debug) print "Read Title: '" Title "', Published: " Published > "/dev/stderr"
    }

    if ($0 ~ "<br><br><br><br>") {
        Is_reading_item = 0

        i = "  {\n"
        i = i "    \"id\": \"" Title "_" Published "\",\n"
        i = i "    \"title\": \"" Title "\",\n"
        i = i "    \"created\": \"" Published "\",\n"
        i = i "    \"text\": \"" trim(Item) "\"\n"
        i = i "  }"

        Items = Items (Items == "" ? "" : ",\n") i
        Item  = ""
    }
    if ($0 != "" && Is_reading_item) {
        gsub(/"/, "\\\"", $0) # Escape quotes
        gsub(/	/, " ",   $0) # Fix weird space
        Item = Item (Item == "" ? "" : "\\n") trim($0)
    }
}
END {
    print "[\n" Items "\n]"
}

# Trims away any whitespace (i.e. space, tab, newlines, carrige-returns) from the left and right of given [string]
function trim(string) {
    sub(/^[ \t\r\n]+/,  "", string)
    sub( /[ \t\r\n]+$/, "", string)
    return string
}' | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"

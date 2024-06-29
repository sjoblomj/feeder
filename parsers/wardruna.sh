#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

download_data "$url" | tr '\r' '\n' | tr "'" "\"" | awk -i "parsers/_common.awk" '
BEGIN {
    Debug = 0

    Title     = ""
    Published = ""
    Item      = ""
    Items     = ""
    Author    = "Wardruna"

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

        split(pub, a)
        Published = make_iso_datetime(a[3], a[2], a[1], "00", "00", "00", "000")

        $0 = ""
        if (Debug) print "Read Title: '" Title "', Published: " Published > "/dev/stderr"
    }

    if ($0 ~ "<br><br><br><br>") {
        Is_reading_item = 0

        Item = make_item(Item, Title "_" Published, Title, Author, null, Published)

        Items = Items (Items == "" ? "" : ",\n") Item
        Item  = ""
    }
    if ($0 != "" && Is_reading_item) {
        Item = Item (Item == "" ? "" : "\n") trim($0)
    }
}
END {
    print "[\n" Items "\n]"
}
' | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"

#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

curl --connect-timeout 10 -sL "$url" | tr '\r' '\n' | tr "'", "\"" | awk '
BEGIN {
    Debug = 0

    Base_url  = "http://www.stormcoast-fortress.net/"

    Title     = ""
    Published = ""
    Author    = ""
    Url       = ""
    Item      = ""
    Items     = ""

    Is_reading_article = 0
    Is_reading_item    = 0
}
{
    if ($0 ~ "<td class=.main.>")
        Is_reading_article = 1
    if ($0 ~ "<a href=./news/Archive/.>News Archive</a>")
        Is_reading_article = 0
    if (!Is_reading_article)
        next

    match($0, /<a name=.(.*).><\/a><table class=.fancytable. cellspacing=.0.>/, a)
    if (RSTART != 0) {
        Url = a[1]
        if (Debug) print "Url: " Url > "/dev/stderr"
    }

    match($0, /<td class=.fancycaption.>(.*)<\/td>/, a)
    if (RSTART != 0) {
        Title = a[1]
        if (Debug) print "Title: " Title > "/dev/stderr"
    }

    match($0, /<td><div class=.fancytop.>&nbsp;Posted: (.*)<\/div><\/td>/, a)
    if (RSTART != 0) {
        Published = a[1]
        split(Published, b)
        split(b[1], c, "-")
        if (length(c[1]) == 1)
            c[1] = "0" c[1]
        if (length(c[2]) == 1)
            c[2] = "0" c[2]

        Published = c[3] "-" c[2] "-" c[1] "T" b[2] "Z"
        if (Debug) print "Published: " Published > "/dev/stderr"
    }

    match($0, /<td align=.right.width=.150.><div class=.fancybox darkbglink.>&nbsp;<a href=[^>]*>(.*)<\/a><\/div><\/td>/, a)
    if (RSTART != 0) {
        Author = a[1]
        if (Debug) print "Author: " Author > "/dev/stderr"
    }

    match($0, /^<div class=.fancycontent.>(.*)/, a)
    if (RSTART != 0) {
        Is_reading_item = 1
        $0   = ""
        Item = a[1]
    }

    match($0, /(.*)<BR><br><\/div>/, a)
    if (RSTART != 0) {
        Is_reading_item = 0
        Item = trim(Item "\n" a[1])

        gsub(/\\/, "\\\\", Item)
        gsub(/"/,  "\\\"", Item)
        gsub(/\n/, "\\n", Item)
        Item = remove_non_ascii(Item)

        i = "  {\n"
        i = i "    \"id\": \"" Url "\",\n"
        i = i "    \"title\": \"" Title "\",\n"
        i = i "    \"user\": \"" Author "\",\n"
        i = i "    \"url\": \"" Base_url "#" Url "\",\n"
        i = i "    \"created\": \"" Published "\",\n"
        i = i "    \"text\": \"" Item "\"\n"
        i = i "  }"

        Items     = Items (Items == "" ? "" : ",\n") i
        Item      = ""
        Title     = ""
        Author    = ""
        Url       = ""
        Published = ""
    }

    if (Is_reading_item) {
        Item = Item "\n" $0
    }
}
END {
    print "[\n" Items "\n]"
}

function remove_non_ascii(text) {
    gsub(/[^a-zA-Z0-9 "\.,!#\*<>()%_=:\-\\\/]/, "", text)
    return text
}

# Trims away any whitespace (i.e. space, tab, newlines, carrige-returns) from the left and right of given [string]
function trim(string) {
    sub(/^[ \t\r\n]+/,  "", string)
    sub( /[ \t\r\n]+$/, "", string)
    return string
}' | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"

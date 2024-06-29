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
        split(Published, a)
        split(a[1], d, "-")
        split(a[2], t, ":")

        Published = make_iso_datetime(d[3], d[2], d[1], t[1], t[2], t[3], "000")
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
        Item = Item "\n" a[1]

        Item = make_item(Item, Url, Title, Author, Base_url "#" Url, Published)

        Items     = Items (Items == "" ? "" : ",\n") Item
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
' | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"

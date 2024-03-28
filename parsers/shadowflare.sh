#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="${2:-.*}"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

curl --connect-timeout 10 -sL "$url" | tr '\r' '\n' | awk '
BEGIN {
    Debug = 0

    Base_url = "https://sfsrealm.hopto.org/"
    split("January February March April May June July August September October November December", month)
    for (i in month) {
        month_nums[month[i]] = i
    }

    Title     = ""
    Date      = ""
    Published = ""
    Author    = ""
    Url       = ""
    Items     = ""

    Is_reading_article = 0
}
{
    if ($0 ~ "^<center><font size=4>Current News</font><p></center>")
        Is_reading_article = 1
    if (!Is_reading_article)
        next

    match($0, /^<font face=.arial. color=.#50FFFF. size=.2.><b>(.+)<\/b><\/font><P>/, a)
    if (RSTART != 0) {
        Date = a[1]
        split(Date, a)
        sub(/,/, "", a[3])
        m = int(month_nums[a[2]])
        if (m < 10)
            m = "0" m
        Date = a[4] "-" m "-" a[3]
        if (Debug) print "Date: " Date > "/dev/stderr"
    }

    match($0, /^<td bgcolor=808080><B><A NAME="(.+)"><FONT COLOR="#FFEEDD" SIZE="2" FACE="arial">(.+)<\/FONT><\/B>/, a)
    if (RSTART != 0) {
        Url   = a[1]
        Title = a[2]
        if (Debug) print "Url: " Url ", Title: " Title > "/dev/stderr"
    }

    match($0, /^<FONT COLOR="#FFEEDD" SIZE="2" FACE="arial"> - <A HREF="[^">]*">(.+)<\/A> - ([0-9:]+)<\/FONT><\/td>/, a)
    if (RSTART != 0) {
        $0 = ""
        Author = a[1]
        Published = Date "T" a[2] ":00Z"
        if (Debug) print "Author: " Author ", Published: " Published > "/dev/stderr"
    }

    match($0, /^<FONT COLOR="#FFEEDD" SIZE="2" FACE="arial">(.+)/, a)
    if (RSTART != 0) {
        text = trim(a[1])
        gsub(/\\/, "\\\\", text)
        gsub(/"/,  "\\\"", text)
        gsub(/\t/, "    ", text)

        i = "  {\n"
        i = i "    \"id\": \"" Url "\",\n"
        i = i "    \"title\": \"" Title "\",\n"
        i = i "    \"user\": \"" Author "\",\n"
        i = i "    \"url\": \"" Base_url "#" Url "\",\n"
        i = i "    \"created\": \"" Published "\",\n"
        i = i "    \"text\": \"" text "\"\n"
        i = i "  }"

        Items     = Items (Items == "" ? "" : ",\n") i
        Title     = ""
        Author    = ""
        Url       = ""
        Published = ""
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

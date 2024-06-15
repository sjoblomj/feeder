#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

curl --connect-timeout 10 -sL "$url" | tr '\r' '\n' | tr "'" "\"" | awk -i "parsers/_common.awk" '
BEGIN {
    Debug = 0

    Base_url  = "https://sfsrealm.hopto.org/"

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

        Date = make_iso_date(a[4], a[2], a[3])
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
        split(a[2], a, ":")
        Published = combine_date_and_time(Date, a[1], a[2], "00", "000")
        if (Debug) print "Author: " Author ", Published: " Published > "/dev/stderr"
    }

    match($0, /^<FONT COLOR="#FFEEDD" SIZE="2" FACE="arial">(.+)/, a)
    if (RSTART != 0) {
        text = a[1]

        text = make_item(text, Url, Title, Author, Base_url "#" Url, Published)

        Items     = Items (Items == "" ? "" : ",\n") text
        Title     = ""
        Author    = ""
        Url       = ""
        Published = ""
    }
}
END {
    print "[\n" Items "\n]"
}
' | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"

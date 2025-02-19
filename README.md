# Feeder

![Feeder](feeder.png)

A set of scripts to parse websites for updates which are displayed in a dashboard-fashion.

The feeds of the websites that the user finds interesting can be specified in `sites.yaml`. The given sites are scraped by the given parser for updates. After all sites are scraped, a json-file is produced with all aggregated data. The `feeder.html` will display a dashboard in HTML of the results.

A useful tool to find feeds in websites is [Lighthouse Feed Finder](https://lighthouseapp.io/tools/feed-finder).

## Running

Simply update `sites.yaml` with the websites and data you find interesting. To scrape, run the `scrape.sh` script, and then open `feeder.html` in your browser.

In order to not have git bug you about `sites.yaml` being changed, you can run `git update-index --assume-unchanged sites.yaml`. To have git track the file again, run `git update-index --no-assume-unchanged sites.yaml`.

## Dashboard usage

In the dashboard, one can mark entries as "seen". By doing so, one can visually keep track of which items have been read, and any new items will be clearly visible.

All feeds will be shown in the dashboard, divided into two sections: those with updates and those without (i.e. when all the feed items have been marked as "seen").

To mark an item as read, hover over the user picture with the mouse, which will make an eye icon appear. Click it to mark that entry as "seen". To mark all items as "seen", click on the icon for the whole feed.

When a user marks items as "seen", a Save-button will appear. Save the corresponding file as `seenentries.json` next to the `feeder.html` file.

Note that if a feed item which was previously marked as "seen" is updated, it will no longer retain the marking.

## Parsers

There are a number of general parsers that are supported:

* rss - Parser for the very common RSS feed format, used all over the Internet.
* atom - Parser for the very common Atom feed format, used all over the Internet.
* github - Can parse GitHub issues and PRs, new releases and new commits to a repository. The GitHub API has a rate limit of 60 requests per hour. If set, the parser will read the `GITHUB_ACCESS_TOKEN` environment variable and use in the requests. So if you need more than 60 requests per hour, create a [GitHub Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) and specify it in the environment `GITHUB_ACCESS_TOKEN`, whereupon GitHub will increase the rate limit to 5000 requests per hour.
* gitlab - Parser for GitLab issues
* youtrack - Parser for issues on YouTrack

### Site specific
* auroramålet - Custom parser for the site auroramålet.se
* bandsintown - Custom parser for the concert API at bandsintown
* drakenhh - Custom parser for the site drakenhh.com
* femern - Custom parser for the site femern.com
* globalsolarcouncil - Custom parser for the site globalsolarcouncil.org
* gotheborg - Custom parser for the site gotheborg.se
* isof - Custom parser for the site isof.se
* railsweden - Custom parser for the site railsweden.lindholmen.se
* shadowflare - Custom parser for the site sfsrealm.hopto.org
* siedler25 - Custom parser for the site siedler25.org
* staredit - Custom parser for the site staredit.net
* stormcoast-fortress - Custom parser for the site stormcoast-fortress.net
 

## Yaml configuration

When specifying a website feed in `sites.yaml`, the following attributes are recognized:

* `name`: Required. Name of site to parse.
* `url`: Required. URL to parse from.
* `parser`: Required. Which parser to use.
* `icon`: Optional. An icon to display next to the name of the site.
* `displayUrl`: Optional. The name of the site will be clickable in the dashboard. If the `url` parameter is not suitable as link (e.g. if it leads to a RSS-feed file), then a URL to be used instead can be specified here.
* `description`: Optional. A description of the site to be displayed in the dashboard.
* `insertValues`: Optional. A list of hard-coded keys and values which will be inserted into each feed entry. Can be used e.g. if the author information or picture is missing.
* `filters`: Optional. A list of search filters which must be present for the feed entry to be considered. The title and entry text is combined and searched. The filters can be specified as regex.


Below is example configuration for the website Phoronix. Since the `url` attribute points to an RSS-feed, the `displayUrl` attribute is given as well, so that the dashboard has a link to the main site. Since (almost) all articles are written by the same author and that information is not encoded into the RSS-feed, the name and picture of the author is specified through the `insertValues`. Finally, there is a filter which specifies that the only articles to keep are those where the text or title contains "wayland" or "arch".

```
  - name: Phoronix
    url: "https://www.phoronix.com/rss.php"
    displayUrl: "https://www.phoronix.com"
    icon: "https://www.phoronix.com/android-chrome-192x192.png"
    parser: rss
    insertValues:
      - user: Michael Larabel
      - userPicture: "https://www.phoronix.com/assets/categories/michaellarabel.webp"
    filters:
      - filter: (wayland|arch)
```

## Filters

Filters can be used to remove articles from the list. The title and text of the articles will be searched.

### Simple case

The simplest case is to just give a keyword that must exist in the title or text of the article.

In the following example, only articles containing "firefox" will be kept:

```
filters:
  - filter: firefox
```

### Regular expressions

Filters support [regular expressions](https://en.wikipedia.org/wiki/Regular_expression). This allows to create powerful matching criteria.

In the following example, only articles containing "wayland" or "arch" will be kept:

```
filters:
  - filter: (wayland|arch)
```

### Boolean logic

Filters also support boolean logic, i.e. `and`, `or` and `not`. A filter consists of an arbitrary number of sections, each one level more nested than the previous. Each section must contain at most one `filter` key, and the rest of the keys on that section should be `and` or `or`.

In the following exmple, only articles containing "wayland" or "firefox" or "arch" will be kept. However, if it does contain "arch", it must not contain "march", "architect" or "research".

```
filters:
  - filter: wayland
  - or:
    - filter: firefox
  - or:
    - filter: arch
    - and:
      - not:
        - filter: march
        - or:
          - filter: architect
        - or:
          - filter: research
```

## Requirements

The scripts make use of the following programs:

* [curl](https://curl.se)
* [jq](https://github.com/jqlang/jq)
* [yq](https://github.com/mikefarah/yq)
* perl

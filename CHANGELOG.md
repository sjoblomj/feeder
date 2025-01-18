# Changelog

All notable changes to this project will be documented in this file.

## [2.3] - ???

### Removed

- Removed site specific parser: planetwild - a feed is avaiable at https://planetwild.com/blog/rss.xml
- Removed site specific parser: wardruna - a feed is available at https://wardruna.com/news/rss.xml
- Removed site specific parser: sagafarmann - page has been decommissioned



## [2.2] - 2024-12-01

### Added

- The GitHub parser now handles pagination and will fetch the latest entries rather than the first entries.

### Changed

- Filters are now case-insensitive.
- The number of columns in the Dashboard will now depend on the screen size; larger screens will have more columns.
- Adjustment to image sizes in the Dashboard.
- The Atom parser can now read titles through the `title[content]` attribute if it exists.
- The Atom parser can now read text through the `summary.div.p` attribute if there is no `content["+content"]` or `group.description` attribute.
- Fixing code warnings in the GitHub parser.
- Fixing code warnings in the awk common library.
- Fixing code warnings in the scrape script.
- Fixing code warnings in the Dashboard.



## [2.1] - 2024-07-01

### Added

- Site specific parser: sagafarmann
- Site specific parser: drakenhh
- Site specific parser: gotheborg
- Site specific parser: planetwild
- Site specific parser: siedler25
- Site specific parser: staredit
- Site specific parser: bandsintown

### Changed

- Refactored so that downloading and error handling is done in common functions.
- Refactored so that conversion of xml to json is done in common functions.
- Updated sites.yaml file to be an up to date reflection of the capabilities of the project.
- Refactored common functions for awk parsing of specific sites to be in its own file.
- Refactored ShadowFlare parser to use common awk functions.
- Refactored Stormcoast-Fortress parser to use common awk functions.
- Refactored Wardruna parser to use common awk functions.
- The YouTrack parser now only requests relevant fields.
- The GitHub parser can now read the created date through the `submitted_at` attribute.
- The Atom parser can now read text through the `group.description` attribute if there is no `content["+content"]` attribute.
- If an entry has no text, the Dashboard will display an empty string instead of "null".
- Links will have the same colour in the Dashboard regardless of if they've been opened or not.
- Refactoring and fixing code warnings.
- Added .idea to .gitignore



## [2.0] - 2024-04-18

### Added

- Filters now support boolean logic.



## [1.10] - 2024-04-14

### Changed

- Better title defaults.
- Fix to Dashboard to prevent sites from overflowing its content.



## [1.9] - 2024-04-10

### Added

- Dashboard will now gracefully handle the absense of the scraper-generated sitedata.json file and the dashboard-generated seenentries.json. When no sitedata.json file is present, a user-friendly message will be shown instead of a blank page as before.

### Changed

- Minor change of jq syntax in parsers, so the required jq version is now 1.6 instead of 1.7 as before.



## [1.8] - 2024-04-08

### Added

- Logo for the project (AI generated from the Playground-v2.5 model at poe.com).
- Support for specifying a GitHub access token in the `GITHUB_ACCESS_TOKEN` environment variable. By providing an access token, the GitHub rate limit of 60 requests per hour instead becomes 5000 requests per hour.

### Changed

- Sites without an icon will now be handled properly in the Dashboard.
- Minor stylistic changes in the Dashboard: When hovering over icons, the author text no longer makes a tiny jump.



## [1.7.1] - 2024-04-02

### Added

- .gitignore file

### Changed

- Slimming down sites.yaml, so that it is more useful as an example.
- The readme now mentions the site-specific parsers for ShadowFlare and Stormcoast-Fortress.



## [1.7] - 2024-03-29

### Added

- Added the `description` parameter in sites.yaml and Dashboard. It can be used to give a description of the sites.
- Site-specific parsers for ShadowFlare and Stormcoast-Fortress.
- This Changelog file.


### Changed

- The parsers are now resilient to network problems. They will time out after 10 seconds and will no longer result in invalid json results.
- Minor stylistic changes.



## [1.6] - 2024-03-24

### Changed

- If a specified parser cannot be found, an error message will be printed, but the produced Json will now still be valid.
- The RSS parser can now read author names through the `author` attribute if there is no `creator` attribute.
- Cleaned up Wardruna parser.



## [1.5.1] - 2024-03-20

### Added

- Added Readme file that describes the project.



## [1.5] - 2024-03-18

### Added

- Added parser for Atom feeds.
- Added a custom parser for wardruna.com. This is a specific parser only for that website, but the structure of the scraper can be adopted into other site-specific scrapers.

### Changed

- Tidying up parser code. Moving the code for filtering and capping elements through the `maxelems` and `maxtextlen` parameters into its own common function.



## [1.4] - 2024-03-16

### Added

- Added a `maxtextlen` parameter to the GitHub and RSS parsers, which will set an upper character limit to text, after which it is capped. If entries are very large, the jq scripts will fail. By using this parameter to cap the length of entries, the problem can be resolved.

### Changed

- The GitHub parser can now read `tag_name` attributes.
- Fixes to the time parsing in the RSS parser.
- Tidier structure in the GitHub and RSS parsers; logic and attribute mapping now happen on distinct lines.



## [1.3] - 2024-03-14

### Changed

- Tidying up timestamps in the Dashboard to improve readability.



## [1.2.1] - 2024-03-11

### Changed

- Some stylistic changes to the Dashboard.



## [1.2] - 2024-03-10

### Added

- Added a `displayUrl` parameter to the sites.yaml file. It will be used in the Dashboard to link back to the site being scraped. This parameter can be used for example to link to the news page of a site rather than it's RSS feed.



## [1.1] - 2024-03-09

### Changed

- The RSS parser will now read text from the `encoded` attribute if there is no `description` attribute.



## [1.0] - 2024-03-08

### Added

- Can now find parsers by file name instead of through a hard-coded list.

### Changed

- Reorganized files.



## [0.8] - 2024-03-06

### Added

- The Dashboard is now divided into two sections, one for the sites without updates (i.e. sites which have entries that have not been marked as "seen"), and one for entries with no updates since last time.

### Changed

- Cleaned up code.



## [0.7] - 2024-03-04

### Added

- Will now generate a random (but deterministic) background colour in the Dashboard, when the author does not have an icon. Previously, that fallback background colour was always the same, but it will now be different for different authors.



## [0.6] - 2024-03-02

### Added

- Crude support for filters. Search terms can be given in the sites.yaml file, and site data will only be kept if the title or text contains that search term. It supports [regex](https://en.wikipedia.org/wiki/Regular_expression).



## [0.5] - 2024-02-23

### Added

- A HTML Dashboard for showing scraped data.
- Support for specifying `insertValues` in the sites.yaml file, which can be used to insert key-values into the scraped data.

### Changed

- Writes a proper JSON file with the scraped data to disk.
- Properly passes the maximum number of elements to scrape to each parser.



## [0.4] - 2024-02-22

### Changed

- The sites.yaml file now uses the keyword `parser` for specifying which parser to use. Previously the nondescript keyword `type` was used.



## [0.3] - 2024-02-21

### Added

- Added the `maxelem` parameter to the parsers, through which one can specify the maximum number of elements to fetch from each site.

### Changed

- A little tidying up in some parsers.



## [0.2] - 2024-02-19

### Added

- The GitHub parser now contains logic to convert front-end URLs into API URLs.
- The YouTrack parser now contains logic to convert front-end URLs into API URLs.

### Changed

- The GitLab parser only sets the `updated` field if it is different from the `created` field.
- The RSS parser will sort entries by the `created` timestamp.
- Properly enabling RSS, YouTrack and GitLab parsers.



## [0.1] - 2024-02-15

### Added

- Crude first version of program. Sites to scrape can be specified in the sites.yaml file. Has support for scraping github, gitlab, youtrack and RSS.

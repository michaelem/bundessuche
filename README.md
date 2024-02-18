# README
Welcome to Bundessuche! This is a Rails application that allows users to search the [Bundesarchiv](https://www.bundesarchiv.de/). You can use it by visiting [bundessuche.de](https://bundessuche.de).
Bundessuche imports [apeEAD](http://apex-project.eu/index.php/en/outcomes/standards/apeead) formatted XML files and makes them searchable.
The search is optimized for advanced users and offers the ability to quickly skim large amounts of files.
Other options for searching the archive include [Archives Portal Europe](https://www.archivesportaleurope.net), [Archivportal-D](https://www.archivportal-d.de) and [Invenio](https://invenio.bundesarchiv.de) (which is directly linked on Bundessuche for checking out the actual archival objects).

## Ruby version
Since the deployment of this app runs on `ARM64` and there is a [bug](https://github.com/ruby/ruby/pull/9371) in Ruby `3.3.0` the Ruby version is currently pinned to `3.2.3`.

## Database
This application uses Postgresql, database creation and migration is done with the standard Rails tasks.

## Included XLM Data
The `test/fixtures/files/dataset*` folders contain excerpts of the [CC0](https://creativecommons.org/public-domain/cc0/) licensed data from the german federal archive. You can find the full dataset on [open-data.bundesarchiv.de](https://open-data.bundesarchiv.de/apex-ead/) and more information on open data program on their [website](https://www.bundesarchiv.de/DE/Content/Artikel/Ueber-uns/Aus-unserer-Arbeit/open-data.html).

## Downloading the full XML Data for import
In order to run your own instance you need the full dataset. It's available on [open-data.bundesarchiv.de](https://open-data.bundesarchiv.de/apex-ead/). Since the files are linked individually it's easiest to use an [auto downloader](https://www.downthemall.net/) to get all the data.
The default location that the importer looks for is the `data` folder, it's easiest to place your XML files there.

## License
AGPL - see the LICENSE file for details. Commercial licenses will be made available upon request.

If you would like ot use a modified version of Bundessuche in a Commercial setting please contact <info@bundessuche.de> for more information!

## Author
Michael Emhofer, [emi.industries](https://emi.industries)

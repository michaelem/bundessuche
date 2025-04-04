# README
Welcome to Bundessuche! This is a Rails application that allows users to search the [Bundesarchiv](https://www.bundesarchiv.de/). You can use it by visiting [bundessuche.de](https://bundessuche.de).
Bundessuche imports [apeEAD](http://apex-project.eu/index.php/en/outcomes/standards/apeead) formatted XML files and makes them searchable.
The search is optimized for advanced users and offers the ability to quickly skim large amounts of files.
Other options for searching the archive include [Archives Portal Europe](https://www.archivesportaleurope.net), [Archivportal-D](https://www.archivportal-d.de) and [Invenio](https://invenio.bundesarchiv.de) (which is directly linked on Bundessuche for checking out the actual archival objects).

## Database
This application uses SQLite (even in production), database creation and migration is done with the standard Rails tasks.
Make sure to mount a volume into the docker image to persist your database. The default location for this is `/rails/db/sqlite`.

## Included XLM Data
The `test/fixtures/files/dataset*` folders contain excerpts of the [CC0](https://creativecommons.org/public-domain/cc0/) licensed data from the german federal archive. You can find the full dataset on [open-data.bundesarchiv.de](https://open-data.bundesarchiv.de/apex-ead/) and more information on open data program on their [website](https://www.bundesarchiv.de/DE/Content/Artikel/Ueber-uns/Aus-unserer-Arbeit/open-data.html).

## Downloading the full XML Data for import
In order to run your own instance you need the full dataset. It's available on [open-data.bundesarchiv.de](https://open-data.bundesarchiv.de/apex-ead/). Since the files are linked individually it's easiest to use an [auto downloader](https://www.downthemall.net/) to get all the data.
The default location that the importer looks for is the `data` folder, it's easiest to place your XML files there.

## License
Bundessuche is licensed under the GNU Affero General Public License (AGPL) - see the LICENSE file for details. The AGPL is a strong copyleft license that requires you to provide the source code of a modified version of Bundessuche to users even these users only access the software via a network.

If you would like ot use a modified version of Bundessuche in a commercial setting please contact <info@bundessuche.de> for more information!

This does not cover the fonts used (found in `app/assets/fonts/`). Both covered by the [SIL Open Font License](https://openfontlicense.org). For details see the fonts section an the respective `LICENSE` file.

## Fonts
Bundessuche uses two fonts:
* [Atkinson Hyperlegible](https://brailleinstitute.org/freefont)
* [EB Garamond](http://www.georgduffner.at/ebgaramond/)

Atkinson Hyperlegible is the default font for all text and EB Garamond is used for the 'Bundessuche' title.

## Author
Michael Emhofer, [emi.industries](https://emi.industries)

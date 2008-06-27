

	Heisr

Heisr is an feed generator for www.heise.de, unfortunately heise does only
provide feeds without atom:content so you would have to visit the website to
read the full article.

Additionally some news items between heise online and heise security are
duplicated so reading both feeds results in redundant content.

Heisr solves both problems by generating one feed from which duplicate stories
are removed and into which the scraped contents of the website are injected.

Heisr comes as a camping app so you can run it as a local web application or
as a command line app which you can integrate as script feed into NetNewsWire
for example.

This will by the way mostly help people in germany which want to read heise
online over RSS...


	Dependencies

* Hpricot 
* Camping, if you want to run it as a local web app.

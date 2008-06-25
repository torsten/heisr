
	Heisr

Heisr is an feed generator for www.heise.de, unfortunately heise does only
provide feeds without atom:content so you have to visit the website to read the
article.  This is the first thing Heisr changes, it injects the content into the
feed.

Additionally some news items between heise online and heise security are duplicated so reading both feeds results in reduntant content, this is also prevented by creating one feed which combines both heise feeds and removing
duplicate entries.

So this will mostly help people in germany which want to read heise over RSS...

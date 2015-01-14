BASEDIR=$(CURDIR)
OUTPUTDIR=$(BASEDIR)/dist
GITHUB_PAGES_BRANCH=gh-pages

publish:
	mkdir -p dist/src
	cp index.html dist/index.html
	coffee src/game.coffee
	cp src/game.js dist/src/game.js
	mkdir -p dist/bower_components/Snap.svg/dist/
	cp bower_components/Snap.svg/dist/snap.svg-min.js dist/bower_components/Snap.svg/dist/snap.svg-min.js

github: publish
	ghp-import -b $(GITHUB_PAGES_BRANCH) $(OUTPUTDIR)
	git push origin $(GITHUB_PAGES_BRANCH)

.PHONY: publish github

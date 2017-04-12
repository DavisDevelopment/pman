
all: compile run

run:
	cd ../dist/ && electron .

compile:
	haxe build.hxml && cd ../dist/ && ./pack preprocess

compile-compress:
	cd ../dist/ && ./pack -compress rc pp

compile-release:
	cd ../dist/ && ./pack -compress -release rc pp

pack:
	cd ../dist/ && ./pack -compress -release pack

build-installers:
	cd ../dist/ && ./pack -compress -release installers

install_deps:
	git clone http://github.com/DavisDevelopment/tnative tannus
	git clone http://github.com/DavisDevelopment/jsgryf gryffin
	haxelib install slambda
	haxelib install actuate
	haxelib install format
	haxelib install electron
	cd ../dist/ && npm install


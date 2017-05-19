
all: compile run

run:
	@read -p "Enter pman args: " args; \
	cd ../dist/ && electron . $$args;

compile:
	haxe build.hxml workers.hxml && cd ../dist/ && ./pack preprocess

compile-compress:
	cd ../dist/ && ./pack -p linux -compress recompile preprocess

compile-release:
	cd ../dist/ && ./pack -p linux -compress -release recompile preprocess

pack:
	cd ../dist/ && ./pack -release package

build-installers:
	cd ../dist/ && ./pack -release installer

install_deps:
	git clone http://github.com/DavisDevelopment/tnative tannus
	git clone http://github.com/DavisDevelopment/jsgryf gryffin
	haxelib install slambda
	haxelib install actuate
	haxelib install format
	haxelib install electron
	cd ../dist/ && npm install


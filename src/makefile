
all: compile run

run:
	#@read -p "Enter pman args: " args; \
	#cd ../dist/ && electron . --background-only $$args;
	cd ../dist/ && electron .

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

release: compile-release
	#cd ../dist/ && ./pack recompile preprocess package installer -release -p linux -a x64
	cd ../dist/ && ./pack -p linux -a x64 -compress -release package installer

install_deps:
	git clone http://github.com/DavisDevelopment/tnative tannus
	git clone http://github.com/DavisDevelopment/jsgryf gryffin
	haxelib install slambda
	haxelib install actuate
	haxelib install format
	haxelib install electron
	cd ../dist/ && npm install


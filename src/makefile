
all: compile run

run:
	@read -p "Enter pman args: " args; \
	cd ../dist/ && electron . $$args;
	#cd ../dist/ && electron .

compile:
	haxe build.hxml workers.hxml && cd ../dist/ && ./pack preprocess

compile-compress:
	cd ../dist/ && ./pack -p linux -compress recompile preprocess

compile-release:
	cd ../dist/ && ./pack -p linux -release recompile preprocess

pack:
	cd ../dist/ && ./pack -release package

build-installers:
	cd ../dist/ && ./pack -release installer

pack-all: compile-release
	cd ../dist/ && ./pack -p linux -p windows -a x64 -release package

release: compile-release
	#cd ../dist/ && ./pack recompile preprocess package installer -release -p linux -a x64
	cd ../dist/ && ./pack -p linux -a x64 -release package installer

install_deps:
	git clone http://github.com/DavisDevelopment/tnative tannus
	git clone http://github.com/DavisDevelopment/jsgryf gryffin
	git clone http://github.com/DavisDevelopment/edis
	haxelib install slambda
	haxelib install actuate
	haxelib install format
	haxelib install electron
	cd ../dist/ && npm install


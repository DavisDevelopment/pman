
all: compile test
	#cd ../dist/ && electron .

test:
	cd ../dist/ && electron .

compile:
	haxe build.hxml && cd ../dist/ && sh build.sh

build-all:
	cd ../dist/ && bash package.sh all

build-pack:
	cd ../dist/ && bash package.sh pack

build-installers:
	cd ../dist/ && bash package.sh installers

install_deps:
	git clone http://github.com/DavisDevelopment/tnative tannus
	git clone http://github.com/DavisDevelopment/jsgryf gryffin
	haxelib install slambda
	haxelib install actuate
	haxelib install format
	haxelib install electron
	cd ../dist/ && npm install


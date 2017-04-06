
coffee -c -o buildscripts/ buildscripts/src/;

cd ../src/;
haxe -D release build.hxml;
cd ../dist/;

node buildscripts/pack.js $@;


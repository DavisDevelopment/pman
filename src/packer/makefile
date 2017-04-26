
all: compile run
	# Done

compile:
	haxe build.hxml
	cd ../../dist/ && python3 prefixer.py && chmod +x ./pack
	#cd ../../dist/ && chmod +x ./pack

run:
	cd ../../dist/ && ./pack pk i -p linux -p windows -a x64 -asar

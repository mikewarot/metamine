linux:
	cd ontleed; make linux
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	
windows:
	mkdir -p bin
	cd ontleed; make windows
	cp -r ontleed/bin/* bin/

all:
	mkdir -p bin	
	cd ontleed; make
	cp -r ontleed/bin/* bin/

web:
	cd ontleed; make web
	mkdir -p bin
	cp -r ontleed/bin/* bin/
	lua2js lex.lua > bin/lex.js
	lua2js lisp.lua > bin/lisp.js

	
	lua2js lisp.lua > bin/lisp.js
	lua2js util.lua > bin/util.js
	lua2js isoleer.lua > bin/isoleer.js
	lua2js symbool.lua > bin/symbool.js
	lua2js noem.lua > bin/noem.js
	lua2js sorteer.lua > bin/sorteer.js
	lua2js vertaal.lua > bin/vertaal.js
	lua2js func.lua > bin/func.js
	lua2js graaf.lua > bin/graaf.js
	lua2js js.lua > bin/js.js

clean:
	rm -r bin/
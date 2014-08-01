ylink
====
A linker written in D.

 tool   | description 
--------|-------------
ylink   | new linker with new custom interface|
olink   | linker that provides the same interface as optlink
mlink   | linker that provides the same interface as microsofts linker
deblink | ?
debdump | ?
map2sym | ?

Build and Test
====
Using the Makefile

    make       # Makes and runs the tests
    make tools # Makes all the tools

Using dub

    dub build --config=<tool-name>

YLINK=ylink.exe
SRC=ylink.d coffdef.d datafile.d linker.d modules.d objectfile.d omfdef.d omflibraryfile.d omfobjectfile.d paths.d pe.d relocation.d section.d sectiontable.d segment.d symbol.d symboltable.d workqueue.d

DEBLINK=deblink.exe
DEBLINKSRC=deblink.d windebug.d x86dis.d

TESTOBJ=testd.obj

default: test

$(YLINK): $(SRC)
	dmd -of$(YLINK) $(SRC)

$(DEBLINK): $(DEBLINKSRC)
	dmd -of$(DEBLINK) $(DEBLINKSRC) psapi.lib

testhello.obj: testhello.c
	dmc -c testhello.c

testd.obj: testd.d
	dmd -c testd.d

testd.exe: $(TESTOBJ)
	link /MAP $(TESTOBJ),testd.exe

teste.exe: $(TESTOBJ) $(YLINK)
	$(YLINK) $(TESTOBJ) -o teste.exe -m

test: $(YLINK) $(DEBLINK) testd.exe teste.exe
	deblink

clean:
	-del *.exe
	-del *.obj
	-del *.txt

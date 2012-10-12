YLINK=ylink.exe
SRC=ylink.d coffdef.d datafile.d linker.d modules.d objectfile.d omfdef.d omflibraryfile.d omfobjectfile.d paths.d pe.d relocation.d section.d sectiontable.d segment.d symbol.d symboltable.d workqueue.d

DEBLINK=deblink.exe
DEBLINKSRC=deblink.d windebug.d x86dis.d

default: test

$(YLINK): $(SRC)
	dmd -of$(YLINK) $(SRC)

$(DEBLINK): $(DEBLINKSRC)
	dmd -of$(DEBLINK) $(DEBLINKSRC) psapi.lib

testhello.obj: testhello.c
	dmc -c testhello.c

testd.exe: testhello.obj
	link testhello.obj,testd.exe

teste.exe: testhello.obj $(YLINK)
	$(YLINK) testhello.obj -o teste.exe

test: $(YLINK) $(DEBLINK) testd.exe teste.exe
	deblink

clean:
	-rm *.exe
	-rm *.obj
	-rm *.txt

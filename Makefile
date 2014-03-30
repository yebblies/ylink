
LINKSRC=coffdef.d datafile.d linker.d modules.d objectfile.d omfdef.d omflibraryfile.d omfobjectfile.d paths.d pe.d relocation.d section.d sectiontable.d segment.d symbol.d symboltable.d workqueue.d coffobjectfile.d cofflibraryfile.d driver.d directive.d

YLINK=ylink.exe
YLINKSRC=ylink.d $(LINKSRC)

OLINK=olink.exe
OLINKSRC=olink.d $(LINKSRC)

MLINK=mlink.exe
MLINKSRC=mlink.d $(LINKSRC)

DEBLINK=deblink.exe
DEBLINKSRC=deblink.d windebug.d

DEBDUMP=debdump.exe
DEBDUMPSRC=debdump.d x86dis.d

TESTOBJ=testd.obj
COFFOBJ=testcoff.obj

CL="c:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\bin\cl.exe"
CL_INCLUDE="c:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\include"

VC_LINK="c:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\bin\link.exe"
VC_LIB="c:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\lib"
SDK_LIB="C:\Program Files (x86)\Windows Kits\8.0\Lib\win8\um\x86"

MAP2SYM=map2sym.exe
MAP2SYMSRC=map2sym.d

PEDUMP=pedump.exe
PEDUMPSRC=pedump.d coffdef.d datafile.d codeview.d pefile.d executablefile.d debuginfo.d loadcv.d debugtypes.d

#DEBUGFLAGS=-debug=fixup -debug=OMFDATA
#DEBUGFLAGS=-debug=OMFDEBUG -debug=OMFDATA
DEBUGFLAGS=

default: test

$(YLINK): $(YLINKSRC)
	dmd -g -of$(YLINK) $(YLINKSRC) $(DEBUGFLAGS)

$(OLINK): $(OLINKSRC)
	dmd -g -of$(OLINK) $(OLINKSRC) $(DEBUGFLAGS)

$(MLINK): $(MLINKSRC)
	dmd -g -of$(MLINK) $(MLINKSRC) $(DEBUGFLAGS)

$(DEBLINK): $(DEBLINKSRC)
	dmd -g -of$(DEBLINK) $(DEBLINKSRC) psapi.lib

$(DEBDUMP): $(DEBDUMPSRC)
	dmd -g -of$(DEBDUMP) $(DEBDUMPSRC)

$(MAP2SYM): $(MAP2SYMSRC)
	dmd -g -of$(MAP2SYM) $(MAP2SYMSRC)

testc.obj: testc.c
	dmc -c testc.c -g

testd.obj: testd.d
	dmd -c testd.d -g -cov

testd.exe testd.map: $(TESTOBJ)
	link /MAP $(TESTOBJ),testd.exe/CO/NOI

teste.exe teste.map: $(TESTOBJ) $(OLINK)
	set LINK=C:\D\dmd2\windows\lib
	$(OLINK) /MAP $(TESTOBJ),teste.exe/CO/NOI

testf.exe testf.map: $(TESTOBJ) $(YLINK)
	$(YLINK) $(TESTOBJ) -o testf.exe -m

testd.sym: testd.map $(MAP2SYM)
	$(MAP2SYM) testd.map testd.sym

teste.sym: teste.map
	copy teste.map teste.sym

testf.sym: testf.map
	copy testf.map testf.sym

testcl.sym: testcl.map $(MAP2SYM)
	$(MAP2SYM) -ms testcl.map testcl.sym

testyl.sym: testyl.map
	copy testyl.map testyl.sym

testd.trace: $(DEBLINK) testd.exe
	$(DEBLINK) testd.exe -of testd.trace

teste.trace: $(DEBLINK) teste.exe
	$(DEBLINK) teste.exe -of teste.trace

testf.trace: $(DEBLINK) testf.exe
	$(DEBLINK) testf.exe -of testf.trace

testcl.trace: $(DEBLINK) testcl.exe
	$(DEBLINK) testcl.exe -of testcl.trace

testyl.trace: $(DEBLINK) testyl.exe
	$(DEBLINK) testyl.exe -of testyl.trace

testd.log: $(DEBDUMP) testd.trace testd.sym
	debdump testd.trace testd.sym testd.log

teste.log: $(DEBDUMP) teste.trace teste.sym
	debdump teste.trace teste.sym teste.log

testf.log: $(DEBDUMP) testf.trace testf.sym
	debdump testf.trace testf.sym testf.log

testcl.log: $(DEBDUMP) testcl.trace testcl.sym
	debdump testcl.trace testcl.sym testcl.log

testyl.log: $(DEBDUMP) testyl.trace testyl.sym
	debdump testyl.trace testyl.sym testyl.log

test: testd.log teste.log testf.log

$(PEDUMP): $(PEDUMPSRC)
	dmd -of$(PEDUMP) $(PEDUMPSRC) -debug=LOADPE

dump: testd.dump teste.dump

testd.dump: $(PEDUMP) testd.exe
	$(PEDUMP) testd.exe -of testd.dump

teste.dump: $(PEDUMP) teste.exe
	$(PEDUMP) teste.exe -of teste.dump

$(COFFOBJ) : testhello.c
	$(CL) /c testhello.c /Fo$(COFFOBJ) -I$(CL_INCLUDE)

testcl.exe: $(COFFOBJ)
	$(VC_LINK) /MAP:testcl.map /OUT:testcl.exe $(COFFOBJ) /LIBPATH:$(VC_LIB) /LIBPATH:$(SDK_LIB) /FIXED

testyl.exe testyl.map: $(COFFOBJ) $(MLINK)
	$(MLINK) /MAP:testyl.map /OUT:testyl.exe $(COFFOBJ) /LIBPATH:$(VC_LIB) /LIBPATH:$(SDK_LIB)

mscoff: testcl.log testyl.log

clean:
	-del *.exe
	-del *.obj
	-del *.txt
	-del *.sym
	-del *.trace
	-del *.dump
	-del *.log
	-del *.lst

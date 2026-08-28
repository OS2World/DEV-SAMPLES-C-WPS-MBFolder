#****************************************************************************
# Makefile.wat - Open Watcom build for the MbFolder Workplace Shell class
#                (OS/2 32-bit LX DLL).
#
# Project layout:
#   idl\    mbfolder.idl (interface definition)
#   h\      headers: mbids.h + sc-generated mbfolder.ih / mbfolder.h
#   src\    mbfolder.c implementation, resource script, module definition
#   doc\    documentation (README.md)
#   release build output: .obj/.res/.dll/.map/.sym
#
# Runs identically natively on OS/2 (ArcaOS Dev VM) or cross-hosted on
# Windows - same tools, same flags.
#
# PREREQUISITES (details and rationale in README.md):
#   1. Open Watcom installed; WATCOM environment variable set.
#   2. h\mbfolder.ih and h\mbfolder.h produced ONCE by the SOM compiler -
#      run genbind.cmd on the OS/2 side.  This makefile never invokes sc:
#      the real implementation is src\mbfolder.c and must NOT be overwritten
#      by sc's emitted template.
#   3. SOMINC points at a directory containing som.h, somobj.h, ...;
#      WPSINC at one containing pmwin.h, wpobject.h, wpfolder.h, ...
#      (the INCLUDE environment variable must also contain h\ for wrc,
#       which picks up mbids.h from there.)
#   4. Import libraries built by wlib from the live system DLLs:
#        wlib -n -b -q release\som.lib  +C:\OS2\DLL\som.dll
#        wlib -n -b -q release\pmwp.lib +C:\OS2\DLL\pmwp.dll
#      som.dll covers SOM runtime; pmwp.dll covers the WPFolder parent-chain
#      class-data symbols (WPFolder/WPObject ClassData/NewClass).
#      Using live DLLs avoids somtk.lib's transitive somc/some/somtc deps.
#   5. src\mbfolder.def contains the wlink OPTION DESCRIPTION (BLDLEVEL
#      string) referenced from LFLAGS via @$(MBFOLDERDEF).
#****************************************************************************

WATCOM  = $(%WATCOM)

# ---- adjust these four paths/libraries for your machine -------------------
# Defaults match the ArcaOS Dev VM (toolkit at C:\os2tk45 - same tree that
# SMINCLUDE uses for genbind.cmd).  Override without editing:
#     wmake -f Makefile.wat SOMINC=D:\path\som\include WPSINC=...
# SOMINC : som.h, somobj.h, somcdev.h, ...
SOMINC  = C:\os2tk45\som\include
# WPSINC : pmwin.h, wpobject.h, wpfolder.h, ...
WPSINC  = C:\os2tk45\h
# import library for SOM.DLL - built from the live DLL via wlib (avoids
# somtk.lib's transitive somc/some/somtc dependencies).
SOMDLL  = C:\OS2\DLL\som.dll
SOMLIB  = $(OUT)\som.lib
# Import library for WPS class-data exports (WPFolder/WPObject ClassData/
# NewClass): built from pmwp.dll via wlib.
PMWPDLL = C:\OS2\DLL\pmwp.dll
WPSLIB  = $(OUT)\pmwp.lib
# ---------------------------------------------------------------------------

HDIR    = h
SRC     = src
OUT     = release
MBFOLDERDEF = $(SRC)\mbfolder.def

CC      = wcc386
LINK    = wlink
RC      = wrc
WLIB    = wlib

# Calling-convention note: SOMLINK stays EMPTY under Watcom (somltype.h has
# no __WATCOMC__ case) - do not -d-define it (E1100 macro conflict).  Linkage
# is instead guaranteed by #pragma linkage(..., system) emitted into the
# generated bindings and used throughout the toolkit headers (sombtype.h:35,
# wpobject.h:2096, ...), which matches IBM's own header design.
CFLAGS  = -bt=os2 -bd -zq -wx -d1 &
          -I$(HDIR) -I$(SOMINC) -I$(WPSINC)

# Export set - mirrors src\mbfolder.def exactly.
EXPS    = EXP MbFolderClassData EXP MbFolderCClassData EXP MbFolderNewClass &
          EXP M_MbFolderClassData EXP M_MbFolderCClassData EXP M_MbFolderNewClass &
          EXP SOMInitModule

LFLAGS  = SYSTEM OS2V2_DLL NAME $(OUT)\mbfolder.dll &
          OP MAP=$(OUT)\mbfolder.map &
          @$(MBFOLDERDEF) &
          LIBF $(SOMLIB),$(WPSLIB) $(EXPS)

all : $(OUT)\mbfolder.dll

$(OUT)\mbfolder.obj : $(SRC)\mbfolder.c idl\mbfolder.idl $(HDIR)\mbfolder.ih $(HDIR)\mbfolder.h $(HDIR)\mbids.h
    $(CC) $(CFLAGS) $(SRC)\mbfolder.c -fo=$@

# wrc -r always writes <name>.res next to the source; relocate afterwards.
$(OUT)\mbfolder.res : $(SRC)\mbfolder.rc $(HDIR)\mbids.h
    $(RC) -r $(SRC)\mbfolder.rc
    copy $(SRC)\mbfolder.res $(OUT)
    del $(SRC)\mbfolder.res

$(OUT)\som.lib : $(SOMDLL)
    $(WLIB) -n -b -q $@ +$(SOMDLL)

$(OUT)\pmwp.lib : $(PMWPDLL)
    $(WLIB) -n -b -q $@ +$(PMWPDLL)

$(OUT)\mbfolder.dll : $(OUT)\mbfolder.obj $(OUT)\mbfolder.res $(MBFOLDERDEF) $(SOMLIB) $(WPSLIB)
    $(LINK) $(LFLAGS) FIL $(OUT)\mbfolder.obj
    $(RC) $(OUT)\mbfolder.res $(OUT)\mbfolder.dll
# No MAPSYM step: IBM mapsym rejects Watcom's map format ("Unexpected eof"),
# and .sym files are optional debug aids.

bindings : .SYMBOLIC
    @echo Run genbind.cmd on the OS/2 side once; this makefile expects
    @echo h\mbfolder.ih and h\mbfolder.h to already exist.

clean : .SYMBOLIC
    -del $(OUT)\mbfolder.obj
    -del $(OUT)\mbfolder.res
    -del $(OUT)\*.lib
    -del $(OUT)\mbfolder.dll
    -del $(OUT)\mbfolder.map
    -del $(OUT)\mbfolder.sym

#!include c:\toolkt20\c\samples\ibmsamp.inc

#****************************************************************************
#  Dot directive definition area (usually just suffixes)
#****************************************************************************

.SUFFIXES: .c .obj .dll .csc .sc .h .ih .ph .psc .rc .res

#****************************************************************************
#  Environment Setup for the component(s).
#****************************************************************************

SOMTEMP = .\somtemp
SCPATH  = C:\toolkt20\sc
HPATH   = C:\toolkt20\c\os2h
LIBPATH = C:\toolkt20\os2lib

!if [set SMINCLUDE=.;$(SCPATH);] || \
    [set SMTMP=$(SOMTEMP)] || \
    [set SMEMIT=ih;h;ph;psc;sc;c;def]
!endif

!if [cd $(SOMTEMP)]
!  if [md $(SOMTEMP)]
!    error Error creating $(SOMTEMP) directory
!  endif
!else
!  if [cd ..]
!    error Error could not cd .. from $(SOMTEMP) directory
!  endif
!endif

#
# Compiler/tools Macros
#

CC         = icc /c /Ge- /Gd- /Se /Re /ss /Ms /Gm+
#CC         = $(CC) /Ge-
LINK       = link386
LDFLAGS    = /noi /map /nol /nod /exepack /packcode /packdata /align:16
#LIBS       = som.lib os2386.lib dde4sbs.lib dde4nbs.lib
LIBS       = som.lib os2386.lib dde4nbs.lib
#LIBS       = $(DLLLIBS) som.lib

#****************************************************************************
# Set up Macros that will contain all the different dependencies for the
# executables and dlls etc. that are generated.
#****************************************************************************

OBJS       = mbfolder.obj

#****************************************************************************
#   Setup the inference rules for compiling source code to
#   object code.
#****************************************************************************

.c.obj:
        $(CC) -I$(HPATH) -c $<

.csc.c:
        sc  $<

all: mbfolder.dll

mbfolder.obj    : $*.c $*.ih $*.h  $*.sc

mbfolder.dll    : $(OBJS) mbfolder.res
         $(LINK) $(LDFLAGS) $(OBJS),$@,,$(LIBS),$*;
         rc $*.res $*.dll
         mapsym mbfolder.map

mbfolder.res: mbfolder.rc
         rc -r $*.rc $*.res


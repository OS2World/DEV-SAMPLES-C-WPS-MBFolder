# MbFolder for ArcaOS / OS/2 - Workplace Shell sample class, modernized

**Version 1.1** - ported edition of IBM Japan's 1993 *MbFolder* Workkplace
Shell sample.

`MbFolder` is a `WPFolder` subclass that adds a **menu bar** to open folder
views, letting you switch between icon and details views inside the same
window instead of opening new ones - plus a small Help menu with product
information. It was written by Toru Aihara (IBM Tokyo Research Laboratory,
1993-01-29) as one of the first published Workplace Shell programming
samples.

This edition converts the original from the long-obsolete **SOM 1.0
precompiler** format to modern **SOM IDL**, and retargets the build from IBM
C Set (`icc`/`link386`) to **Open Watcom** (`wcc386`/`wlink`/`wrc`). The
class version stays 1.1 (`majorversion = 1`, `minorversion = 1`), exactly as
the original author declared it.

| | |
|---|---|
| Original | `(C) 1993 IBM Japan / IBM Tokyo Research Laboratory, Toru Aihara` |
| Source of original | `github.com/OS2World/DEV-SAMPLES-C-WPS-MBFolder` (pristine copy kept in `orig\`) |
| This port | SOM IDL conversion + Open Watcom build system, 2026 |
| Class | `MbFolder : WPFolder`, metaclass `M_MbFolder : M_WPFolder`, DLL `mbfolder.dll` |
| Target | OS/2 2.x+ / Warp 4 / ArcaOS (32-bit LX DLL) |
| Status | Builds clean; runtime test pending on ArcaOS VM |

---

## 1. What the class does

| Method | Kind | Purpose |
|---|---|---|
| `wpMenuItemSelected` | instance override | Intercepts picks from the added menu bar. Toggling *View -> Icons/Details* re-parents the existing view in place (`parent_wpOpen` with the other `OPEN_*` constant, then swaps container attributes via `UpdateContainer`). Everything else falls through to the parent. |
| `wpOpen` | instance override | When opening contents/settings views of this folder, attaches the menu bar resource (`WinCreateMenu` with the template loaded in `wpclsInitData`) to the created frame window. |
| `wpclsInitData` | class override | On class load: obtains own module handle, loads menu template `ID_MBMENU` via `DosGetResource(RT_MENU)`; locates the class file through `_somLocateClassFile`. Calls parent first. |
| `wpclsUnInitData` | class override | On unload: frees the menu resource (`DosFreeResource`) and the module handle (`DosFreeModule`). Calls parent last. |

No new instance variables are declared, so `sc` emits no data accessors -
the methods carry no `somThis`.

## 2. Version 1.1 - what changed against the 1993 original

### 2.1 Interface definition

The original shipped as `MBFOLDER.SC`, input for the SOM 1.0 *precompiler*
(`spc` 1.22 / `emitcsc` 1.10), whose `.SC` syntax and generated artifacts no
modern toolchain accepts. It is now `idl\mbfolder.idl`:

| Original (.SC) | Port (.IDL) |
|---|---|
| `#include "wpfolder.sc"` | `#include <wpfolder.idl>` |
| `class: MbFolder;` / `parent class: WPFolder;` | `interface MbFolder : WPFolder { ... };` |
| `external prefix = mbfolder_;` | `externalprefix = mbfolder_;` |
| `class prefix = mbfoldercls_;` | `externalprefix = mbfoldercls_;` (+ `functionprefix`) on the metaclass interface |
| `file stem = MBFOLDER` / `major version = 1` / `minor version = 1` | `filestem = mbfolder; majorversion = 1; minorversion = 1;` |
| `override wpMenuItemSelected, wpOpen;` | one statement per method inside the implementation block: `wpMenuItemSelected: override; wpOpen: override;` |
| `override wpclsInitData, class;` / `wpclsUnInitData, class;` | separate metaclass `interface M_MbFolder : M_WPFolder { ... }` with `wpclsInitData: override; wpclsUnInitData: override;` (forward-declared before use) |
| C.h passthru containing unused `DebugBox` macro | dropped - dead code, never referenced |

Notes learned the hard way (see troubleshooting):
SOM IDL's override statement form is `methodname: override;` -
an `override name1, name2;` list is not valid and produces
`sc` error `"override" has not been declared`.

### 2.2 Runtime code (`src\mbfolder.c`)

1. **`zString` removed.** `wpclsInitData` used a SOM 1.x string-class object
   to receive `_somLocateClassFile`. With modern bindings the method returns
   plain `PSZ`; `SOM_IdFromString` is spelled `somIdFromString`, and the
   returned `somId` is released with `SOMFree`.
2. **PM/DOS prelude restored.** The old precompiler emitted
   `INCL_WIN`, `INCL_DOS`, `INCL_GPIBITMAPS`, `INCL_WPCLASS`,
   `INCL_WPFOLDER` + `#include <os2.h>` into its generated `.IH`
   (`orig\MBFOLDER.IH:17-23`); modern `sc` emits nothing comparable, so the
   prelude now lives at the top of `src\mbfolder.c` - required because
   `wpobject.h` pulls in `<pmstddlg.h>`, which needs the base PM types.
3. **Menu IDs rescued.** `ID_MBMENU`, `IDM_FOLDER`, `IDM_VIEW`,
   `IDM_VIEW_ICON/TREE/DETAILS`, `IDM_MYHELP`, `IDM_MYHELP_TUTORIAL`,
   `IDM_PRODUCTINFO` were emitted by the old precompiler into generated
   headers; `sc` does not emit IDs. They now live in the hand-written
   `h\mbids.h`. All sit above `WPMENUID_USER 0x6500` (`wpobject.h:230`).
4. **No-instance-data cleanups.** The old toolchain always declared
   `somThis = <Class>GetData(somSelf)` even for classes without instance
   variables; since `sc` emits no accessor here, those lines (and an unused
   `CNRINFO` local) were removed.
5. Everything else - both helper routines (`UpdateContainer`,
   `QueryDetailsView`) and the logic of all four overrides - is unchanged.

### 2.3 Module definition (`src\mbfolder.def`)

* Export set updated to what modern bindings actually define:
  `MbFolderClassData`, `MbFolderCClassData`, `MbFolderNewClass`,
  `M_MbFolderClassData`, `M_MbFolderCClassData`, `M_MbFolderNewClass`
  (verified identical to sc output), **plus `SOMInitModule`**.
* `SOMInitModule` did not exist under SOM 1.0 conventions; the modern kernel
  calls it when a class DLL is loaded. Implemented in `src\mbfolder.c` per
  IBM's own sample form (`os2tk45\samples\rexx\som\animal\sominit.c`):

      void SOMLINK SOMInitModule(integer4 majorVersion, integer4 minorVersion)

  creating the metaclass first, then the instance class.

### 2.4 Resources (`src\mbfolder.rc`)

Same menu template as 1993. Two fixes: the stale include of a non-existent
`myfolder.ih` (which only ever worked because the old generated IH happened
to carry the ID defines) now points at `..\h\mbids.h`; and the file gained
its own `#define INCL_WIN` + `<os2.h>` prelude so `wrc` sees the `MIS_*` /
`MIA_*` constants (`pmwin.h:2481/2508`).

### 2.5 Build system (new)

* `Makefile.wat` - Open Watcom build (`wcc386 -bd` -> `wlink SYSTEM
  OS2V2_DLL` -> `wrc`), replacing the original IBM NMAKE/VAC makefile.
  Links against the toolkit-shipped `somtk.lib` (covers `SOM.DLL` *and*
  the WPS class-data imports resolved to `PMWP.*`). No MAPSYM step:
  IBM `mapsym` cannot read Watcom map files.
* `genbind.cmd` - REXX harness that runs the SOM compiler once, on OS/2,
  with full logging (`release\genbind.log` summary, `release\sc_raw.log`
  raw compiler stdout+stderr via kLIBC `sh.exe`). It deliberately never
  runs from the makefile: `sc`'s emitted template `.c` would clobber the
  hand port; the template is preserved instead as
  `release\sc_mbfolder_template.c` for reference.
* `register.cmd` / `deregister.cmd` - REXX install/uninstall using
  `SysRegisterObjectClass` / `WinRegisterObjectClass` semantics and a test
  folder on the desktop.
* All text files are **CRLF** - mandatory for OS/2 REXX and expected by the
  OS/2-side tools.

### 2.6 Deliberately unchanged

Behaviour, method logic, resource IDs, class versions, and the export
surface's meaning are preserved. No behaviour change is intended anywhere
in the port.

## 3. Files

```
MBFolder-Watcom\
  README.md            this file
  Makefile.wat         Open Watcom build script (native OS/2 or cross)
  genbind.cmd          REXX: one-shot SOM compile -> h\mbfolder.ih/.h (+logs)
  register.cmd         REXX: register class + create test folder
  deregister.cmd       REXX: deregister + clean up
  idl\mbfolder.idl     converted interface definition
  h\mbids.h            menu/resource IDs (rescued from old generated headers)
  h\mbfolder.ih/.h     sc-generated bindings (created by genbind.cmd)
  src\mbfolder.c       implementation (ported)
  src\mbfolder.rc      menu bar template
  src\mbfolder.def     exports
  release\             build outputs + logs (obj/res/dll/map, genbind.log,
                       sc_raw.log, sc_mbfolder_template.c)
  orig\                pristine 1993 sources (reference only)
```

## 4. Building

Prerequisites (ArcaOS Dev VM layout assumed; toolkit at `C:\os2tk45`):

* Open Watcom (tested 2.0.1): `WATCOM` env var set, tools on PATH.
* SOM compiler (`sc.exe`) reachable - on this VM it lives in
  `C:\os2tk45\som\bin`. Do **not** rely on bare `sc`: Open Watcom ships a
  different `SC.EXE` that shadows it on PATH.
* `SMINCLUDE` containing the SOM/WPS IDL trees, e.g.
  `C:\os2tk45\h;C:\os2tk45\idl;.;C:\os2tk45\som\include`.

Steps:

```
[OS/2]  genbind                      ; once, or whenever the .idl changes
[OS/2]  wmake -f Makefile.wat        ; -> release\mbfolder.dll
```

Include paths can be overridden without editing:
`wmake -f Makefile.wat SOMINC=D:\path\som\include WPSINC=...`

## 5. Install and test

```
[OS/2]  register.cmd     ; registers MbFolder, puts "MbFolder Test" on desktop
```

Open the test folder: it must show a menu bar (*Folder / View / Help*) where
plain folders have none. *View -> Icons* vs *View -> Details* switches the
existing view in place. *Help -> Product Information* shows the 1993
credits. Uninstall with `deregister.cmd`. If the WPS misbehaves, check
`C:\POPUPLOG.OS2`.

## 6. Verification performed

* `genbind`: sc rc 0; four emitters ran; `h\mbfolder.h` (29 KB) +
  `h\mbfolder.ih` (16 KB).
* Compile: clean except one benign toolkit warning
  (`sombtype.h(41) W1177 Modifier repeated`).
* Link: zero unresolved symbols against `somtk.lib`.
* `lx_export.py` on the DLL: all seven exports present
  (`MbFolderClassData`, `MbFolderCClassData`, `MbFolderNewClass`,
  `M_MbFolderClassData`, `M_MbFolderCClassData`, `M_MbFolderNewClass`,
  `SOMInitModule`); imports only `som*`, `DOSCALLS`, `PMWIN`, `PMWP`.
* Signature audit: hand-ported override bodies match generated prototypes
  exactly (`BOOL wpMenuItemSelected(HWND, ULONG)`;
  `HWND wpOpen(HWND hwndCnr, ULONG ulView, ULONG param)` - the 1993 shapes
  survived into Toolkit 4.5's `wpfolder.idl`).

## 7. Troubleshooting (lessons encoded in this tree)

| Symptom | Cause and fix |
|---|---|
| REXX `REX0013 Error 13 ... Invalid character in program`, line 1, whole file echoed as one line | Bare-LF line endings. OS/2 REXX requires CRLF; an LF-only script is parsed as a single line. Keep every project text file CRLF. |
| `SC.EXE not found` or `Syntax error: Unterminated quoted string` from `C:/WATCOM/BINW/sc.exe` | Watcom's own `sc.exe` shadowed the SOM compiler on PATH (and kLIBC sh cannot exec it). Use the explicit path (`genbind.cmd` does). |
| sc errors about missing `wpobject.idl` / empty `SMINCLUDE` warning | Set `SMINCLUDE` to the SOM kit idl tree + Workplace Shell idl tree. |
| sc `"override" has not been declared` | Override statements must be written `methodname: override;` - not `override name1, name2;`. |
| `wcc386` E1100 `Definition of macro 'SOMLINK' not identical` | Never `-d`-define `SOMLINK`. Under Watcom it stays empty; calling convention is guaranteed by `#pragma linkage(..., system)` in the generated bindings and toolkit headers (`sombtype.h:35`, `wpobject.h:2096`). |
| `E1022 Missing or misspelled data type near 'LHANDLE'/'HWND'/...` in `pmstddlg.h` | PM base headers missing: put `INCL_WIN`/`INCL_DOS` defines + `#include <os2.h>` **before** including class bindings. |
| `wrc` E049 syntax error near `MIS_TEXT` | Same root cause in the resource pass; add the `<os2.h>` prelude to the `.rc`. |
| `mapsym: Unexpected eof reading ...map` | IBM MAPSYM cannot parse Watcom maps; intentionally skipped. Use `wdis -l` or the `.map` directly. |
| `wcc386` E062/wrc unable to open `mbids.h` | Include paths differ per tool; the `.rc` uses `..\h\mbids.h`, the C side uses `-Ih`. |

## 8. Facts verified against Toolkit 4.5 headers

* `WPMENUID_USER 0x6500` - `wpobject.h:230`
* `USAGE_OPENVIEW 5`, `VIEWITEM` - `wpobject.h:347`, `:376`
* `OPEN_CONTENTS 1` / `OPEN_SETTINGS 2` - `wpobject.h:320-321`;
  `OPEN_DETAILS 102` - `wpfolder.h:101`
* `_wpQueryFldrAttr` binding - `wpfolder.h:668-677`
* `WinCreateMenu` - `pmwin.h:2428`; `MIS_TEXT` - `pmwin.h:2481`;
  `MIA_DISABLED` - `pmwin.h:2508`
* `RT_MENU 3`, `DosGetResource`, `DosFreeResource` - `bsedos.h:2248/2286/2291`
* `CNRINFO`, `CV_*`, `CM_*` - `pmstddlg.h`
* `SOMLINK` defaulting rules - `somltype.h:57-88` (no Watcom case);
  `somMethodProc` pragma pattern - `sombtype.h:33-42`
* `SOMInitModule` role and invocation - see `som.md` "Class libraries and
  SOMInitModule"; prototype per IBM animal sample `sominit.c`

## 9. Open items

* **Runtime test pending**: register/open/exercise on the ArcaOS VM
  (build verified only up to the DLL artifact).
* Cross-build from Windows has not been attempted (paths currently default
  to the VM toolkit); override `SOMINC`/`WPSINC` when doing so.

## 10. Provenance and license

Original work and ideas: (C) 1993 IBM Japan / IBM Tokyo Research Laboratory,
Toru Aihara - see `orig\LICENSE`. This port changes build plumbing, the
interface format, and one legacy API usage; it introduces no behavioural
change. Menu-bar concept, class design, and all credit text remain the
original author's.

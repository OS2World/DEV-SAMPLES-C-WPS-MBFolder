/* genbind.cmd - REXX script. Run ONCE on the OS/2 side (ArcaOS Dev VM),
 * from the project directory, to produce h\mbfolder.ih and h\mbfolder.h
 * from idl\mbfolder.idl.
 *
 * LOGGING: summary -> release\genbind.log ; raw compiler output ->
 * release\sc_raw.log (stdout+stderr when sh.exe is available).
 *
 * NOTE: never call bare "sc" - Open Watcom ships its own SC.EXE which
 * shadows the SOM compiler on PATH (and which kLIBC sh cannot exec,
 * producing a misleading "Syntax error" from ash).  This script therefore
 * uses an explicit compiler path.
 */

/* ---------------- EDIT THIS BLOCK FOR YOUR MACHINE ---------------------
 * somBin : directory containing the SOM compiler SC.EXE
 * smIdl  : directories (semicolon-separated) holding the IDL interface
 *          files sc must find: somobj.idl, somcls.idl, somcm.idl ...
 *          and wpobject.idl, wpfsys.idl, wpfolder.idl ...  ('.' included
 *          automatically)
 * Leave a value '' to have the script try common locations. */
somBin = ''
smIdl  = ''
/* ----------------------------------------------------------------------- */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

logfile = 'release\genbind.log'
sclog   = 'release\sc_raw.log'
ih      = 'h\mbfolder.ih'
hhdr    = 'h\mbfolder.h'

call log '=== genbind start ' date() time() ' ==='
call log 'cwd       : ' directory()

/* ---- locate the SOM compiler ------------------------------------------ */
if somBin = '' then do
    candidates = 'C:\SOM\BIN D:\SOM\BIN E:\SOM\BIN' || ,
                 ' C:\IBMSOM\BIN D:\IBMSOM\BIN' || ,
                 ' C:\SOMOBJ\BIN C:\SOMOBJECTS\BIN' || ,
                 ' C:\TOOLKIT\SOM\BIN D:\TOOLKIT\SOM\BIN'
    do i = 1 while somBin = '' & i <= words(candidates)
        d = word(candidates, i)
        if stream(d'\SC.EXE', 'C', 'QUERY EXISTS') <> '' then
            somBin = d
    end
end

if somBin <> '' then
    scexe = stream(somBin'\SC.EXE', 'C', 'QUERY EXISTS')
else do
    p = SysSearchPath('PATH', 'SC.EXE')
    if pos('\WATCOM\', translate(p)) > 0 | pos('/WATCOM/', translate(p)) > 0 then
        p = ''                       /* that is Watcom's sc, not ours */
    scexe = p
end

if scexe = '' then do
    call log 'ERROR     : SOM compiler SC.EXE not found.'
    call log '            Set somBin at the top of this script to the'
    call log '            directory holding the SOM compiler and rerun.'
    call finish 8
end
call log 'sc        : ' scexe

/* ---- SMINCLUDE -------------------------------------------------------- */
cur = VALUE('SMINCLUDE', , 'OS2ENVIRONMENT')
if cur <> '' then
    call log 'SMINCLUDE : (from environment) ' cur
if smIdl <> '' then do
    x = VALUE('SMINCLUDE', smIdl';.', 'OS2ENVIRONMENT')
    call log 'SMINCLUDE : (set by script)   ' smIdl';.'
end
else if cur = '' then
    call log 'WARNING   : SMINCLUDE still empty - sc will not find somobj.idl/wpfolder.idl'

/* ---- scratch dir for sc ------------------------------------------------ */
x = VALUE('SMTMP', '.\release', 'OS2ENVIRONMENT')

call SysFileDelete sclog

/* Prefer running the compiler under sh.exe so BOTH stdout and stderr land
 * in the log (OS/2 CMD.EXE cannot redirect stderr). */
scSh = translate(scexe, '/', '\')          /* forward slashes for sh      */
shp  = SysSearchPath('PATH', 'SH.EXE')
if shp <> '' then do
    call log 'shell     : sh.exe (stdout+stderr captured)'
    ADDRESS CMD "sh.exe -c '"""scSh""" -s ""ih;h;c"" -d h -v idl/mbfolder.idl > release/sc_raw.log 2>&1'"
end
else do
    call log 'shell     : cmd.exe only (stdout captured; stderr stays on console)'
    ADDRESS CMD '"'||scexe||'" -s "ih;h;c" -d h -v idl\mbfolder.idl > release\sc_raw.log'
end
scrc = rc
call log 'sc rc     : ' scrc
call log 'raw sc out: ' sclog

/* sc -d h writes .ih/.h/.c directly into h\ - no move needed for bindings */
/* keep the emitted template .c as reference only; h\ is headers, not src  */
ADDRESS CMD 'if exist h\mbfolder.c  copy h\mbfolder.c  release\sc_mbfolder_template.c >nul'
ADDRESS CMD 'if exist h\mbfolder.c  del  h\mbfolder.c'

if stream(ih, 'C', 'QUERY EXISTS') <> '' ,
   & stream(hhdr, 'C', 'QUERY EXISTS') <> '' then do
    call log 'RESULT    : OK - h\mbfolder.ih and h\mbfolder.h written.'
    call finish 0
end
else do
    call log 'RESULT    : FAILED - bindings missing; inspect ' sclog
    call finish 12
end

finish:
    call lineout logfile          /* flush/close the log */
    exit arg(1)

log:
    parse arg msg
    call lineout logfile, msg
    say msg
    return

halt:
    say 'genbind interrupted.'
    exit 4

/* register.cmd - register the MbFolder class and create one test folder
 * on the desktop.  Run on the ArcaOS Dev VM with MBFOLDER.DLL somewhere
 * on LIBPATH (or in the current directory).
 *
 * REXX, using the RexxUtil functions that map straight onto
 * WinRegisterObjectClass / WinCreateObject.
 */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

rc = SysRegisterObjectClass('MbFolder', 'MBFOLDER')
say 'SysRegisterObjectClass("MbFolder","MBFOLDER") rc =' rc
if rc <> 1 then do
    say 'Registration failed - is MBFOLDER.DLL reachable (LIBPATH)?'
    exit 1
end

rc = SysCreateObject('MbFolder',            ,
                     'MbFolder Test',       ,
                     '<WP_DESKTOP>',        ,
                     'OBJECTID=<MBFOLDER_TEST>;', ,
                     'R')
say 'SysCreateObject rc =' rc '(1 = created, 0 = failed/exists)'
exit 0

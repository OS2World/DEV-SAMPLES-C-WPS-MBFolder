/* deregister.cmd - remove the test object and unregister the class.
 * Run on the ArcaOS Dev VM.
 */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

rc = SysDestroyObject('<MBFOLDER_TEST>')
say 'SysDestroyObject(<MBFOLDER_TEST>) rc =' rc

rc = SysDeregisterObjectClass('MbFolder')
say 'SysDeregisterObjectClass("MbFolder") rc =' rc
exit 0

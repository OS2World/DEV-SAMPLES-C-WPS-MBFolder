/* mk.cmd - run wmake and capture ALL output (stdout+stderr) into
 * release\wmake.log.  Run on the VM from the project directory.
 */

logfile = 'release\wmake.log'

'wmake -f Makefile.wat clean'

'wmake -f Makefile.wat > ' || logfile || ' 2>&1'
rcx = rc

say ''
say 'wmake rc =' rcx
if rcx = 0 then
    say 'BUILD OK - see release\mbfolder.dll'
else do
    say 'BUILD FAILED - full output in' logfile
end
exit rcx

@echo off

REM --------DETECT FILES------------
 
set putty=0
set pscp=0
set script=0
set webpage=0

set "putty_path="
set "pscp_path="
set "script_path="
set "webpage_path="

if exist "%cd%\putty.exe" (
	set putty=1
	set "putty_path=%cd%\putty.exe"
)
if exist "%cd%\pscp.exe" (
	set pscp=1
	set "pscp_path=%cd%\pscp.exe"
)
if exist "%cd%\FreshJR_QOS.sh" (
	set script=1
	set "script_path=%cd%\FreshJR_QOS.sh"
)
if exist "%cd%\FreshJR_QoS_Stats.asp" (
	set webpage=1
	set "webpage_path=%cd%\FreshJR_QoS_Stats.asp"
)

set /a "files=%putty%+%pscp%+%script%+%webpage%"
set /a "exectuables=%putty%+%pscp%"

REM --------OUTPUT FILE DETECTION------------

cls
echo Detecting if files are present in current folder
echo:

if %script%==1 (
	echo   [x] FreshJR_QOS.sh          %script_path%
) else (
	echo   [ ] FreshJR_QOS.sh           %cd%\FreshJR_QOS.sh NOT detected
)

if %webpage%==1 (
	echo   [x] FreshJR_QoS_Stats.asp   %webpage_path%
) else (
	echo   [ ] FreshJR_QoS_Stats.asp   %cd%\FreshJR_QoS_Stats.asp NOT detected
)
if %putty%==1 (
	echo   [x] putty.exe               %putty_path%
) else (
	echo   [ ] putty.exe               %cd%\putty.exe NOT detected
)

if %pscp%==1 (
	echo   [x] pscp.exe                %pscp_path%
) else (
	echo   [ ] pscp.exe                %cd%\pscp.exe NOT detected
)

echo:

if not %files%==4 (
	echo  Not all files detected
	echo  --CANNOT CONTINUE^!^!--
	echo:
	if not %exectuables%==2 (
		echo --------------------------------------------------------------------------
		echo   Putty / Pscp portable BINARY FILES are located at the following link:
		echo:
		echo     https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
		echo ---------------------------------------------------------------------------
		echo:
	)
	pause
	exit
) 

if exist "%cd%\scripts\" (
	echo Remove the folder "scripts" in current directory
	echo  --CANNOT CONTINUE^!^!--
	echo:
	pause
	exit
)

if exist "%cd%\ssh_command" (
	echo Remove the file "ssh_command" in current directory
	echo  --CANNOT CONTINUE^!^!--
	echo:
	pause
	exit
)

REM --------PROMPT USER INPUT------------

echo Getting router login information
echo:	
set /p "user=.  Router username:  "
set /p "pass=.  Router password:  "
set /p "  ip=.  Router ipaddress: "
echo:	

echo Transferring files onto the router
echo:	
mkdir "%cd%\scripts\"
pscp -r -pw %pass% -scp "%cd%\scripts" %user%@%ip%:/jffs/
rmdir "%cd%\scripts\"
pscp -pw %pass% -scp "%webpage_path%" %user%@%ip%:/jffs/scripts/www_FreshJR_QoS_Stats.asp
pscp -pw %pass% -scp "%script_path%" %user%@%ip%:/jffs/scripts/FreshJR_QOS
echo:	
echo Starting script installer
echo:	
echo dos2unix /jffs/scripts/FreshJR_QOS ^&^& sh /jffs/scripts/FreshJR_QOS -install ^&^& read -n 1 -s -r -p "(Press any key to Exit)" > ssh_command
putty.exe -ssh %user%@%ip% -pw %pass% -m "%cd%\ssh_command" -t
del "%cd%\ssh_command"

pause

@echo off

:: ---------------------------------------------------------------------------------------
:: The MIT License (MIT)
:: 
:: Copyright (c) 2014 cyanfr@github
:: 
:: Permission is hereby granted, free of charge, to any person obtaining a copy
:: of this software and associated documentation files (the "Software"), to deal
:: in the Software without restriction, including without limitation the rights
:: to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
:: copies of the Software, and to permit persons to whom the Software is
:: furnished to do so, subject to the following conditions:
:: 
:: The above copyright notice and this permission notice shall be included in all
:: copies or substantial portions of the Software.
:: 
:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
:: AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
:: LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
:: OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
:: SOFTWARE.
:: ---------------------------------------------------------------------------------------
::
:: Batch file for Tableau Server 8.2+.
::
:: Purpose
:: To allow for easy dynamic scripting of Active Directory group sync into Tableau Server.
::
:: It is written to echo lots of info to a log file for debug.
::
:: It also assumes you have created certain directories on your Tableau server
:: where the actual bat files that you might want to run as scheduled Windows tasks.
:: C:\tableau\tableau_tasks\ad_sync
:: C:\tableau\tableau_tasks\ad_sync\logs
:: C:\tableau\tableau_tasks\ad_sync\lists
:: 
:: Explanation
:: If your Tableau Server environment is using Active Directory for authentication,
:: one of the useful features is to import and keep in sync groups from AD inside Tableau Server.
:: This allows you to grant the owner of the group in AD who can add and delete users to that group
:: to also, by extension of this sync script, control the corresponding group in Tableau Server.
:: This should server alleviate a bit of burden from the Tableau Server admins.
::
:: Requirements
:: A Tableau Server environment attached to Active Directory for Authentication.
:: The credential of the AD user you use in the Tableau Server config to connect to AD.
:: The ability to schedule and run scripts on the Tableau Server at elevated authority.
::
:: Usage
:: This batch file requires that several .lst files exist in a directory at the level of this batch file.
:: So if batch file is at: D:\tableau\tableau_tasks\ad_sync
:: the .lst files should be in D:\tableau\tableau_tasks\ad_sync\lists
:: default.lst is required.  It should contain the list of AD groups you wish to sync in the Tableau Server default site.
:: One AD group name per line.  See example in this repo.
:: sites.lst is required.  It should include the list of sites OTHER THAN DEFAULT that have other AD groups you need to keep in sync.
:: One Tableau site ID per line.
::
:: default.lst = list of AD groups to sync in default site.  One group per line.
:: sites.lst = list of Tableau Site IDs that also contain AD groups to keep in sync.
:: <site id>.lst = possibly multiple files.  Each one is equal to a line in the sites.lst file and contains the AD groups to sync in that site.
::
:: For each site in the sites.lst file, you also need a file named for each line in the sites.lst file.
:: So for example if your sites.lst file contains three lines with the values sales, finance, and hr, you should also
:: have three files in the same dir named sales.lst, fiancne.lst, hr.lst.
:: The script loops through the lines in sites.lst and then through each corresponding sites file for the actual groups to sync in each site.
:: Edit the values of the variables in the section below titles "START EDITING HERE" to reflect your Tableau Server environment.
:: Use Control Panel > Administrative Tools > Task Scheduler to set up regular recurring times to run this script or run it as administrator at any time.
:: Batch file must be run as administrator.

::set up useful date time keys
for /F "TOKENS=1* DELIMS= " %%A IN ('DATE/T') DO SET CDATE=%%B
for /F "TOKENS=1,2 eol=/ DELIMS=/ " %%A IN ('DATE/T') DO SET mm=%%B
for /F "TOKENS=1,2 DELIMS=/ eol=/" %%A IN ('echo %CDATE%') DO SET dd=%%B
for /F "TOKENS=2,3 DELIMS=/ " %%A IN ('echo %CDATE%') DO SET yyyy=%%B
for /F "TOKENS=1 DELIMS=: " %%h in ('time /T') do set hour=%%h
for /F "TOKENS=2 DELIMS=: " %%m in ('time /T') do set minutes=%%m
set dt_key=%yyyy%%mm%%dd%
set ts_key=%yyyy%%mm%%dd%-%hour%%minutes%
set date_string=%mm%/%dd%/%yyyy%

:: set day of week number
for /f %%a in ('wmic path win32_localtime get dayofweek /format:list ^| findstr "="') do (set %%a)
set dow_num=%dayofweek%

::----------------------------------------
:: START EDITING HERE
::----------------------------------------
::SETUP VARS
set install_drive=C:
set bin_loc="C:\tableau\tableauserver\8.2\bin"
set usr=<Tableau user that runs tableau server>
set pwd=<password>
set svr=http://localhost
set site=all

set script_drive=C:
set script_dir=C:\tableau\tableau_tasks\ad_sync
set script_lists_dir=%script_dir%\lists
set defaultlst=%script_lists_dir%\default.lst
set siteslst=%script_lists_dir%\sites.lst

set log_dir=D:\tableau\tableau_tasks\ad_sync\logs
set log_file=ad_sync
set log_ext=log
set log=%log_dir%\%log_file%-%dt_key%-all.%log_ext%
::----------------------------------------
:: STOP EDITING HERE
::----------------------------------------

echo install_drive = %install_drive% > %log%
echo bin_loc = %bin_loc% >> %log%
echo usr = %usr% >> %log%
echo svr = %svr% >> %log%
echo site = %site% >> %log%
echo. >> %log%

echo script_drive = %script_drive% >> %log%
echo script_dir = %script_dir% >> %log%
echo script_lists_dir = %script_lists_dir% >> %log%
echo defaultlst = %defaultlst% >> %log%
echo siteslst = %siteslst% >> %log%
echo. >> %log%

echo log_dir = %log_dir% >> %log%
echo log_file = %log_file% >> %log%
echo log_ext = %log_ext% >> %log%
echo log  = %log% >> %log%
echo. >> %log%

::go to tabcmd home, change this to wherever you have tableau server installed
%install_drive%
cd %bin_loc%

::*********************************
::SYNCING DEFALT SITE
::*********************************
echo ******AD Synch STARTING %date%:%time%****** >> %log%
echo. >> %log%

echo ***logging in to Default site*** >> %log%
echo tabcmd login -u %usr% -p %pwd% -s %svr% --no-certcheck >> %log%
tabcmd login -u %usr% -p %pwd% -s %svr% --no-certcheck >> %log%
echo. >> %log%

::SYNC GROUPS on Default site, COPY THESE FOR EVERY GROUP YOU WISH TO SYNC
echo ***syncing groups on Default site*** >> %log%

setlocal EnableDelayedExpansion
FOR /F "tokens=*" %%i IN (!defaultlst!) DO (
set group=%%i
echo tabcmd syncgroup "!group!" --license interactor --publisher -u !usr! -p !pwd! -s !svr! --no-certcheck >> !log!
tabcmd syncgroup "!group!" --license interactor --publisher -u !usr! -p !pwd! -s !svr! --no-certcheck >> !log!
)
setlocal DisableDelayedExpansion

echo ***finished syncing groups on default site*** >> %log%
echo tabcmd logout >> %log%
tabcmd logout >> %log%

echo ******Default AD Synch finishing %date%:%time%****** >> %log%

echo. >> %log%

::*********************************
::SYNCING ALL OTHER SITES
::*********************************

setlocal EnableDelayedExpansion
FOR /F "tokens=*" %%s IN (!siteslst!) DO (
    set sitevar=%%s
    set sitevarfile=!script_lists_dir!\!sitevar!.lst
    echo ******!sitevar! AD Synch STARTING !date!:!time!****** >> !log!
    echo ***logging in to !sitevar! site*** >> !log!
	echo tabcmd login -u !usr! -p !pwd! -s !svr! -t !sitevar! --no-certcheck >> !log!
    tabcmd login -u !usr! -p !pwd! -s !svr! -t !sitevar! --no-certcheck >> !log!
    echo. >> %log%
    
	REM SYNC GROUPS on uncertified site, COPY THESE FOR EVERY GROUP YOU WISH TO SYNC
    echo ***syncing groups on !sitevar! site*** >> !log!

    FOR /F "tokens=*" %%g IN (!sitevarfile!) DO (
        set group=%%g
        echo tabcmd syncgroup "!group!" --license interactor --publisher -u !usr! -p !pwd! -s !svr! -t !sitevar! --no-certcheck >> !log!
		tabcmd syncgroup "!group!" --license interactor --publisher -u !usr! -p !pwd! -s !svr! -t !sitevar! --no-certcheck >> !log!
    )

    echo ***finished syncing groups on !sitevar! site*** >> !log!
    echo tabcmd logout >> !log!
	tabcmd logout >> !log!

    echo ******!sitevar! site AD Synch finishing !date!:!time!****** >> !log!
    echo. >> !log!
    echo. >> !log!
)
setlocal DisableDelayedExpansion

echo Done! >> %log%

GOTO End

:End

exit
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
:: The purpose of this batch file is to create and keep a continuously rolling 7 days of full Tableau Server system backups.
:: 
:: It is written to echo lots of info to a log file for debug.
::
:: It also assumes you have created certain directories on your Tableau server
:: where the actual bat files that you might want to run as scheduled Windows tasks.
:: C:\tableau\tableau_tasks\backup
:: C:\tableau\tableau_tasks\backup\logs
:: C:\tableau\tableau_tasks\backup\backup_files

:: Explanation
:: So for example the Sunday backup will have the name tableau_prod_daily_backup_0.tsbak.
:: The following Sunday's file will have the same name and so when copied to the network drive per the script,
:: it will over-write the one from the previous week.
:: This could easily be altered to retain continuous backups by day by using the dt_key variable instead of dow_num.
::
:: Requirements
:: Sufficient local drive space for 7 days of backups.
:: Access to an off-box network drive for a second copy of the backup files.
:: Space on the network drive for 7 days of backups.
:: An Amazon AWS S3 account.
:: The AWS CLI installed on the server:  https://aws.amazon.com/cli/
:: The ability to schedule and run scripts on the Tableau Server at elevated authority.
::
:: Usage
:: Edit the values of the variables in the section below titles "START EDITING HERE" to reflect your Tableau Server environment.
:: Use Control Panel > Administrative Tools > Task Scheduler to set up a regular daily time to run this script or run it as administrator at any time.
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
set curr_dir=C:
set usr=<Tableau user that runs tableau server>
set pwd=<password>
set svr=http://localhost
set tab_drive=C:
set bin_dir=C:\tableau\tableauserver\8.2\bin

set script_drive=C:
set script_dir=C:\tableau\tableau_tasks\backup
set log_dir=%script_dir%\logs
set backup_dir=%script_dir%\backup_files

set file_name=tableau_daily_backup_%dow_num%
set log_ext=log
set log=%log_dir%\%file_name%.%log_ext%
set backup_name=%file_name%.tsbak
set from_dir=%bin_dir%
set to_dir=<absolute path to an accessible network drive directory off box>

:: AWS SETUP
set AWS_ACCESS_KEY_ID=_YOUR_AWS_ACCESS_KEY_HERE_
set AWS_SECRET_ACCESS_KEY=_YOUR_AWS_SECRET_KEY_HERE_
set aws_bin=C:\Program Files\Amazon\AWSCLI
set s3_dir=s3://<your s3 bucket name>/<a folder inside your s3 bucket>/
::----------------------------------------
:: STOP EDITING HERE
::----------------------------------------

::ECHO VARS
echo dt_key = %dt_key% > %log%
echo dow_num=%dow_num% >> %log%
echo curr_dir = %curr_dir% >> %log%
echo usr = %usr% >> %log%
echo svr = %svr% >> %log%
echo tab_drive = %tab_drive% >> %log%
echo bin_dir = %bin_dir% >> %log%
echo. >> %log%

echo script_drive = %script_drive% >> %log%
echo script_dir = %script_dir% >> %log%
echo log_dir = %log_dir% >> %log%
echo backup_dir = %backup_dir% >> %log%
echo. >> %log%

echo file_name = %file_name% >> %log%
echo log_ext = %log_ext% >> %log%
echo log = %log% >> %log%
echo backup_name = %backup_name% >> %log%
echo from_dir = %from_dir% >> %log%
echo to_dir = %to_dir% >> %log%

echo aws_bin = %aws_bin% >> %log%
echo s3_dir = %s3_dir% >> %log%
echo. >> %log%

::change drives
echo %tab_drive% >> %log%
%tab_drive%

::go to tabcmd home, change this to wherever you have tableau server installed
echo cd %bin_dir% >> %log%
cd %bin_dir%
echo. >> %log%

echo ******Backup STARTING %date%:%time%****** >> %log%
echo tabadmin cleanup >> %log%
tabadmin cleanup
echo tabadmin backup %file_name% -d >> %log%
tabadmin backup %file_name%
echo ******Backup FINISHING %date%:%time%****** >> %log%
echo. >> %log%

echo ******Copying backup to network drive %date%:%time%****** >> %log%
echo copy /Y %backup_name% %to_dir% >> %log%
copy /y %backup_name% %to_dir%
echo ******Copying backup to AWS S3 %date%:%time%****** >> %log%
echo cd %aws_bin% >> %log%
cd %aws_bin%
echo aws s3 cp %bin_dir%\%backup_name% %s3_dir% >> %log%
aws s3 cp %bin_dir%\%backup_name% %s3_dir%
echo cd %bin_dir% >> %log%
cd %bin_dir%
echo ******Backup copied %date%:%time%****** >> %log%
echo. >> %log%

echo ******Moving backup %date%:%time%****** >> %log%
echo move /Y %backup_name% %backup_dir% >> %log%
move /y %backup_name% %backup_dir%
echo ******Backup moved %date%:%time%****** >> %log%
echo. >> %log%

echo cd %curr_dir% >> %log%
cd \

exit
@echo off

:: ---------------------------------------------------------------------------------------
:: The MIT License (MIT)
:: 
:: Copyright (c) 2014 Andrew Meserole
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
:: The purpose of this batch file is to provide a way to
:: export a multi-tab workbook to PDF format and to
:: automatically email the result as an attachment.
:: 
:: It is written to echo all commands and output to a log file for debug.
::
:: It also assumes you have created certain directories on your Tableau server
:: where the actual bat files that you might want to run as scheduled Windows tasks.
:: C:\Program Files\Tableau\Tableau Server\tableau_tasks
:: C:\Program Files\Tableau\Tableau Server\tableau_tasks\logs
:: C:\Program Files\Tableau\Tableau Server\tableau_exports
::
:: It also assumes you have febooti command line email utility installed.
:: See here for info: http://www.febooti.com/products/command-line-email/
:: This is a very affordable tool and super easy to install.
:: Approx. $160 for 1 corporate license + 3 years maintenance as of August 2014.
::
:: It also uses information gleaned from these Tableau Support pages:
:: http://onlinehelp.tableausoftware.com/v8.2/server/en-us/tabcmd_cmd.htm#id7cb8d032-a4ff-43da-9990-15bdfe64bcd0
:: http://kb.tableausoftware.com/articles/knowledgebase/using-tabcmd
:: 
:: You should be able to easily modify this script to export csv or png.
:: There are several of switches you can alter to control page layout and size.
::
:: After you have made your changes, you can schedule it via Windows Server Task Scheduler.
:: Be sure to schedule to run with elevated permissions to avoid problems.

:: START EDITING HERE!

::setup date time key
for /F "TOKENS=1* DELIMS= " %%A IN ('DATE/T') DO SET CDATE=%%B
for /F "TOKENS=1,2 eol=/ DELIMS=/ " %%A IN ('DATE/T') DO SET mm=%%B
for /F "TOKENS=1,2 DELIMS=/ eol=/" %%A IN ('echo %CDATE%') DO SET dd=%%B
for /F "TOKENS=2,3 DELIMS=/ " %%A IN ('echo %CDATE%') DO SET yyyy=%%B
for /F "TOKENS=1 DELIMS=: " %%h in ('time /T') do set hour=%%h
for /F "TOKENS=2 DELIMS=: " %%m in ('time /T') do set minutes=%%m
set dt_key=%yyyy%%mm%%dd%
set ts_key=%yyyy%%mm%%dd%-%hour%%minutes%
set date_string=%mm%/%dd%/%yyyy%

:: THIS SETUP VAR SECTION IS THE ONLY PLACE YOU SHOULD NEED TO MAKE CHANGES.
:: But you MUST check them all.  The ones below are either for examples or stubs.
:: SETUP VARS
:: This set variable section is the only place you should need to make changes to export and email PDFs.
:: Note I install Tableau Server not to Program Files/Tableau Server but to a path with no spaces in the name.
:: There are a variety of odd-ball situations that can cocur that are caused by having spaces in the path.
set tableau_drive=C:
set tableau_root=C:\tableau\tableauserver
set tableau_bin_dir="%tableau_root%\8.2\bin"
set script_drive=C:
set script_root=C:
set script_dir=%script_root%\tableau_tasks
set usr=<Put your username here. Remove the brackets of course.>
set pwd="<Put your password here.  Keep the double quotes!>"
set svr="https://your.tableau.host"
:: or possibly set svr="http://your.tableau.host"
:: or maybe with ssl.  So set svr="https://your.tableau.host"
::
:: If workbook is in default site,
:: site variable should be left empty
:: Otherwise set like this...
:: set site=-t <site name>
:: So for default.
set site=
:: For another site such as Sales
:: set site=-t Sales
set log_dir=%script_dir%\logs
set log_file=report_log
set log_ext=log
set log="%log_dir%\%log_file%-%dt_key%.%log_ext%"
set report_admin=some.email.addr.you.choose@yourcompany.com
:: report_loc is the workbook in Tableau.
:: Format is <Workbook-Name>/<Name-of-First-Tab>.
:: You can figure this out by just navigating to the workbook
:: in a browser and checking the path.
set report_loc="Workbook/FirstTab"
set export_dir=%script_root%\tableau_exports
set report=report_name_%dt_key%.pdf
:: Formatting options for export vars.
:: Format choices are --csv, --pdf, --png, --fullpdf.
set format=--fullpdf
:: Pagelayout choices are landscape, portrait.
set pagelayout=--pagelayout portrait
:: Pagesize options are letter, legal, note folio, tabloid, ledger, statement, executive, a3, a4, a5, b4, b5, quatro
set pagesize=--pagesize letter
:: Email related vars.
set attachment="%export_dir%\%report%"
set smtp_server=smtp.yourcompany.com
set from_email=some.email.addr@yourcompany.com
:: At least one of to_email, cc_email, bcc_email is required.
:: But any of them can just be left empty.
::set to_email=
set to_email=-TO "some-email-address@company-aye.com; some-other-mail-address@company-bee.com"
set cc_email=
set bcc_email=-BCC "%report_admin%"
set email_subject=-SUBJECT "Your report for %date_string%."
set email_body=-BODY "Please find attached your report for %date_string%.  Please direct question to %from_email%."

:: STOP EDITING HERE!

echo ---------------------------------------------- > %log%
echo ---------- variables ------------------------- >> %log%
echo ---------------------------------------------- >> %log%
echo dt_key          = %dt_key% >> %log%
echo ts_key          = %ts_key% >> %log%
echo date_string     = %date_string% >> %log%
echo tableau_drive   = %tableau_drive% >> %log%
echo tableau_root    = %tableau_root% >> %log%
echo tableau_bin_dir = %tableau_bin_dir% >> %log%
echo script_drive    = %script_drive% >> %log%
echo script_dir      = %script_dir% >> %log%
echo usr             = %usr% >> %log%
echo svr             = %svr% >> %log%
echo site            = %site% >> %log%
echo log_dir         = %log_dir% >> %log%
echo log_file        = %log_file% >> %log%
echo log_ext         = %log_ext% >> %log%
echo log             = %log% >> %log%
echo report_admin    = %report_admin% >> %log%
echo report_loc      = %report_loc% >> %log%
echo export_dir      = %export_dir% >> %log%
echo report          = %report% >> %log%
echo format          = %format% >> %log%
echo pagelayout      = %pagelayout% >> %log%
echo pagesize        = %pagesize% >> %log%
echo attachment      = %attachment% >> %log%
echo smtp_server     = %smtp_server% >> %log%
echo from_email      = %from_email% >> %log%
echo to_email        = %to_email% >> %log%
echo cc_email        = %cc_email% >> %log%
echo bcc_email       = %bcc_email% >> %log%
echo email_subject   = %email_subject% >> %log%
echo email_body      = %email_body% >> %log%
echo. >> %log%
echo. >> %log%

echo ----------------------------------------------- >> %log%
echo ---------- change to Tableau bin dir ---------- >> %log%
echo ----------------------------------------------- >> %log%
%tableau_drive% >> %log%
cd %tableau_bin_dir% >> %log%
echo Current location check: %CD% >> %log%
echo. >> %log%
echo. >> %log%

echo ------------------------------------------------ >> %log%
echo ---------- logging in to tableau site ---------- >> %log%
echo ------------------------------------------------ >> %log%
echo tabcmd login -u %usr% -p %pwd% -s %svr% %site% --no-certcheck >> %log%
tabcmd login -u %usr% -p %pwd% -s %svr% %site% --no-certcheck >> %log%
echo. >> %log%
echo. >> %log%


echo ------------------------------------------------ >> %log%
echo ---------- export the report ------------------- >> %log%
echo ------------------------------------------------ >> %log%
echo tabcmd export %site% %report_loc% %format% %pagelayout% %pagesize% -f %attachment% >> %log%
tabcmd export %site% %report_loc% %format% %pagelayout% %pagesize% -f %attachment% >> %log%
echo. >> %log%
echo. >> %log%

echo ------------------------------------------------ >> %log%
echo ---------- email the report -------------------- >> %log%
echo ------------------------------------------------ >> %log%
echo febootimail.exe -SMTP %smtp_server% -FROM %from_email% %to_email% %cc_email% %bcc_email% %email_subject% -ATTACH %attachment% %email_body% >> %log%
febootimail.exe -SMTP %smtp_server% -FROM %from_email% %to_email% %cc_email% %bcc_email% %email_subject% -ATTACH %attachment% %email_body% >> %log%
echo. >> %log%
echo. >> %log%

echo ------------------------------------------------ >> %log%
echo ---------- logging in to Default site ---------- >> %log%
echo ------------------------------------------------ >> %log%
echo tabcmd logout >> %log%
tabcmd logout >> %log%
echo. >> %log%
echo. >> %log%

exit
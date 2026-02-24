@echo off
set "outputFile=%~dp0collected_files.txt"

:: Clear or create the output file
type nul > "%outputFile%"

:: Search for .md, .sh, and .txt files recursively from C:\
for /r "C:\" %%F in (*.md *.sh *.txt) do (
    if /I not "%%~fF"=="%outputFile%" (
        echo ================================================================================ >> "%outputFile%"
        echo FILE: %%~nxF >> "%outputFile%"
        echo PATH: %%~fF >> "%outputFile%"
        echo ================================================================================ >> "%outputFile%"
        type "%%F" >> "%outputFile%" 2>nul
        echo. >> "%outputFile%"
        echo. >> "%outputFile%"
    )
)

echo Done! Output saved to %outputFile%
pause
@echo off
rem *** Author: T. Wittrock, Kiel ***

setlocal enabledelayedexpansion

if not exist "%TEMP%\msxsl.exe" .\bin\wget.exe -N -i .\static\StaticDownloadLink-msxsl.txt -P "%TEMP%"
if not exist "%TEMP%\wsusscn2.cab" (
  .\bin\wget.exe -N -i .\static\StaticDownloadLinks-wsus.txt -P "%TEMP%"
  if exist "%TEMP%\wuredist.cab" del "%TEMP%\wuredist.cab"
  if exist "%TEMP%\WindowsUpdateAgent30-x64.exe" del "%TEMP%\WindowsUpdateAgent30-x64.exe"
  if exist "%TEMP%\WindowsUpdateAgent30-x86.exe" del "%TEMP%\WindowsUpdateAgent30-x86.exe"
)
if exist "%TEMP%\package.cab" del "%TEMP%\package.cab"
if exist "%TEMP%\package.xml" del "%TEMP%\package.xml"
%SystemRoot%\system32\expand.exe "%TEMP%\wsusscn2.cab" -F:package.cab "%TEMP%"
%SystemRoot%\system32\expand.exe "%TEMP%\package.cab" "%TEMP%\package.xml"
del "%TEMP%\package.cab"

"%TEMP%\msxsl.exe" "%TEMP%\package.xml" .\xslt\ExtractUpdateRevisionIds.xsl -o "%TEMP%\ValidUpdateRevisionIds.txt"
"%TEMP%\msxsl.exe" "%TEMP%\package.xml" .\xslt\ExtractSupersedingRevisionIds.xsl -o "%TEMP%\SupersedingRevisionIds.txt"
%SystemRoot%\system32\findstr.exe /L /G:"%TEMP%\SupersedingRevisionIds.txt" "%TEMP%\ValidUpdateRevisionIds.txt" >"%TEMP%\ValidSupersedingRevisionIds.txt"
rem del "%TEMP%\ValidUpdateRevisionIds.txt"
rem del "%TEMP%\SupersedingRevisionIds.txt"
"%TEMP%\msxsl.exe" "%TEMP%\package.xml" .\xslt\ExtractSupersededUpdateRelations.xsl -o "%TEMP%\SupersededUpdateRelations.txt"
%SystemRoot%\system32\findstr.exe /L /G:"%TEMP%\ValidSupersedingRevisionIds.txt" "%TEMP%\SupersededUpdateRelations.txt" >"%TEMP%\ValidSupersededUpdateRelations.txt"
rem del "%TEMP%\SupersededUpdateRelations.txt"
rem del "%TEMP%\ValidSupersedingRevisionIds.txt"
"%TEMP%\msxsl.exe" "%TEMP%\package.xml" .\xslt\ExtractBundledUpdateRelationsAndFileIds.xsl -o "%TEMP%\BundledUpdateRelationsAndFileIds.txt"
%SystemRoot%\system32\cscript.exe //Nologo //B //E:vbs .\cmd\ExtractIdsAndFileNames.vbs "%TEMP%\ValidSupersededUpdateRelations.txt" "%TEMP%\ValidSupersededRevisionIds.txt" /firstonly
rem del "%TEMP%\ValidSupersededUpdateRelations.txt"
%SystemRoot%\system32\findstr.exe /L /G:"%TEMP%\ValidSupersededRevisionIds.txt" "%TEMP%\BundledUpdateRelationsAndFileIds.txt" >"%TEMP%\SupersededRevisionAndFileIds.txt"
rem del "%TEMP%\ValidSupersededRevisionIds.txt"
rem del "%TEMP%\BundledUpdateRelationsAndFileIds.txt"
%SystemRoot%\system32\cscript.exe //Nologo //B //E:vbs .\cmd\ExtractIdsAndFileNames.vbs "%TEMP%\SupersededRevisionAndFileIds.txt" "%TEMP%\SupersededFileIds.txt" /secondonly
rem del "%TEMP%\SupersededRevisionAndFileIds.txt"
%SystemRoot%\system32\sort.exe "%TEMP%\SupersededFileIds.txt" /O "%TEMP%\SupersededFileIdsSorted.txt"
rem del "%TEMP%\SupersededFileIds.txt"
%SystemRoot%\system32\cscript.exe //Nologo //B //E:vbs .\cmd\ExtractUniqueFromSorted.vbs "%TEMP%\SupersededFileIdsSorted.txt" "%TEMP%\SupersededFileIdsUnique.txt"
rem del "%TEMP%\SupersededFileIdsSorted.txt"
"%TEMP%\msxsl.exe" "%TEMP%\package.xml" .\xslt\ExtractUpdateCabExeIdsAndLocations.xsl -o "%TEMP%\UpdateCabExeIdsAndLocations.txt"
%SystemRoot%\system32\findstr.exe /B /L /G:"%TEMP%\SupersededFileIdsUnique.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" >"%TEMP%\SupersededCabExeIdsAndLocations.txt"
rem del "%TEMP%\UpdateCabExeIdsAndLocations.txt"
rem del "%TEMP%\SupersededFileIdsUnique.txt"
%SystemRoot%\system32\cscript.exe //Nologo //B //E:vbs ExtractIdsAndFileNames.vbs "%TEMP%\SupersededCabExeIdsAndLocations.txt" "%TEMP%\ExcludeList-superseded-all.txt" /noids
rem del "%TEMP%\SupersededCabExeIdsAndLocations.txt"
%SystemRoot%\system32\findstr.exe /L /I /V /G:..\exclude\ExcludeList-superseded-exclude.txt "%TEMP%\ExcludeList-superseded-all.txt" >"%TEMP%\ExcludeList-superseded.txt"
rem del "%TEMP%\ExcludeList-superseded-all.txt"

goto EoF

del "%TEMP%\package.xml"
del "%TEMP%\wsusscn2.cab"
del "%TEMP%\msxsl.exe"

:EoF

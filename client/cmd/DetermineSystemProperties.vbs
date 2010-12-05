' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strRegKeyIE                     = "HKLM\Software\Microsoft\Internet Explorer\"
Private Const strRegKeyMDAC                   = "HKLM\Software\Microsoft\DataAccess\"
Private Const strRegKeyDirectX                = "HKLM\Software\Microsoft\DirectX\"
Private Const strRegKeyDotNet35               = "HKLM\Software\Microsoft\NET Framework Setup\NDP\v3.5\"
Private Const strRegKeyDotNet4                = "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full\"
Private Const strRegKeyPowerShell             = "HKLM\Software\Microsoft\PowerShell\1\PowerShellEngine\"
Private Const strRegKeyMSSE                   = "HKLM\Software\Microsoft\Microsoft Security Essentials\"
Private Const strRegKeyMSSEDefs               = "HKLM\Software\Microsoft\Microsoft Antimalware\Signature Updates\"
Private Const strRegValVersion                = "Version"
Private Const strRegValPShVersion             = "PowerShellVersion"
Private Const strRegValAVSVersion             = "AVSignatureVersion"
Private Const strRegKeyOfficePrefix_Mx86      = "HKLM\Software\Microsoft\Office\"
Private Const strRegKeyOfficePrefix_Mx64      = "HKLM\Software\Wow6432Node\Microsoft\Office\"
Private Const strRegKeyOfficePrefix_User      = "HKCU\Software\Microsoft\Office\"
Private Const strRegKeyOfficeInfixes_Version  = "10.0,11.0,12.0,14.0"
Private Const strRegKeyOfficeSuffix_InstRoot  = "\Common\InstallRoot\"
Private Const strRegKeyOfficeSuffix_Language  = "\Common\LanguageResources\"
Private Const strRegValOfficePath             = "Path"
Private Const strRegValOfficeLanguage_Inst    = "SKULanguage"
Private Const strRegValOfficeLanguage_User    = "InstallLanguage"
Private Const strRegValOfficeVersion          = "LastProduct"
Private Const strVersionSuffixes              = "MAJOR,MINOR,BUILD,REVISION"
Private Const strOfficeNames                  = "oxp,o2k3,o2k7,o2k10"
Private Const strOfficeAppNames               = "Word,Excel,Outlook,Powerpoint,Access,FrontPage"
Private Const strOfficeExeNames               = "WINWORD.EXE,EXCEL.EXE,OUTLOOK.EXE,POWERPNT.EXE,MSACCESS.EXE,FRONTPG.EXE"
Private Const strBuildNumbers_Oxp             = "2627,2614,2627,2623,2627,2623;3416,3506,3416,3506,3409,3402;4219,4302,4024,4205,4302,4128;6612,6501,6626,6501,6501,6308"
Private Const strBuildNumbers_O2k3            = "5604,5612,5510,5529,5614,5516;6359,6355,6353,6361,6355,6356;6568,6560,6565,6564,6566,6552;8169,8169,8169,8169,8166,8164"
Private Const strBuildNumbers_O2k7            = "4518,4518,4518,4518,4518,4518;6211,6214,6212,6211,6211,6211;6425,6425,6423,6425,6423,6423"
Private Const strBuildNumbers_O2k10           = "4762,4756,4760,4754,4750,4750"
Private Const idxBuild                        = 2

Dim wshShell, objFileSystem, objCmdFile, objWMIService, objWMIQuery, arrayOfficeNames, arrayOfficeVersions, arrayOfficeAppNames, arrayOfficeExeNames
Dim strSystemFolder, strTempFolder, strWUAFileName, strMSIFileName, strWSHFileName, strTSCFileName, strWMPFileName, strCmdFileName, strOSVersion, strOfficeInstallPath, strOfficeExeVersion, strProduct, languageCode, i, j

Private Function RegExists(objShell, strName)
  On Error Resume Next  'Turn error reporting off
  RegRead = objShell.RegRead(strName)
  RegExists = (Err >= 0)
  Err.Clear
  On Error GoTo 0       'Turn error reporting on
End Function

Private Function RegRead(objShell, strName)
  On Error Resume Next  'Turn error reporting off
  RegRead = objShell.RegRead(strName)
  If Err <> 0 Then
    RegRead = ""
    Err.Clear
  End If
  On Error GoTo 0       'Turn error reporting on
End Function

Private Sub WriteLanguageToFile(objTextFile, varName, langCode, writeExtVar)
  Select Case langCode
' supported languages
    Case &H0009, &H0409, &H0809, &H0C09, &H1009, &H1409, &H1809, &H1C09, &H2009, &H2409, &H2809, &H2C09, &H3009, &H3409, &H4009, &H4409, &H4809
      objTextFile.WriteLine("set " & varName & "=enu")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=en-us")
    Case &H000C, &H040C, &H080C, &H0C0C, &H100C, &H140C, &H180C
      objTextFile.WriteLine("set " & varName & "=fra")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=fr-fr")
    Case &H000A, &H080A, &H0C0A, &H100A, &H140A, &H180A, &H1C0A, &H200A, &H240A, &H280A, &H2C0A, &H300A, &H340A, &H380A, &H3C0A, &H400A, &H440A, &H480A, &H4C0A, &H500A, &H540A
      objTextFile.WriteLine("set " & varName & "=esn")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=es-es")
    Case &H0019, &H0419
      objTextFile.WriteLine("set " & varName & "=rus")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ru-ru")
    Case &H0816
      objTextFile.WriteLine("set " & varName & "=ptg")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=pt-pt")
    Case &H0416
      objTextFile.WriteLine("set " & varName & "=ptb")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=pt-br")
    Case &H0007, &H0407, &H0807, &H0C07, &H1007, &H1407
      objTextFile.WriteLine("set " & varName & "=deu")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=de-de")
    Case &H0013, &H0413, &H0813
      objTextFile.WriteLine("set " & varName & "=nld")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=nl-nl")
    Case &H0010, &H0410, &H0810
      objTextFile.WriteLine("set " & varName & "=ita")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=it-it")
    Case &H0015, &H0415
      objTextFile.WriteLine("set " & varName & "=plk")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=pl-pl")
    Case &H000E, &H040E
      objTextFile.WriteLine("set " & varName & "=hun")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=hu-hu")
    Case &H0005, &H0405
      objTextFile.WriteLine("set " & varName & "=csy")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=cs-cz")
    Case &H001D, &H041D, &H081D
      objTextFile.WriteLine("set " & varName & "=sve")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=sv-se")
    Case &H001F, &H041F
      objTextFile.WriteLine("set " & varName & "=trk")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=tr-tr")
    Case &H0008, &H0408
      objTextFile.WriteLine("set " & varName & "=ell")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=el-gr")
    Case &H0006, &H0406
      objTextFile.WriteLine("set " & varName & "=dan")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=da-dk")
    Case &H0014, &H0414, &H7C14, &H0814, &H7814
      objTextFile.WriteLine("set " & varName & "=nor")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=nb-no")
    Case &H000B, &H040B
      objTextFile.WriteLine("set " & varName & "=fin")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=fi-fi")
    Case &H0004, &H0804, &H1004, &H7804
      objTextFile.WriteLine("set " & varName & "=chs")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=zh-cn")
    Case &H0404, &H0C04, &H1404, &H7C04
      objTextFile.WriteLine("set " & varName & "=cht")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=zh-tw")
    Case &H0011, &H0411
      objTextFile.WriteLine("set " & varName & "=jpn")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ja-jp")
    Case &H0012, &H0412
      objTextFile.WriteLine("set " & varName & "=kor")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ko-kr")
    Case &H0001, &H0401, &H0801, &H0C01, &H1001, &H1401, &H1801, &H1C01, &H2001, &H2401, &H2801, &H2C01, &H3001, &H3401, &H3801, &H3C01, &H4001
      objTextFile.WriteLine("set " & varName & "=ara")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ar-sa")
    Case &H000D, &H040D
      objTextFile.WriteLine("set " & varName & "=heb")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=he-il")

' unsupported languages, detection only
    Case &H002B, &H042B
      objTextFile.WriteLine("set " & varName & "=hye")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=hy-am")
    Case &H002D, &H042D
      objTextFile.WriteLine("set " & varName & "=euq")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=eu-es")
    Case &H0023, &H0423
      objTextFile.WriteLine("set " & varName & "=bel")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=be-by")
    Case &H007E, &H047E
      objTextFile.WriteLine("set " & varName & "=bre")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=br-fr")
    Case &H0002, &H0402
      objTextFile.WriteLine("set " & varName & "=bgr")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=bg-bg")
    Case &H0003, &H0403
      objTextFile.WriteLine("set " & varName & "=cat")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ca-es")
    Case &H0083, &H0483
      objTextFile.WriteLine("set " & varName & "=cos")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=co-fr")
    Case &H001A, &H041A, &H101A
      objTextFile.WriteLine("set " & varName & "=hrv")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=hr-hr")
    Case &H0025, &H0425
      objTextFile.WriteLine("set " & varName & "=eti")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=et-ee")
    Case &H0038, &H0438
      objTextFile.WriteLine("set " & varName & "=fos")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=fo-fo")
    Case &H0062, &H0462
      objTextFile.WriteLine("set " & varName & "=fyn")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=fy-nl")
    Case &H0056, &H0456
      objTextFile.WriteLine("set " & varName & "=glc")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=gl-es")
    Case &H0037, &H0437
      objTextFile.WriteLine("set " & varName & "=kat")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ka-ge")
    Case &H006F, &H046F
      objTextFile.WriteLine("set " & varName & "=kal")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=kl-gl")
    Case &H0039, &H0439
      objTextFile.WriteLine("set " & varName & "=hin")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=hi-in")
    Case &H000F, &H040F
      objTextFile.WriteLine("set " & varName & "=isl")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=is-is")
    Case &H003C, &H083C
      objTextFile.WriteLine("set " & varName & "=ire")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ga-ie")
    Case &H0026, &H0426
      objTextFile.WriteLine("set " & varName & "=lvi")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=lv-lv")
    Case &H0027, &H0427
      objTextFile.WriteLine("set " & varName & "=lth")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=lt-lt")
    Case &H0029, &H0429
      objTextFile.WriteLine("set " & varName & "=far")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=fa-ir")
    Case &H0046, &H0446
      objTextFile.WriteLine("set " & varName & "=pan")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=pa-in")
    Case &H0018, &H0418
      objTextFile.WriteLine("set " & varName & "=rom")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=ro-ro")
    Case &H004F, &H044F
      objTextFile.WriteLine("set " & varName & "=san")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=sa-in")
    Case &H001B, &H041B
      objTextFile.WriteLine("set " & varName & "=sky")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=sk-sk")
    Case &H0024, &H0424
      objTextFile.WriteLine("set " & varName & "=slv")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=sl-si")
    Case &H001E, &H041E
      objTextFile.WriteLine("set " & varName & "=tha")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=th-th")
    Case &H0022, &H0422
      objTextFile.WriteLine("set " & varName & "=ukr")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=uk-ua")
    Case &H002A, &H042A
      objTextFile.WriteLine("set " & varName & "=vit")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=vi-vn")
    Case &H0052, &H0452
      objTextFile.WriteLine("set " & varName & "=cym")
      If writeExtVar Then objTextFile.WriteLine("set " & varName & "_EXT=cy-gb")
  End Select
End Sub

Private Sub WriteVersionToFile(objTextFile, strPrefix, strVersion)
Dim arraySuffixes, arrayVersion, i

  arraySuffixes = Split(strVersionSuffixes, ",")
  If Len(strVersion) > 0 Then
    arrayVersion = Split(strVersion, ".")
  Else
    arrayVersion = Split("0", ".")
  End If
  For i = 0 To UBound(arraySuffixes)
    If i > UBound(arrayVersion) Then
      objTextFile.WriteLine("set " & strPrefix & "_" & arraySuffixes(i) & "=0")         
    Else
      objTextFile.WriteLine("set " & strPrefix & "_" & arraySuffixes(i) & "=" & arrayVersion(i))         
    End If
  Next
End Sub

Private Sub WriteDXNameToFile(objTextFile, strDXVersion)

  Select Case strDXVersion
    Case "4.02.0095"
      objTextFile.WriteLine("set DIRECTX_NAME=1.0")
    Case "4.03.00.1096"
      objTextFile.WriteLine("set DIRECTX_NAME=2.0")
    Case "4.04.0068"
      objTextFile.WriteLine("set DIRECTX_NAME=3.0")
    Case "4.04.0069"
      objTextFile.WriteLine("set DIRECTX_NAME=3.0")
    Case "4.05.00.0155"
      objTextFile.WriteLine("set DIRECTX_NAME=5.0")
    Case "4.05.01.1721"
      objTextFile.WriteLine("set DIRECTX_NAME=5.0")
    Case "4.05.01.1998"
      objTextFile.WriteLine("set DIRECTX_NAME=5.0")
    Case "4.06.02.0436"
      objTextFile.WriteLine("set DIRECTX_NAME=6.0")
    Case "4.07.00.0700"
      objTextFile.WriteLine("set DIRECTX_NAME=7.0")
    Case "4.07.00.0716"
      objTextFile.WriteLine("set DIRECTX_NAME=7.0a")
    Case "4.08.00.0400"
      objTextFile.WriteLine("set DIRECTX_NAME=8.0")
    Case "4.08.01.0881"
      objTextFile.WriteLine("set DIRECTX_NAME=8.1")
    Case "4.08.01.0810"
      objTextFile.WriteLine("set DIRECTX_NAME=8.1")
    Case "4.09.00.0900"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0")
    Case "4.09.0000.0900"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0")
    Case "4.09.00.0901"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0a")
    Case "4.09.0000.0901"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0a")
    Case "4.09.00.0902"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0b")
    Case "4.09.0000.0902"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0b")
    Case "4.09.00.0904"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0c")
    Case "4.09.0000.0904"
      objTextFile.WriteLine("set DIRECTX_NAME=9.0c")
  End Select
End Sub

Private Function OfficeInstallPath(objShell, strVersionInfix)
Dim strRegVal

  OfficeInstallPath = ""
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx86 & strVersionInfix & strRegKeyOfficeSuffix_InstRoot & strRegValOfficePath)
  If strRegVal <> "" Then 
    OfficeInstallPath = strRegVal
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx64 & strVersionInfix & strRegKeyOfficeSuffix_InstRoot & strRegValOfficePath)
  If strRegVal <> "" Then 
    OfficeInstallPath = strRegVal
    Exit Function
  End If
End Function

Private Function OfficeLanguageCode(objShell, strVersionInfix)
Dim strRegVal

  OfficeLanguageCode = 0
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx86 & strVersionInfix & strRegKeyOfficeSuffix_Language & strRegValOfficeLanguage_Inst)
  If strRegVal <> "" Then 
    OfficeLanguageCode = CInt(strRegVal)
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx64 & strVersionInfix & strRegKeyOfficeSuffix_Language & strRegValOfficeLanguage_Inst)
  If strRegVal <> "" Then 
    OfficeLanguageCode = CInt(strRegVal)
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_User & strVersionInfix & strRegKeyOfficeSuffix_Language & strRegValOfficeLanguage_User)
  If strRegVal <> "" Then 
    OfficeLanguageCode = CInt(strRegVal)
    Exit Function
  End If
End Function

Private Function OfficeSPVersion(strExeVersion, idxApp)
Dim arrayVersion, arraySPs, arrayBuilds, i

  OfficeSPVersion = 0
  arrayVersion = Split(strExeVersion, ".")
  Select Case CInt(arrayVersion(0))
    Case 10
      arraySPs = Split(strBuildNumbers_Oxp, ";")
    Case 11
      arraySPs = Split(strBuildNumbers_O2k3, ";")
    Case 12
      arraySPs = Split(strBuildNumbers_O2k7, ";")
    Case 14
      arraySPs = Split(strBuildNumbers_O2k10, ";")
    Case Else
      arraySPs = Split("0,0,0,0,0,0", ";")
  End Select
  If UBound(arrayVersion) < idxBuild Then
    Exit Function
  End If
  For i = 0 To UBound(arraySPs)
    arrayBuilds = Split(arraySPs(i), ",")
    If UBound(arrayBuilds) < idxApp Then
      Exit Function
    End If
    If CInt(arrayVersion(idxBuild)) >= CInt(arrayBuilds(idxApp)) Then
      OfficeSPVersion = i
    End If
  Next
End Function

' Main
Set wshShell = WScript.CreateObject("WScript.Shell")
strSystemFolder = wshShell.ExpandEnvironmentStrings("%SystemRoot%") & "\system32"
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strWUAFileName = strSystemFolder & "\wuaueng.dll"
strMSIFileName = strSystemFolder & "\msi.dll"
strWSHFileName = strSystemFolder & "\vbscript.dll"
strWMPFileName = strSystemFolder & "\wmp.dll"
strTSCFileName = strSystemFolder & "\mstsc.exe"
strCmdFileName = strTempFolder & "\SetSystemEnvVars.cmd"

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objCmdFile = objFileSystem.CreateTextFile(strCmdFileName, True)

' Determine Windows system properties
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
' Documentation: http://msdn.microsoft.com/en-us/library/aa394239(VS.85).aspx
For Each objWMIQuery in objWMIService.ExecQuery("Select * from Win32_OperatingSystem") 
  objCmdFile.WriteLine("set OS_CAPTION=" & objWMIQuery.Caption)
  WriteVersionToFile objCmdFile, "OS_VER", objWMIQuery.Version
  strOSVersion = Left(objWMIQuery.Version, 3) ' For determination of Windows activation state - see below
  objCmdFile.WriteLine("set OS_SP_VER_MAJOR=" & objWMIQuery.ServicePackMajorVersion)
  objCmdFile.WriteLine("set OS_SP_VER_MINOR=" & objWMIQuery.ServicePackMinorVersion)
  objCmdFile.WriteLine("set OS_LANG_CODE=0x" & Hex(objWMIQuery.OSLanguage))
  WriteLanguageToFile objCmdFile, "OS_LANG", objWMIQuery.OSLanguage, True
  objCmdFile.WriteLine("set SystemDirectory=" & objWMIQuery.SystemDirectory)
Next
' Documentation: http://msdn.microsoft.com/en-us/library/aa394102(VS.85).aspx
For Each objWMIQuery in objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
  objCmdFile.WriteLine("set OS_ARCH=" & LCase(Left(objWMIQuery.SystemType, 3)))
  objCmdFile.WriteLine("set OS_DOMAIN_ROLE=" & objWMIQuery.DomainRole)
Next

' Determine Windows Update Agent version 
If objFileSystem.FileExists(strWUAFileName) Then
  WriteVersionToFile objCmdFile, "WUA_VER", objFileSystem.GetFileVersion(strWUAFileName)
Else
  WriteVersionToFile objCmdFile, "WUA_VER", ""
End If

' Determine Microsoft Installer version
If objFileSystem.FileExists(strMSIFileName) Then
  WriteVersionToFile objCmdFile, "MSI_VER", objFileSystem.GetFileVersion(strMSIFileName)
Else
  WriteVersionToFile objCmdFile, "MSI_VER", ""
End If

' Determine Windows Script Host version
If objFileSystem.FileExists(strWSHFileName) Then
  WriteVersionToFile objCmdFile, "WSH_VER", objFileSystem.GetFileVersion(strWSHFileName)
Else
  WriteVersionToFile objCmdFile, "WSH_VER", ""
End If

' Determine Internet Explorer version
WriteVersionToFile objCmdFile, "IE_VER", RegRead(wshShell, strRegKeyIE & strRegValVersion)

' Determine Microsoft Data Access Components version
WriteVersionToFile objCmdFile, "MDAC_VER", RegRead(wshShell, strRegKeyMDAC & strRegValVersion)

' Determine Microsoft DirectX version
WriteVersionToFile objCmdFile, "DIRECTX_VER", RegRead(wshShell, strRegKeyDirectX & strRegValVersion)
WriteDXNameToFile objCmdFile, RegRead(wshShell, strRegKeyDirectX & strRegValVersion)

' Determine Microsoft .NET Framework 3.5 SP1 installation state
WriteVersionToFile objCmdFile, "DOTNET35_VER", RegRead(wshShell, strRegKeyDotNet35 & strRegValVersion)
WriteVersionToFile objCmdFile, "DOTNET4_VER", RegRead(wshShell, strRegKeyDotNet4 & strRegValVersion)

' Determine Windows PowerShell version
WriteVersionToFile objCmdFile, "PSH_VER", RegRead(wshShell, strRegKeyPowerShell & strRegValPShVersion)

' Determine Microsoft Security Essentials installation state
If RegExists(wshShell, strRegKeyMSSE) Then
  objCmdFile.WriteLine("set MSSE_INSTALLED=1")
Else
  objCmdFile.WriteLine("set MSSE_INSTALLED=0")
End If

' Determine Microsoft Antimalware signatures' version
WriteVersionToFile objCmdFile, "MSSEDEFS_VER", RegRead(wshShell, strRegKeyMSSEDefs & strRegValAVSVersion)

' Determine Remote Desktop Connection (Terminal Services Client) version
If objFileSystem.FileExists(strTSCFileName) Then
  WriteVersionToFile objCmdFile, "TSC_VER", objFileSystem.GetFileVersion(strTSCFileName)
Else
  WriteVersionToFile objCmdFile, "TSC_VER", ""
End If

' Determine Windows Media Player version
If objFileSystem.FileExists(strWMPFileName) Then
  WriteVersionToFile objCmdFile, "WMP_VER", objFileSystem.GetFileVersion(strWMPFileName)
Else
  WriteVersionToFile objCmdFile, "WMP_VER", ""
End If

' Determine Office version
arrayOfficeNames = Split(strOfficeNames, ",")
arrayOfficeVersions = Split(strRegKeyOfficeInfixes_Version, ",")
arrayOfficeAppNames = Split(strOfficeAppNames, ",")
arrayOfficeExeNames = Split(strOfficeExeNames, ",")
For i = 0 To UBound(arrayOfficeNames)
  strOfficeInstallPath = OfficeInstallPath(wshShell, arrayOfficeVersions(i)) 
  If strOfficeInstallPath <> "" Then
    For j = 0 To UBound(arrayOfficeExeNames)
      If objFileSystem.FileExists(strOfficeInstallPath & arrayOfficeExeNames(j)) Then
        objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_VER_APP=" & arrayOfficeAppNames(j))
        strOfficeExeVersion = objFileSystem.GetFileVersion(strOfficeInstallPath & arrayOfficeExeNames(j)) 
        WriteVersionToFile objCmdFile, UCase(arrayOfficeNames(i)) & "_VER", strOfficeExeVersion  
        objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_SP_VER=" & OfficeSPVersion(strOfficeExeVersion, j))
        languageCode = OfficeLanguageCode(wshShell, arrayOfficeVersions(i))
        objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_LANG_CODE=0x" & Hex(languageCode))
        If languageCode = 0 Then
          objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_LANG=%OS_LANG%")
        Else
          WriteLanguageToFile objCmdFile, UCase(arrayOfficeNames(i)) & "_LANG", languageCode, False
        End If
        Exit For
      End If
    Next
  End If
Next
For Each strProduct In CreateObject("WindowsInstaller.Installer").Products
  If UCase(strProduct) = "{6EECB283-E65F-40EF-86D3-D51BF02A8D43}" Then
    objCmdFile.WriteLine("set OFC_CONV_PACK=1")
  End If
  If UCase(strProduct) = "{90120000-0020-0407-0000-0000000FF1CE}" Then
    objCmdFile.WriteLine("set OFC_COMP_PACK=1")
  End If
Next

'
' Perform the following WMI queries last, since they might fail if WMI is damaged 
'

' Determine state of automatic updates service 
For Each objWMIQuery in objWMIService.ExecQuery("Select * from Win32_Service Where Name = 'wuauserv'")
  objCmdFile.WriteLine("set AU_SVC_STATE_INITIAL=" & objWMIQuery.State)
  objCmdFile.WriteLine("set AU_SVC_START_MODE=" & objWMIQuery.StartMode)
Next

' Determine Windows activation state - not available on Windows 2000 and Vista systems 
If (strOSVersion = "5.1") Or (strOSVersion = "5.2") Then
  For Each objWMIQuery in objWMIService.ExecQuery("Select * from Win32_WindowsProductActivation")
    objCmdFile.WriteLine("set OS_ACTIVATION_REQUIRED=" & objWMIQuery.ActivationRequired)
  Next
End If

objCmdFile.Close
WScript.Quit(0)

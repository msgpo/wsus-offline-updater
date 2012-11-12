; ***   WSUS Offline Update 7.5 - Installer   ***
; ***       Author: T. Wittrock, Kiel         ***
; ***   Dialog scaling added by Th. Baisch    ***

#include <GUIConstants.au3>
#RequireAdmin

Dim Const $caption                    = "WSUS Offline Update 7.5 - Installer"

; Registry constants
Dim Const $reg_key_wsh_hklm           = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings"
Dim Const $reg_key_wsh_hkcu           = "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings"
Dim Const $reg_key_ie                 = "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer"
Dim Const $reg_key_mssl               = "HKEY_LOCAL_MACHINE\Software\Microsoft\Silverlight"
Dim Const $reg_key_dotnet35           = "HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v3.5"
Dim Const $reg_key_dotnet4            = "HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v4\Full"
Dim Const $reg_key_psh                = "HKEY_LOCAL_MACHINE\Software\Microsoft\PowerShell\1\PowerShellEngine"
Dim Const $reg_key_wmf                = "HKEY_LOCAL_MACHINE\Software\Microsoft\PowerShell\3\PowerShellEngine"
Dim Const $reg_key_msse               = "HKEY_LOCAL_MACHINE\Software\Microsoft\Microsoft Security Client"
Dim Const $reg_key_fontdpi            = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontDPI"
Dim Const $reg_key_windowmetrics      = "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics"
Dim Const $reg_key_windowsupdate      = "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate"

Dim Const $reg_val_default            = ""
Dim Const $reg_val_enabled            = "Enabled"
Dim Const $reg_val_version            = "Version"
Dim Const $reg_val_pshversion         = "PowerShellVersion"
Dim Const $reg_val_logpixels          = "LogPixels"
Dim Const $reg_val_applieddpi         = "AppliedDPI"
Dim Const $reg_val_wustatusserver     = "WUStatusServer"

; Defaults
Dim Const $default_logpixels          = 96
Dim Const $target_version_dotnet35    = "3.5.30729.01"
Dim Const $target_version_dotnet40    = "4.0.30319"
Dim Const $target_version_dotnet45    = "4.5.50709"
Dim Const $target_version_psh         = "2.0"
Dim Const $target_version_wmf         = "3.0"

; INI file constants
Dim Const $ini_section_installation   = "Installation"
Dim Const $ini_value_backup           = "backup"
Dim Const $ini_value_rcerts           = "updatercerts"
Dim Const $ini_value_ie7              = "instie7"
Dim Const $ini_value_ie8              = "instie8"
Dim Const $ini_value_ie9              = "instie9"
Dim Const $ini_value_cpp              = "updatecpp"
Dim Const $ini_value_dx               = "updatedx"
Dim Const $ini_value_mssl             = "instmssl"
Dim Const $ini_value_wmp              = "updatewmp"
Dim Const $ini_value_dotnet35         = "instdotnet35"
Dim Const $ini_value_dotnet4          = "instdotnet4"
Dim Const $ini_value_psh              = "instpsh"
Dim Const $ini_value_wmf              = "instwmf"
Dim Const $ini_value_msse             = "instmsse"
Dim Const $ini_value_tsc              = "updatetsc"
Dim Const $ini_value_ofc              = "instofc"
Dim Const $ini_value_ofv              = "instofv"
Dim Const $ini_value_all              = "all"
Dim Const $ini_value_excludestatics   = "excludestatics"
Dim Const $ini_value_skipdynamic      = "skipdynamic"

Dim Const $ini_section_control        = "Control"
Dim Const $ini_value_verify           = "verify"
Dim Const $ini_value_autoreboot       = "autoreboot"
Dim Const $ini_value_shutdown         = "shutdown"

Dim Const $ini_section_messaging      = "Messaging"
Dim Const $ini_value_showlog          = "showlog"

Dim Const $ini_section_misc           = "Miscellaneous"
Dim Const $ini_value_wustatusserver   = "WUStatusServer"

Dim Const $enabled                    = "Enabled"
Dim Const $disabled                   = "Disabled"

; Paths
Dim Const $path_max_length            = 128
Dim Const $path_invalid_chars         = "!%&()^+,;="
Dim Const $path_rel_builddate         = "\builddate.txt"
Dim Const $path_rel_hashes            = "\md\"
Dim Const $path_rel_autologon         = "\bin\Autologon.exe"
Dim Const $path_rel_win_glb           = "\win\glb\"
Dim Const $path_rel_cpp               = "\cpp\vcredist*.exe"
Dim Const $path_rel_instdotnet35      = "\dotnet\dotnetfx35.exe"
Dim Const $path_rel_instdotnet4       = "\dotnet\dotNetFx40_Full_x86_x64.exe"
Dim Const $path_rel_ofc_glb           = "\ofc\glb\"
Dim Const $path_rel_msse_x86          = "\msse\x86-glb\mseinstall-x86-*.exe"
Dim Const $path_rel_msse_x64          = "\msse\x64-glb\mseinstall-x64-*.exe"

Dim $maindlg, $scriptdir, $mapped, $inifilename, $backup, $rcerts, $ie7, $ie8, $ie9, $cpp, $dx, $mssl, $wmp, $dotnet35, $dotnet4, $psh, $wmf, $msse, $tsc, $ofc, $ofv, $verify, $autoreboot, $shutdown, $showlog, $btn_start, $btn_exit, $options, $builddate
Dim $dlgheight, $groupwidth, $txtwidth, $txtheight, $btnwidth, $btnheight, $txtxoffset, $txtyoffset, $txtxpos, $txtypos

Func ShowGUIInGerman()
  If ($CmdLine[0] > 0) Then
    Switch StringLower($CmdLine[1])
      Case "enu"
        Return False
      Case "deu"
        Return True
    EndSwitch
  EndIf
  Return ( (@OSLang = "0007") OR (@OSLang = "0407") OR (@OSLang = "0807") OR (@OSLang = "0C07") OR (@OSLang = "1007") OR (@OSLang = "1407") )
EndFunc

; Returns script directory, also sets global variable $mapped
Func AssignScriptDirectory()
Dim $result, $netdrives, $i

  ; Check if script directory is a network share, map if unmapped
  $result = ""
  $mapped = False
  If DriveGetType(@ScriptDir) = "Network" Then
    If StringInStr(@ScriptDir, "\\") = 0 Then
      $result = @ScriptDir
    Else
      $netdrives = DriveGetDrive("NETWORK")
      If NOT @error Then
        For $i = 1 to $netdrives[0]
          If StringInStr(@ScriptDir, DriveMapGet($netdrives[$i])) > 0 Then
            $result = $netdrives[$i] & StringRight(@ScriptDir, StringLen(@ScriptDir) - StringLen(DriveMapGet($netdrives[$i])))
            ExitLoop
          EndIf
        Next
      EndIf
      If $result = "" Then
        $result = DriveMapAdd("*", @ScriptDir)
        If @error Then
          $result = ""
        Else
          $mapped = True
        EndIf
      EndIf
    EndIf
  Else
    $result = @ScriptDir
  EndIf
  Return $result
EndFunc

Func PathValid($basepath)
Dim $result, $arr_invalid, $i

  If StringLen($basepath) > $path_max_length Then
    $result = False
  Else
    $result = True
    $arr_invalid = StringSplit($path_invalid_chars, "")
    For $i = 1 to $arr_invalid[0]
      If StringInStr($basepath, $arr_invalid[$i]) > 0 Then
        $result = False
        ExitLoop
      EndIf
    Next
  EndIf
  Return $result
EndFunc

Func MediumBuildDate($basepath)
Dim $result

  $result = FileReadLine($basepath & $path_rel_builddate)
  If @error Then
    $result = ""
  EndIf
  Return $result
EndFunc

Func WSHAvailable()
Dim $reg_val

  $reg_val = RegRead($reg_key_wsh_hklm, $reg_val_enabled)
  If ($reg_val = "0") Then
    Return 0
  EndIf
  $reg_val = RegRead($reg_key_wsh_hkcu, $reg_val_enabled)
  If ($reg_val = "0") Then
    Return 0
  EndIf
  Return 1
EndFunc

Func IEVersion()
Dim $reg_val

  $reg_val = RegRead($reg_key_ie, $reg_val_version)
  Return StringLeft($reg_val, StringInStr($reg_val, ".") - 1)
EndFunc

Func DotNet35Version()
  Return RegRead($reg_key_dotnet35, $reg_val_version)
EndFunc

Func DotNet4Version()
  Return RegRead($reg_key_dotnet4, $reg_val_version)
EndFunc

Func DotNet4TargetVersion()
  If ( (@OSVersion = "WIN_XP") OR (@OSVersion = "WIN_2003") ) Then
    Return $target_version_dotnet40
  Else
    Return $target_version_dotnet45
  EndIf
EndFunc

Func PowerShellVersion()
  Return RegRead($reg_key_psh, $reg_val_pshversion)
EndFunc

Func ManagementFrameworkVersion()
  Return RegRead($reg_key_wmf, $reg_val_pshversion)
EndFunc

Func MSSLInstalled()
Dim $dummy

  $dummy = RegRead($reg_key_mssl, $reg_val_default)
  Return (@error <= 0)
EndFunc

Func MSSEInstalled()
Dim $dummy

  $dummy = RegRead($reg_key_msse, $reg_val_default)
  Return (@error <= 0)
EndFunc

Func HashFilesPresent($basepath)
  Return FileExists($basepath & $path_rel_hashes)
EndFunc

Func AutologonPresent($basepath)
  Return FileExists($basepath & $path_rel_autologon)
EndFunc

Func WinGlbPresent($basepath)
  Return FileExists($basepath & $path_rel_win_glb)
EndFunc

Func CPPPresent($basepath)
  Return FileExists($basepath & $path_rel_cpp)
EndFunc

Func DotNet35InstPresent($basepath)
  Return FileExists($basepath & $path_rel_instdotnet35)
EndFunc

Func DotNet4InstPresent($basepath)
  Return FileExists($basepath & $path_rel_instdotnet4)
EndFunc

Func OfcGlbPresent($basepath)
  Return FileExists($basepath & $path_rel_ofc_glb)
EndFunc

Func MSSEPresent($basepath)
  Return (FileExists($basepath & $path_rel_msse_x86) OR FileExists($basepath & $path_rel_msse_x64))
EndFunc

Func CalcGUISize()
  Dim $reg_val

  $reg_val = RegRead($reg_key_windowmetrics, $reg_val_applieddpi)
  If ($reg_val = "") Then
    $reg_val = RegRead($reg_key_fontdpi, $reg_val_logpixels)
  EndIf
  If ($reg_val = "") Then
    $reg_val = $default_logpixels
  EndIf
  $dlgheight = 345 * $reg_val / $default_logpixels
  If ShowGUIInGerman() Then
    $txtwidth = 240 * $reg_val / $default_logpixels
  Else
    $txtwidth = 220 * $reg_val / $default_logpixels
  EndIf
  $txtheight = 20 * $reg_val / $default_logpixels
  $btnwidth = 80 * $reg_val / $default_logpixels
  $btnheight = 25 * $reg_val / $default_logpixels
  $txtxoffset = 10 * $reg_val / $default_logpixels
  $txtyoffset = 10 * $reg_val / $default_logpixels
  Return 0
EndFunc	

; Main Dialog
AutoItSetOption("GUICloseOnESC", 0)
AutoItSetOption("TrayAutoPause", 0)
AutoItSetOption("TrayIconHide", 1)
CalcGUISize()
$groupwidth = 2 * $txtwidth + 2 * $txtxoffset
$maindlg = GUICreate($caption, $groupwidth + 2 * $txtxoffset, $dlgheight)
GUISetFont(8.5, 400, 0, "Sans Serif")

$scriptdir = AssignScriptDirectory()
$inifilename = $scriptdir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) & "ini"

;  Label
$txtxpos = $txtxoffset
$txtypos = $txtyoffset
If ShowGUIInGerman() Then
  GUICtrlCreateLabel("W�hlen Sie die gew�nschten Optionen und klicken Sie auf 'Start'," & @LF & "um die fehlenden Microsoft-Updates auf Ihrem System zu installieren.", $txtxpos, $txtypos, 3 * $groupwidth / 4, 2 * $txtheight)
Else
  GUICtrlCreateLabel("Select desired options and click 'Start'" & @LF & "to install missing Microsoft updates on your computer.", $txtxpos, $txtypos, 3 * $groupwidth / 4, 2 * $txtheight)
EndIf

;  Medium info group
$builddate = MediumBuildDate($scriptdir)
If ($builddate <> "") Then
  $txtxpos = $txtxoffset + 3 * $groupwidth / 4
  $txtypos = 0
  GUICtrlCreateGroup("Medium info", $txtxpos, $txtypos, $groupwidth / 4, 2 * $txtheight)
  $txtxpos = $txtxpos + $txtxoffset
  $txtypos = $txtypos + 1.5 * $txtyoffset + 2
  GUICtrlCreateLabel("Build: " & $builddate, $txtxpos, $txtypos, $groupwidth / 4 - 2 * $txtxoffset, $txtheight)
EndIf

;  Installation group
$txtxpos = $txtxoffset
$txtypos = $txtyoffset + 1.5 * $txtheight
GUICtrlCreateGroup("Installation", $txtxpos, $txtypos, $groupwidth, 10 * $txtheight)

; Backup
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + 1.5 * $txtyoffset
If ShowGUIInGerman() Then
  $backup = GUICtrlCreateCheckbox("Existierende Systemdateien sichern", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $backup = GUICtrlCreateCheckbox("Back up existing system files", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") ) Then
  GUICtrlSetState(-1, $GUI_CHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_backup, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Update Root Certificates
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $rcerts = GUICtrlCreateCheckbox("Stammzertifikate aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $rcerts = GUICtrlCreateCheckbox("Update Root Certificates", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If WinGlbPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_installation, $ini_value_rcerts, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

; Install IE7
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $ie7 = GUICtrlCreateCheckbox("Internet Explorer 7 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $ie7 = GUICtrlCreateCheckbox("Install Internet Explorer 7", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (IEVersion() = "7") OR (IEVersion() = "8") OR (IEVersion() = "9") OR (NOT WinGlbPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If (IniRead($inifilename, $ini_section_installation, $ini_value_ie7, $disabled) = $enabled) Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install IE8
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $ie8 = GUICtrlCreateCheckbox("Internet Explorer 8 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $ie8 = GUICtrlCreateCheckbox("Install Internet Explorer 8", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (IEVersion() = "8") OR (IEVersion() = "9") OR (NOT WinGlbPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If (IniRead($inifilename, $ini_section_installation, $ini_value_ie8, $enabled) = $enabled) Then
    GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetState($ie7, $GUI_UNCHECKED + $GUI_DISABLE)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
    If BitAND(GUICtrlRead($ie7), $GUI_CHECKED) = $GUI_CHECKED Then
      GUICtrlSetState(-1, $GUI_DISABLE)
    EndIf
  EndIf
EndIf

; Install IE9
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $ie9 = GUICtrlCreateCheckbox("Internet Explorer 9 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $ie9 = GUICtrlCreateCheckbox("Install Internet Explorer 9", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_XP") OR (@OSVersion = "WIN_2003") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (IEVersion() = "9") OR (NOT WinGlbPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If (IniRead($inifilename, $ini_section_installation, $ini_value_ie9, $disabled) = $enabled) Then
    GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetState($ie7, $GUI_UNCHECKED + $GUI_DISABLE)
    GUICtrlSetState($ie8, $GUI_UNCHECKED + $GUI_DISABLE)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
    If ( (BitAND(GUICtrlRead($ie7), $GUI_CHECKED) = $GUI_CHECKED) OR (BitAND(GUICtrlRead($ie8), $GUI_CHECKED) = $GUI_CHECKED) ) Then
      GUICtrlSetState(-1, $GUI_DISABLE)
    EndIf
  EndIf
EndIf

; Update C++ Runtime Libraries
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $cpp = GUICtrlCreateCheckbox("C++-Laufzeitbibliotheken aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $cpp = GUICtrlCreateCheckbox("Update C++ Runtime Libraries", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If CPPPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_installation, $ini_value_cpp, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

; Update DirectX Runtime Libraries
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $dx = GUICtrlCreateCheckbox("DirectX-Laufzeitbibliotheken aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $dx = GUICtrlCreateCheckbox("Update DirectX Runtime Libraries", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If WinGlbPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_installation, $ini_value_dx, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

; Install Microsoft Silverlight
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  If MSSLInstalled() Then
    $mssl = GUICtrlCreateCheckbox("Microsoft Silverlight aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $mssl = GUICtrlCreateCheckbox("Microsoft Silverlight installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
Else
  If MSSLInstalled() Then
    $mssl = GUICtrlCreateCheckbox("Update Microsoft Silverlight", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $mssl = GUICtrlCreateCheckbox("Install Microsoft Silverlight", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
EndIf
If ( (NOT WinGlbPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_mssl, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Update Windows Media Player
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $wmp = GUICtrlCreateCheckbox("Windows Media Player aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $wmp = GUICtrlCreateCheckbox("Update Windows Media Player", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_2003") OR (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (NOT WinGlbPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_wmp, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install .NET Framework 3.5 SP1
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $dotnet35 = GUICtrlCreateCheckbox(".NET Framework 3.5 SP1 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $dotnet35 = GUICtrlCreateCheckbox("Install .NET Framework 3.5 SP1", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (DotNet35Version() = $target_version_dotnet35) OR (NOT DotNet35InstPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_dotnet35, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install Windows PowerShell 2.0
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $psh = GUICtrlCreateCheckbox("PowerShell 2.0 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $psh = GUICtrlCreateCheckbox("Install PowerShell 2.0", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR ( (DotNet35Version() <> $target_version_dotnet35) AND (BitAND(GUICtrlRead($dotnet35), $GUI_CHECKED) <> $GUI_CHECKED) ) _
  OR (PowerShellVersion() = $target_version_psh) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_psh, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install .NET Framework 4
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $dotnet4 = GUICtrlCreateCheckbox(".NET Framework 4.x installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $dotnet4 = GUICtrlCreateCheckbox("Install .NET Framework 4.x", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (DotNet4Version() = DotNet4TargetVersion()) OR (NOT DotNet4InstPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_dotnet4, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install Windows Management Framework 3.0
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $wmf = GUICtrlCreateCheckbox("Management Framework 3.0 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $wmf = GUICtrlCreateCheckbox("Install Management Framework 3.0", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_XP") OR (@OSVersion = "WIN_2003") OR (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR ( (DotNet4Version() <> DotNet4TargetVersion()) AND (BitAND(GUICtrlRead($dotnet4), $GUI_CHECKED) <> $GUI_CHECKED) ) _
  OR (ManagementFrameworkVersion() = $target_version_wmf) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_wmf, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install Microsoft Security Essentials
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  If MSSEInstalled() Then
    $msse = GUICtrlCreateCheckbox("Microsoft Security Essentials aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $msse = GUICtrlCreateCheckbox("Microsoft Security Essentials installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
Else
  If MSSEInstalled() Then
    $msse = GUICtrlCreateCheckbox("Update Microsoft Security Essentials", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $msse = GUICtrlCreateCheckbox("Install Microsoft Security Essentials", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
EndIf
If ( (@OSVersion = "WIN_2003") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_2012") _
  OR (NOT MSSEPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_msse, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Update Windows Remote Desktop Client
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $tsc = GUICtrlCreateCheckbox("Remote Desktop Client aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $tsc = GUICtrlCreateCheckbox("Update Remote Desktop Client", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (NOT WinGlbPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If IniRead($inifilename, $ini_section_installation, $ini_value_tsc, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install file format converters for Office
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $ofc = GUICtrlCreateCheckbox("Office-Dateikonverter installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $ofc = GUICtrlCreateCheckbox("Install Office File Converters", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If OfcGlbPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_installation, $ini_value_ofc, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

; Install Office File Validation
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $ofv = GUICtrlCreateCheckbox("Office-Datei�berpr�fung installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $ofv = GUICtrlCreateCheckbox("Install Office File Validation", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If OfcGlbPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_installation, $ini_value_ofv, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

;  Control group
$txtxpos = $txtxoffset
$txtypos = $txtypos + 2.5 * $txtyoffset
If ShowGUIInGerman() Then
  GUICtrlCreateGroup("Steuerung", $txtxpos, $txtypos, $groupwidth, 3 * $txtheight)
Else
  GUICtrlCreateGroup("Control", $txtxpos, $txtypos, $groupwidth, 3 * $txtheight)
EndIf

; Verify
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + 1.5 * $txtyoffset
If ShowGUIInGerman() Then
  $verify = GUICtrlCreateCheckbox("Installationspakete verifizieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $verify = GUICtrlCreateCheckbox("Verify installation packages", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If HashFilesPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_control, $ini_value_verify, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

;  Automatic reboot and recall
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $autoreboot = GUICtrlCreateCheckbox("Automatisch neu starten und fortsetzen", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $autoreboot = GUICtrlCreateCheckbox("Automatic reboot and recall", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If AutologonPresent($scriptdir) Then
  If IniRead($inifilename, $ini_section_control, $ini_value_autoreboot, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

;  Automatic shutdown
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + $txtheight
If ShowGUIInGerman() Then
  $shutdown = GUICtrlCreateCheckbox("Nach Aktualisierung herunterfahren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $shutdown = GUICtrlCreateCheckbox("Shut down after updating", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If IniRead($inifilename, $ini_section_control, $ini_value_shutdown, $disabled) = $enabled Then
  GUICtrlSetState(-1, $GUI_CHECKED)
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED)
EndIf

; Show log file
$txtxpos = $txtxoffset + $groupwidth / 2
If ShowGUIInGerman() Then
  $showlog = GUICtrlCreateCheckbox("Protokolldatei anzeigen", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $showlog = GUICtrlCreateCheckbox("Show log file", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (IniRead($inifilename, $ini_section_messaging, $ini_value_showlog, $disabled) = $enabled) _
 AND (BitAND(GUICtrlRead($shutdown), $GUI_CHECKED) <> $GUI_CHECKED) ) Then
  GUICtrlSetState(-1, $GUI_CHECKED)
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED)
  If BitAND(GUICtrlRead($shutdown), $GUI_CHECKED) = $GUI_CHECKED Then
    GUICtrlSetState(-1, $GUI_DISABLE)
  EndIf
EndIf

;  Start button
$txtypos = $txtypos + 3.5 * $txtyoffset
$btn_start = GUICtrlCreateButton("Start", $txtxoffset, $txtypos, $btnwidth, $btnheight)
GUICtrlSetResizing (-1, $GUI_DOCKLEFT + $GUI_DOCKBOTTOM)

;  Exit button
If ShowGUIInGerman() Then
  $btn_exit = GUICtrlCreateButton("Ende", $groupwidth - $btnwidth + $txtxoffset, $txtypos, $btnwidth, $btnheight)
Else
  $btn_exit = GUICtrlCreateButton("Exit", $groupwidth - $btnwidth + $txtxoffset, $txtypos, $btnwidth, $btnheight)
EndIf
GUICtrlSetResizing (-1, $GUI_DOCKRIGHT + $GUI_DOCKBOTTOM)

; GUI message loop
GUISetState()
If NOT WSHAvailable() Then
  If ShowGUIInGerman() Then
    MsgBox(0x2010, "Fehler", "Der Windows Script Host ist deaktiviert. Bitte pr�fen Sie die Registrierungswerte" _
                     & @LF & "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings\Enabled und" _
                     & @LF & "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings\Enabled")
    Exit(1)
  Else
    MsgBox(0x2010, "Error", "Windows Script Host is disabled on this machine. Please check registry values" _
                    & @LF & "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings\Enabled and" _
                    & @LF & "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings\Enabled")
    Exit(1)
  EndIf
EndIf
If $scriptdir = "" Then
  If ShowGUIInGerman() Then
    MsgBox(0x2010, "Fehler", "Dem Skript-Pfad " & @ScriptDir _
                     & @LF & "konnte kein Laufwerksbuchstabe zugewiesen werden.")
    Exit(1)
  Else
    MsgBox(0x2010, "Error", "Unable to assign a drive letter" _
                    & @LF & "to the script path " & @ScriptDir)
    Exit(1)
  EndIf
EndIf
If NOT PathValid($scriptdir) Then
  If ShowGUIInGerman() Then
    MsgBox(0x2010, "Fehler", "Der Skript-Pfad darf nicht mehr als " & $path_max_length & " Zeichen lang sein und" _
                     & @LF & "darf keines der folgenden Zeichen enthalten: " & $path_invalid_chars)
    Exit(1)
  Else
    MsgBox(0x2010, "Fehler", "The script path must not be more than " & $path_max_length & " characters long and" _
                     & @LF & "must not contain any of the following characters: " & $path_invalid_chars)
    Exit(1)
  EndIf
EndIf
If ( (StringRight(EnvGet("TEMP"), 1) = "\") OR (StringRight(EnvGet("TEMP"), 1) = ":") ) Then
  If ShowGUIInGerman() Then
    MsgBox(0x2010, "Fehler", "Die Umgebungsvariable TEMP" & @LF & "enth�lt einen abschlie�enden Backslash ('\')" & @LF & "oder einen abschlie�enden Doppelpunkt (':').")
    Exit(1)
  Else
    MsgBox(0x2010, "Error", "The environment variable TEMP" & @LF & "contains a trailing backslash ('\')" & @LF & "or a trailing colon (':').")
    Exit(1)
  EndIf
EndIf
While 1
  Switch GUIGetMsg()
    Case $GUI_EVENT_CLOSE    ; Window closed
      If $mapped Then
        DriveMapDel($scriptdir)
      EndIf
      ExitLoop

    Case $btn_exit           ; Exit Button pressed
      If $mapped Then
        DriveMapDel($scriptdir)
      EndIf
      ExitLoop

    Case $ie7                ; IE7 check box toggled
      If (BitAND(GUICtrlRead($ie7), $GUI_CHECKED) = $GUI_CHECKED) Then
        GUICtrlSetState($ie8, $GUI_UNCHECKED + $GUI_DISABLE)
        GUICtrlSetState($ie9, $GUI_UNCHECKED + $GUI_DISABLE)
      Else
        If ( (IEVersion() = "8") OR (IEVersion() = "9") ) Then
          GUICtrlSetState($ie8, $GUI_UNCHECKED + $GUI_DISABLE)
        Else
          GUICtrlSetState($ie8, $GUI_ENABLE)
        EndIf
        If ( (@OSVersion = "WIN_XP") OR (@OSVersion = "WIN_2003") OR (IEVersion() = "9") ) Then
          GUICtrlSetState($ie9, $GUI_UNCHECKED + $GUI_DISABLE)
        Else
          GUICtrlSetState($ie9, $GUI_ENABLE)
        EndIf
      EndIf

    Case $ie8                ; IE8 check box toggled
      If (BitAND(GUICtrlRead($ie8), $GUI_CHECKED) = $GUI_CHECKED) Then
        GUICtrlSetState($ie7, $GUI_UNCHECKED + $GUI_DISABLE)
        GUICtrlSetState($ie9, $GUI_UNCHECKED + $GUI_DISABLE)
      Else
        If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
          OR (IEVersion() = "7") OR (IEVersion() = "8") OR (IEVersion() = "9") ) Then
          GUICtrlSetState($ie7, $GUI_UNCHECKED + $GUI_DISABLE)
        Else
          GUICtrlSetState($ie7, $GUI_ENABLE)
        EndIf
        If ( (@OSVersion = "WIN_XP") OR (@OSVersion = "WIN_2003") OR (IEVersion() = "9") ) Then
          GUICtrlSetState($ie9, $GUI_UNCHECKED + $GUI_DISABLE)
        Else
          GUICtrlSetState($ie9, $GUI_ENABLE)
        EndIf
      EndIf

    Case $ie9                ; IE9 check box toggled
      If (BitAND(GUICtrlRead($ie9), $GUI_CHECKED) = $GUI_CHECKED) Then
        GUICtrlSetState($ie7, $GUI_UNCHECKED + $GUI_DISABLE)
        GUICtrlSetState($ie8, $GUI_UNCHECKED + $GUI_DISABLE)
      Else
        If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
          OR (IEVersion() = "7") OR (IEVersion() = "8") OR (IEVersion() = "9") ) Then
          GUICtrlSetState($ie7, $GUI_UNCHECKED + $GUI_DISABLE)
        Else
          GUICtrlSetState($ie7, $GUI_ENABLE)
        EndIf
        If ( (IEVersion() = "8") OR (IEVersion() = "9") ) Then
          GUICtrlSetState($ie8, $GUI_UNCHECKED + $GUI_DISABLE)
        Else
          GUICtrlSetState($ie8, $GUI_ENABLE)
        EndIf
      EndIf

    Case $dotnet35             ; .NET 3.5 check box toggled
      If ( (BitAND(GUICtrlRead($dotnet35), $GUI_CHECKED) = $GUI_CHECKED) _
       AND (@OSVersion <> "WIN_7") AND (@OSVersion <> "WIN_2008R2") AND (@OSVersion <> "WIN_8") AND (@OSVersion <> "WIN_2012") _
       AND (PowerShellVersion() <> $target_version_psh) ) Then
        GUICtrlSetState($psh, $GUI_ENABLE)
      Else
        GUICtrlSetState($psh, $GUI_UNCHECKED + $GUI_DISABLE)
      EndIf

    Case $dotnet4              ; .NET 4 check box toggled
      If ( (BitAND(GUICtrlRead($dotnet4), $GUI_CHECKED) = $GUI_CHECKED) _
       AND (@OSVersion <> "WIN_XP") AND (@OSVersion <> "WIN_2003") AND (@OSVersion <> "WIN_VISTA") AND (@OSVersion <> "WIN_8") AND (@OSVersion <> "WIN_2012") _
       AND (ManagementFrameworkVersion() <> $target_version_wmf) ) Then
        GUICtrlSetState($wmf, $GUI_ENABLE)
      Else
        GUICtrlSetState($wmf, $GUI_UNCHECKED + $GUI_DISABLE)
      EndIf

    Case $msse                 ; Microsoft Security Essentials check box toggled
      If (BitAND(GUICtrlRead($msse), $GUI_CHECKED) = $GUI_CHECKED) Then
        If ShowGUIInGerman() Then
          If MsgBox(0x2134, "Warnung", "Bei der Installation der Microsoft Security Essentials wird eine" _
                               & @LF & "obligate 'Windows Genuine Advantage' (WGA)-Pr�fung durchgef�hrt." _
                               & @LF & "M�chten Sie fortsetzen?") = 7 Then
            GUICtrlSetState($msse, $GUI_UNCHECKED)
          EndIf
        Else
          If MsgBox(0x2134, "Warning", "The installation of Microsoft Security Essentials performs" _
                               & @LF & "a mandatory 'Windows Genuine Advantage' (WGA) check." _
                               & @LF & "Do you wish to proceed?") = 7 Then
            GUICtrlSetState($msse, $GUI_UNCHECKED)
          EndIf
        EndIf
      EndIf

    Case $autoreboot         ; Automatic reboot check box toggled
      If ( (BitAND(GUICtrlRead($autoreboot), $GUI_CHECKED) = $GUI_CHECKED) _
       AND ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") ) ) Then
        If ShowGUIInGerman() Then
          If MsgBox(0x2134, "Warnung", "Die Option 'Automatisch neu starten und fortsetzen' deaktiviert" _
                               & @LF & "tempor�r die Benutzerkontensteuerung (UAC), falls erforderlich." _
                               & @LF & "M�chten Sie fortsetzen?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        Else
          If MsgBox(0x2134, "Warning", "The option 'Automatic reboot and recall' temporarily" _
                               & @LF & "disables the User Account Control (UAC), if required." _
                               & @LF & "Do you wish to proceed?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        EndIf
      EndIf
      If ( (BitAND(GUICtrlRead($autoreboot), $GUI_CHECKED) = $GUI_CHECKED) AND (DriveGetType($scriptdir) = "Network") ) Then
        If ShowGUIInGerman() Then
          If MsgBox(0x2134, "Warnung", @ScriptName & " wurde von einer Netzwerkfreigabe gestartet." _
                               & @LF & "Die Option 'Automatisch neu starten und fortsetzen'" _
                               & @LF & "funktioniert nur dann ohne Benutzereingriff," _
                               & @LF & "wenn diese Freigabe anonymen Zugriff erlaubt." _
                               & @LF & "M�chten Sie fortsetzen?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        Else
          If MsgBox(0x2134, "Warning", @ScriptName & " was started from a network share." _
                               & @LF & "The option 'Automatic reboot and recall'" _
                               & @LF & "does only work without user interaction," _
                               & @LF & "if this share permits anonymous access." _
                               & @LF & "Do you wish to proceed?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        EndIf
      EndIf

    Case $shutdown           ; Automatic shutdown check box toggled
      If (BitAND(GUICtrlRead($shutdown), $GUI_CHECKED) = $GUI_CHECKED) Then
        GUICtrlSetState($showlog, $GUI_UNCHECKED + $GUI_DISABLE)
      Else
        GUICtrlSetState($showlog, $GUI_ENABLE)
      EndIf

    Case $btn_start          ; Start Button pressed
      $options = IniRead($inifilename, $ini_section_misc, $ini_value_wustatusserver, "")    ; Dummy use of $options
      If $options <> "" Then
        RegWrite($reg_key_windowsupdate, $reg_val_wustatusserver, "REG_SZ", $options)
      EndIf
      $options = ""
      If BitAND(GUICtrlRead($backup), $GUI_CHECKED) <> $GUI_CHECKED Then
        $options = $options & " /nobackup"
      EndIf
      If BitAND(GUICtrlRead($rcerts), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /updatercerts"
      EndIf
      If BitAND(GUICtrlRead($ie7), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instie7"
      EndIf
      If BitAND(GUICtrlRead($ie8), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instie8"
      EndIf
      If BitAND(GUICtrlRead($ie9), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instie9"
      EndIf
      If BitAND(GUICtrlRead($cpp), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /updatecpp"
      EndIf
      If BitAND(GUICtrlRead($dx), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /updatedx"
      EndIf
      If BitAND(GUICtrlRead($mssl), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instmssl"
      EndIf
      If BitAND(GUICtrlRead($wmp), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /updatewmp"
      EndIf
      If BitAND(GUICtrlRead($dotnet35), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instdotnet35"
      EndIf
      If BitAND(GUICtrlRead($dotnet4), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instdotnet4"
      EndIf
      If BitAND(GUICtrlRead($psh), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instpsh"
      EndIf
      If BitAND(GUICtrlRead($wmf), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instwmf"
      EndIf
      If BitAND(GUICtrlRead($msse), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instmsse"
      EndIf
      If BitAND(GUICtrlRead($tsc), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /updatetsc"
      EndIf
      If BitAND(GUICtrlRead($ofc), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instofc"
      EndIf
      If BitAND(GUICtrlRead($ofv), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /instofv"
      EndIf
      If BitAND(GUICtrlRead($verify), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /verify"
      EndIf
      If ( (BitAND(GUICtrlRead($autoreboot), $GUI_DISABLE) <> $GUI_DISABLE) _
       AND (BitAND(GUICtrlRead($autoreboot), $GUI_CHECKED) = $GUI_CHECKED) ) Then
        $options = $options & " /autoreboot"
      EndIf
      If BitAND(GUICtrlRead($shutdown), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /shutdown"
      EndIf
      If BitAND(GUICtrlRead($showlog), $GUI_CHECKED) = $GUI_CHECKED Then
        $options = $options & " /showlog"
      EndIf
      If IniRead($inifilename, $ini_section_installation, $ini_value_all, $disabled) = $enabled Then
        $options = $options & " /all"
      EndIf
      If IniRead($inifilename, $ini_section_installation, $ini_value_excludestatics, $disabled) = $enabled Then
        $options = $options & " /excludestatics"
      EndIf
      If IniRead($inifilename, $ini_section_installation, $ini_value_skipdynamic, $disabled) = $enabled Then
        $options = $options & " /skipdynamic"
      EndIf
      If (@OSArch <> "X86") Then
        DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1)
      EndIf
      If Run(@ComSpec & " /D /C Update.cmd" & $options, $scriptdir, @SW_HIDE) = 0 Then
        If ShowGUIInGerman() Then
          MsgBox(0x2010, "Fehler", "Fehler #" & @error & " beim Aufruf von" _
                           & @LF & @ComSpec & " /D /C Update.cmd" & $options & " in" _
                           & @LF & $scriptdir & ".")
        Else
          MsgBox(0x2010, "Error", "Error #" & @error & " when calling" _
                          & @LF & @ComSpec & " /D /C Update.cmd" & $options & " in" _
                          & @LF & $scriptdir & ".")
        EndIf
      Else
        ExitLoop
      EndIf
  EndSwitch
WEnd
Exit

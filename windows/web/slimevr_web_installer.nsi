Unicode True

!include x64.nsh 		; For RunningX64 check
!include LogicLib.nsh	; For conditional operators
!include nsDialogs.nsh  ; For custom pages
!include FileFunc.nsh   ; For GetTime function
!include MUI2.nsh

!define SF_USELECTED  0
!define MUI_ICON "run.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "logo.bmp"
!define MUI_HEADERIMAGE_BITMAP_STRETCH "NoStretchNoCrop"
!define MUI_HEADERIMAGE_RIGHT

# Define name of installer
Name "SlimeVR"

SpaceTexts none # Don't show required disk space since we don't know for sure
SetOverwrite on
SetCompressor lzma  # Use LZMA Compression algorithm, compression quality is better.

OutFile "slimevr_web_installer.exe"

# Define installation directory
InstallDir "$PROGRAMFILES\SlimeVR Server" ; $InstDir default value. Defaults to user's local appdata to avoid asking admin rights

ShowInstDetails show
ShowUninstDetails show

BrandingText "SlimeVR Installer 0.1.7"

# Admin rights are required for:
# 1. Removing Start Menu shortcut in Windows 7+
# 2. Adding/removing firewall rules
# 3. USB drivers installation
RequestExecutionLevel admin

# Start page installer actions
Var REPAIR
Var UPDATE
Var SELECTED_INSTALLER_ACTION

# End page actions
Var CREATE_DESKTOP_SHORTCUT
Var CREATE_STARTMENU_SHORTCUTS
Var OPEN_DOCUMENTATION

# Detected Steam folder
Var STEAMDIR

# Init functions start #
Function .onInit
    InitPluginsDir
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM SOFTWARE\WOW6432Node\Valve\Steam InstallPath
    ${Else}
        ReadRegStr $0 HKLM SOFTWARE\Valve\Steam InstallPath
    ${EndIf}
    StrCpy $STEAMDIR $0
FunctionEnd

# Detect Steam installation and just write path that we need to remove during uninstall (if present)
Function un.onInit
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM SOFTWARE\WOW6432Node\Valve\Steam InstallPath
    ${Else}
        ReadRegStr $0 HKLM SOFTWARE\Valve\Steam InstallPath
    ${EndIf}
    StrCpy $STEAMDIR $0
FunctionEnd

# Clean up on exit
Function cleanTemp
    Delete "$TEMP\slimevr-openvr-driver-win64.zip"
    Delete "$TEMP\SlimeVR-win64.zip"
    Delete "$TEMP\OpenJDK17U-jre_x64_windows_hotspot_17.0.5_8.zip"
    Delete "$TEMP\OpenJDK17U-jre_x86-32_windows_hotspot_17.0.5_8.zip"
    Delete "$TEMP\SlimeVR-Feeder-App-win64.zip"
    RMDir /r "$TEMP\slimevr-openvr-driver-win64"
    RMDir /r "$TEMP\SlimeVR"
    RMDir /r "$TEMP\OpenJDK17U-jre_x86-32_windows_hotspot_17.0.5_8"
    RMDir /r "$TEMP\OpenJDK17U-jre_x64_windows_hotspot_17.0.5_8"
    RMDir /r "$TEMP\slimevr_usb_drivers_inst"
    RMDir /r "$TEMP\SlimeVR-Feeder-App-win64"
FunctionEnd

Function .onInstFailed
    ${If} $SELECTED_INSTALLER_ACTION == ""
        Call cleanInstDir
    ${Endif}
FunctionEnd

Function .onGUIEnd
    Call cleanTemp
FunctionEnd

Function cleanInstDir
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    Delete "$INSTDIR\slimevr*"
    Delete "$INSTDIR\firewall*.bat"
    Delete "$INSTDIR\MagnetoLib.dll"
    Delete "$INSTDIR\steamvr.ps1"
    Delete "$INSTDIR\log*"
    Delete "$INSTDIR\*.log"
    Delete "$INSTDIR\*.lck"
    Delete "$INSTDIR\vrconfig.yml"
    Delete "$INSTDIR\LICENSE*"

    RMDir /r "$INSTDIR\Recordings"
    RMdir /r "$INSTDIR\jre"
    RMdir /r "$INSTDIR\driver"
    RMDir /r "$INSTDIR\logs"
    RMdir /r "$INSTDIR\Feeder-App"

    RMDir $INSTDIR
FunctionEnd
# Init functions end #

Page Custom startPage startPageLeave

!define MUI_PAGE_CUSTOMFUNCTION_PRE componentsPre
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_CUSTOMFUNCTION_PRE installerActionPre
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_PAGE_CUSTOMFUNCTION_PRE cleanTemp ; Clean temp on pre-install to avoid any leftover files failing the installation, temp files will be removed in .onGUIEnd
!insertmacro MUI_PAGE_INSTFILES

Page Custom endPage endPageLeave

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "SimpChinese"

LangString START_PAGE_TITLE ${LANG_ENGLISH} "欢迎"
LangString START_PAGE_SUBTITLE ${LANG_ENGLISH} "欢迎使用 SlimeVR 安装程序!"

Function startPage
    !insertmacro MUI_HEADER_TEXT $(START_PAGE_TITLE) $(START_PAGE_SUBTITLE)
    nsDialogs::Create 1018
    Pop $0

    ${If} $0 == error
        Abort
    ${EndIf}

    ReadRegStr $0 HKLM Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR InstallLocation
    ${If} $0 != ""
        StrCpy $INSTDIR $0

        ${NSD_CreateLabel} 0 0 100% 20u '在 "$0" 目录下检测到已经安装. 请选择一个选项.'
        ${NSD_CreateRadioButton} 0 40u 100% 10u "更新"
        Pop $UPDATE
        ${NSD_CreateRadioButton} 0 55u 100% 10u "修复"
        Pop $REPAIR

        ${If} $SELECTED_INSTALLER_ACTION == "update"
            SendMessage $UPDATE ${BM_SETCHECK} 1 0
        ${ElseIf} $SELECTED_INSTALLER_ACTION == "repair"
            SendMessage $REPAIR ${BM_SETCHECK} 1 0
        ${Else}
            SendMessage $UPDATE ${BM_SETCHECK} 1 0
        ${EndIf}
    ${Else}
        ${NSD_CreateLabel} 0 0 100% 50u "点击下一步继续安装."
        Pop $0
    ${EndIf}

    nsDialogs::Show

FunctionEnd

Function startPageLeave

  ${NSD_GetState} $UPDATE $0
  ${NSD_GetState} $REPAIR $1

  ${If} $0 = 1
    StrCpy $SELECTED_INSTALLER_ACTION "update"
  ${ElseIf} $1 = 1
    StrCpy $SELECTED_INSTALLER_ACTION "repair"
  ${EndIf}

FunctionEnd

Function endPage

    nsDialogs::Create 1018
    Pop $0

    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 12u "安装完成!"
    Pop $0

    ${NSD_CreateCheckbox} 0 25u 100% 10u "查看 SlimeVR 文档"
    Pop $OPEN_DOCUMENTATION
    # Don't open documentation if we're updating
    ${If} $SELECTED_INSTALLER_ACTION == ""
        ${NSD_Check} $OPEN_DOCUMENTATION
    ${EndIf}

    ${NSD_CreateCheckbox} 0 40u 100% 10u "创建桌面图标"
    Pop $CREATE_DESKTOP_SHORTCUT
    ${NSD_Check} $CREATE_DESKTOP_SHORTCUT
    ${NSD_CreateCheckbox} 0 55u 100% 10u "创建开始菜单"
    Pop $CREATE_STARTMENU_SHORTCUTS
    ${NSD_Check} $CREATE_STARTMENU_SHORTCUTS

    nsDialogs::Show

FunctionEnd

Function endPageLeave

    SetOutPath $INSTDIR

    ${NSD_GetState} $CREATE_STARTMENU_SHORTCUTS $0
    ${NSD_GetState} $CREATE_DESKTOP_SHORTCUT $1
    ${NSD_GetState} $OPEN_DOCUMENTATION $2

    ${If} $0 = 1
        CreateDirectory "$SMPROGRAMS\SlimeVR Server"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\Uninstall SlimeVR Server.lnk" "$INSTDIR\uninstall.exe"
        CreateShortcut "$SMPROGRAMS\SlimeVR Server\SlimeVR Server.lnk" "$INSTDIR\slimevr.exe" ""
    ${Else}
        Delete "$SMPROGRAMS\Uninstall SlimeVR Server.lnk"
        Delete "$SMPROGRAMS\SlimeVR Server.lnk"
        RMdir /r "$SMPROGRAMS\SlimeVR Server"
    ${Endif}

    ${If} $1 = 1
        CreateShortcut "$DESKTOP\SlimeVR Server.lnk" "$INSTDIR\slimevr.exe" ""
    ${Else}
        Delete "$DESKTOP\SlimeVR Server.lnk"
    ${EndIf}
    ${If} $2 = 1
        ExecShell "open" "https://docs.slimevr.dev/server-setup/slimevr-setup.html"
    ${EndIf}

FunctionEnd

# Pre-hook for directory selection function
Function installerActionPre
    # Skip directory selection if existing installation was detected and user selected an action
    ${If} $SELECTED_INSTALLER_ACTION != ""
        Abort
    ${EndIf}
FunctionEnd

# GetTime function macro to get datetime
!insertmacro GetTime

Function DumpLog
  Exch $5
  Push $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $6

  FindWindow $0 "#32770" "" $HWNDPARENT
  GetDlgItem $0 $0 1016
  StrCmp $0 0 exit
  FileOpen $5 $5 "w"
  StrCmp $5 "" exit
    SendMessage $0 ${LVM_GETITEMCOUNT} 0 0 $6
    System::Alloc ${NSIS_MAX_STRLEN}
    Pop $3
    StrCpy $2 0
    System::Call "*(i, i, i, i, i, i, i, i, i) i \
      (0, 0, 0, 0, 0, r3, ${NSIS_MAX_STRLEN}) .r1"
    loop: StrCmp $2 $6 done
      System::Call "User32::SendMessageA(i, i, i, i) i \
        ($0, ${LVM_GETITEMTEXT}, $2, r1)"
      System::Call "*$3(&t${NSIS_MAX_STRLEN} .r4)"
      FileWrite $5 "$4$\r$\n"
      IntOp $2 $2 + 1
      Goto loop
    done:
      FileClose $5
      System::Free $1
      System::Free $3
  exit:
    Pop $6
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
    Exch $5
FunctionEnd

Section "SlimeVR Server" SEC_SERVER
    SectionIn RO

    SetOutPath $INSTDIR

    DetailPrint "正在下载 SlimeVR Server..."
    NScurl::http GET "https://ghproxy.com/https://github.com/SlimeVR/SlimeVR-Server/releases/latest/download/SlimeVR-win64.zip" "$TEMP\SlimeVR-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "下载 SlimeVR 失败. Reason: $0."
    ${EndIf}
    DetailPrint "已下载!"

    nsisunz::Unzip "$TEMP\SlimeVR-win64.zip" "$TEMP\SlimeVR\"
    Pop $0
    DetailPrint "解压成功 $0."

    ${If} $SELECTED_INSTALLER_ACTION == "update"
        Delete "$INSTDIR\slimevr-ui.exe"
    ${EndIf}

    DetailPrint "正在复制 SlimeVR Server 到安装目录..."
    CopyFiles /SILENT "$TEMP\SlimeVR\SlimeVR\*" $INSTDIR

    IfFileExists "$INSTDIR\slimevr-ui.exe" found not_found
    found:
        Delete "$INSTDIR\slimevr.exe"
        Rename "$INSTDIR\slimevr-ui.exe" "$INSTDIR\slimevr.exe"
    not_found:

    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"

    # Create the uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Webview2" SEC_WEBVIEW
    SectionIn RO

    # Read Only protects it from Installing when it is not needed
    DetailPrint "下载 webview2!"
    NScurl::http GET "https://go.microsoft.com/fwlink/p/?LinkId=2124703" "$TEMP\MicrosoftEdgeWebView2RuntimeInstaller.exe" /CANCEL /RESUME /END

    DetailPrint "安装 webview2!"
    nsExec::ExecToLog '"$TEMP\MicrosoftEdgeWebView2RuntimeInstaller.exe" /silent /install' $0
    Pop $0
    DetailPrint "安装完成 $0."
    ${If} $0 != 0
        Abort "webview 2 安装失败"
    ${EndIf}

SectionEnd

Section "Java JRE" SEC_JRE
    # SectionIn RO
    
    Var /GLOBAL DownloadedJreFile
    DetailPrint "正在下载 Java JRE 17..."
    NScurl::http GET "https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jre/x64/windows/OpenJDK17U-jre_x64_windows_hotspot_17.0.5_8.zip" "$TEMP\OpenJDK17U-jre_x64_windows_hotspot_17.0.5_8.zip" /CANCEL /RESUME /END
    StrCpy $DownloadedJreFile "OpenJDK17U-jre_x64_windows_hotspot_17.0.5_8"
    
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "下载 Java JRE 17 失败. Reason: $0."
    ${EndIf}
    DetailPrint "下载成功!"

    DetailPrint "解压 Java JRE 17 到安装目录...."
    nsisunz::Unzip "$TEMP\$DownloadedJreFile.zip" "$TEMP\$DownloadedJreFile\"
    Pop $0
    DetailPrint "解压成功 $0."
    CopyFiles /SILENT "$TEMP\$DownloadedJreFile\jdk-17.0.5+8-jre\*" "$INSTDIR\jre"
SectionEnd

Section "SteamVR Driver" SEC_VRDRIVER
    SetOutPath $INSTDIR

    DetailPrint "下载 SteamVR 驱动..."
    NScurl::http GET "https://ghproxy.com/https://github.com/SlimeVR/SlimeVR-OpenVR-Driver/releases/latest/download/slimevr-openvr-driver-win64.zip" "$TEMP\slimevr-openvr-driver-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "下载 SteamVR Driver 驱动失败. Reason: $0."
    ${EndIf}
    DetailPrint "下载成功!"

    DetailPrint "解压文件中..."
    nsisunz::Unzip "$TEMP\slimevr-openvr-driver-win64.zip" "$TEMP\slimevr-openvr-driver-win64\"
    Pop $0
    DetailPrint "解压成功 $0."

    # Include SteamVR powershell script to register/unregister driver
    File "steamvr.ps1"

    DetailPrint "复制 SteamVR 驱动到 SteamVR..."
    # If powershell is present - rely on automatic detection.
    ${DisableX64FSRedirection}
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "$TEMP\slimevr-openvr-driver-win64\slimevr"' $0
    ${EnableX64FSRedirection}
    Pop $0
    ${If} $0 != 0
        nsDialogs::SelectFolderDialog "Specify a path to your SteamVR folder" "$STEAMDIR\steamapps\common\SteamVR"
        Pop $0
        ${If} $0 == "error"
            Abort "复制 SteamVR 驱动失败."
        ${Endif}
        CopyFiles /SILENT "$TEMP\slimevr-openvr-driver-win64\slimevr" "$0\drivers\slimevr"
    ${EndIf}

SectionEnd

Section "SlimeVR Feeder App" SEC_FEEDER_APP
    SetOutPath $INSTDIR

    DetailPrint "下载 SlimeVR Feeder App..."
    NScurl::http GET "https://ghproxy.com/https://github.com/SlimeVR/SlimeVR-Feeder-App/releases/latest/download/SlimeVR-Feeder-App-win64.zip" "$TEMP\SlimeVR-Feeder-App-win64.zip" /CANCEL /RESUME /END
    Pop $0 ; Status text ("OK" for success)
    ${If} $0 != "OK"
        Abort "下载 SlimeVR Feeder App 失败. Reason: $0."
    ${EndIf}
    DetailPrint "下载成功!"

    DetailPrint "解压文件中..."
    nsisunz::Unzip "$TEMP\SlimeVR-Feeder-App-win64.zip" "$TEMP"
    Pop $0
    DetailPrint "解压成功 $0."

    DetailPrint "复制 SlimeVR Feeder App..."
    CopyFiles /SILENT "$TEMP\SlimeVR-Feeder-App-win64\*" "$INSTDIR\Feeder-App"

    DetailPrint "Installing SlimeVR Feeder App driver..."
    nsExec::ExecToLog '"$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" --install'
SectionEnd

SectionGroup /e "USB drivers" SEC_USBDRIVERS

    Section "CP210x driver" SEC_CP210X
        # CP210X drivers (NodeMCU v2)
        SetOutPath "$TEMP\slimevr_usb_drivers_inst\CP210x"
        DetailPrint "Installing CP210x driver..."
        File /r "CP210x\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$TEMP\slimevr_usb_drivers_inst\CP210x\slabvcp.inf"' $0
        ${EnableX64FSRedirection}
        Pop $0
        ${If} $0 == 0
            DetailPrint "成功!"
        ${ElseIf} $0 == 259
            DetailPrint "没有找到匹配该驱动的设备，或您已安装了一个更新版本的驱动."
        ${ElseIf} $0 == 3010
            DetailPrint "安装成功，需重启系统生效."
        ${Else}
            Abort "Failed to install CP210x driver. Error code: $0."
        ${Endif}
    SectionEnd

    Section "CH340 driver" SEC_CH340
        # CH340 drivers (NodeMCU v3)
        SetOutPath "$TEMP\slimevr_usb_drivers_inst\CH341SER"
        DetailPrint "Installing CH340 driver..."
        File /r "CH341SER\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$TEMP\slimevr_usb_drivers_inst\CH341SER\CH341SER.INF"' $0
        ${EnableX64FSRedirection}
        Pop $0
        ${If} $0 == 0
            DetailPrint "成功!"
        ${ElseIf} $0 == 259
            DetailPrint "没有找到匹配该驱动的设备，或您已安装了一个更新版本的驱动."
        ${ElseIf} $0 == 3010
            DetailPrint "安装成功，需重启系统生效."
        ${Else}
            Abort "Failed to install CH340 driver. Error code: $0."
        ${Endif}
    SectionEnd

    Section /o "CH9102x driver" SEC_CH9102X
        # CH343 drivers (NodeMCU v2.1, some NodeMCU v3?)
        SetOutPath "$TEMP\slimevr_usb_drivers_inst\CH343SER"
        DetailPrint "Installing CH910x driver..."
        File /r "CH343SER\*"
        ${DisableX64FSRedirection}
        nsExec::Exec '"$SYSDIR\PnPutil.exe" -i -a "$TEMP\slimevr_usb_drivers_inst\CH343SER\CH343SER.INF"' $0
        ${EnableX64FSRedirection}
        Pop $0
        ${If} $0 == 0
            DetailPrint "成功!"
        ${ElseIf} $0 == 259
            DetailPrint "没有找到匹配该驱动的设备，或您已安装了一个更新版本的驱动."
        ${ElseIf} $0 == 3010
            DetailPrint "安装成功，需重启系统生效."
        ${Else}
            Abort "Failed to install CH910x driver. Error code: $0."
        ${Endif}
    SectionEnd

SectionGroupEnd

Section "-" SEC_FIREWALL
    ${If} $SELECTED_INSTALLER_ACTION == "repair"
        DetailPrint "移除 SlimeVR Server 防火墙规则...."
        nsExec::Exec '"$INSTDIR\firewall_uninstall.bat"'
    ${Endif}

    DetailPrint "添加 SlimeVR Server 到防火墙规则...."
    nsExec::Exec '"$INSTDIR\firewall.bat"'
SectionEnd

Section "-" SEC_REGISTERAPP
    DetailPrint "正在写入注册表..."
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "DisplayName" "SlimeVR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "DisplayIcon" "$INSTDIR\slimevr.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "HelpLink" "https://docs.slimevr.dev/"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "URLInfoAbout" "https://slimevr.dev/"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "URLUpdateInfo" "https://github.com/SlimeVR/SlimeVR-Installer/releases"
SectionEnd

Section
    # Grant all users full access to the installation folder to avoid using elevated rights
    # when installing to folders with limited access
    AccessControl::GrantOnFile $INSTDIR "(BU)" "FullAccess"
    Pop $0

    # Add/update installation date
    ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR" \
                    "InstallDate" "$2$1$0"

    # Write install.log
    StrCpy $0 "$INSTDIR\install.log"
    Push $0
    Call DumpLog
SectionEnd

Function componentsPre
    ${If} $SELECTED_INSTALLER_ACTION == "update"
        SectionSetFlags ${SEC_FIREWALL} 0
        SectionSetFlags ${SEC_REGISTERAPP} 0
        SectionSetFlags ${SEC_JRE} ${SF_SELECTED}
        SectionSetFlags ${SEC_WEBVIEW} ${SF_SELECTED}
        SectionSetFlags ${SEC_USBDRIVERS} ${SF_SECGRP}
        SectionSetFlags ${SEC_SERVER} ${SF_SELECTED}
    ${EndIf}

    ${If} $STEAMDIR == ""
        MessageBox MB_OK $(DESC_STEAM_NOTFOUND)
        SectionSetFlags ${SEC_VRDRIVER} ${SF_USELECTED}|${SF_RO}
        SectionSetFlags ${SEC_FEEDER_APP} ${SF_USELECTED}|${SF_RO}
    ${Else}
        SectionSetFlags ${SEC_VRDRIVER} ${SF_SELECTED}
        SectionSetFlags ${SEC_FEEDER_APP} ${SF_SELECTED}
    ${EndIf}

    # Detect WebView2
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM "SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
        ReadRegStr $1 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
    ${Else}
        ReadRegStr $0 HKLM "SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
        ReadRegStr $1 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
    ${EndIf}

    ${If} $0 == ""
    ${AndIf} $1 == ""
        SectionSetFlags ${SEC_WEBVIEW} ${SF_SELECTED}|${SF_RO}
    ${Else}
        SectionSetFlags ${SEC_WEBVIEW} ${SF_USELECTED}|${SF_RO}
    ${EndIf}
FunctionEnd

Section "-un.SlimeVR Server" un.SEC_SERVER
    # Remove the shortcuts
    RMdir /r "$SMPROGRAMS\SlimeVR Server"
    # Remove separate shortcuts introduced with first release
    Delete "$SMPROGRAMS\Uninstall SlimeVR Server.lnk"
    Delete "$SMPROGRAMS\SlimeVR Server.lnk"
    Delete "$DESKTOP\SlimeVR Server.lnk"
    Delete "$INSTDIR\slimevr-ui.exe"
    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\run.ico"
    # Ignore errors on the files above, they are optional to remove and may not even exist
    ClearErrors
    Delete "$INSTDIR\slimevr*"
    Delete "$INSTDIR\slimevr.jar"
    Delete "$INSTDIR\MagnetoLib.dll"
    Delete "$INSTDIR\log*"
    Delete "$INSTDIR\*.log"
    Delete "$INSTDIR\*.lck"
    Delete "$INSTDIR\vrconfig.yml"
    Delete "$INSTDIR\LICENSE*"
    Delete "$INSTDIR\ThirdPartyNotices.txt"

    RMDir /r "$INSTDIR\Recordings"
    RMdir /r "$INSTDIR\jre"
    RMDir /r "$INSTDIR\logs"

    IfErrors fail success
    fail:
        Abort "移除 SlimeVR Server 文件失败. 请确认 SlimeVR Server 没有在运行."
    success:
SectionEnd

Section "-un.SteamVR Driver" un.SEC_VRDRIVER
    ${DisableX64FSRedirection}
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$INSTDIR\steamvr.ps1" -SteamPath "$STEAMDIR" -DriverPath "slimevr" -Uninstall' $0
    ${EnableX64FSRedirection}
    Pop $0
    ${If} $0 != 0
        DetailPrint "移除 SteamVR 驱动失败."
    ${EndIf}
    Delete "$INSTDIR\steamvr.ps1"
SectionEnd

Section "-un.SlimeVR Feeder App" un.SEC_FEEDER_APP
    IfFileExists "$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" found not_found
    found:
        DetailPrint "正在移除 SlimeVR Feeder App..."
        nsExec::ExecToLog '"$INSTDIR\Feeder-App\SlimeVR-Feeder-App.exe" --uninstall'
        DetailPrint "移除 SlimeVR Feeder App..."
        RMdir /r "$INSTDIR\Feeder-App"
    not_found:
SectionEnd

Section "-un." un.SEC_FIREWALL
    DetailPrint "移除 SlimeVR Server 防火墙规则...."
    nsExec::Exec '"$INSTDIR\firewall_uninstall.bat"'
    Pop $0
    Delete "$INSTDIR\firewall*.bat"
SectionEnd

Section "-un." un.SEC_POST_UNINSTALL
    DetailPrint "清理安装信息..."
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlimeVR"
    Delete "$INSTDIR\uninstall.exe"
    RMDir $INSTDIR
    DetailPrint "Done."
SectionEnd

LangString DESC_SEC_SERVER ${LANG_ENGLISH} "安装最新的 SlimeVR Server."
LangString DESC_SEC_JRE ${LANG_ENGLISH} "下载和复制 Java JRE 17 到安装目录. SlimeVR Server 必须."
LangString DESC_SEC_WEBVIEW ${LANG_ENGLISH} "下载和安装 Webview2. SlimeVR GUI 必须"
LangString DESC_SEC_VRDRIVER ${LANG_ENGLISH} "安装最新的 SteamVR Driver 到 SteamVR."
LangString DESC_SEC_USBDRIVERS ${LANG_ENGLISH} "各种不同主控的 USB 驱动."
LangString DESC_SEC_FEEDER_APP ${LANG_ENGLISH} "安装 SlimeVR Feeder App 可以把 SteamVR trackers (如 Vive trackers, 手柄) 到 SlimeVR Server 中. 手臂追踪必须安装."
LangString DESC_SEC_CP210X ${LANG_ENGLISH} "安装 CP210X USB driver 适用于以下开发板: NodeMCU v2, Wemos D1 Mini."
LangString DESC_SEC_CH340 ${LANG_ENGLISH} "安装 CH340 USB driver 适用于以下开发板: NodeMCU v3, SlimeVR, Wemos D1 Mini."
LangString DESC_SEC_CH9102x ${LANG_ENGLISH} "安装 CH9102x USB driver 适用于以下开发板: NodeMCU v2.1."
LangString DESC_STEAM_NOTFOUND ${LANG_ENGLISH} "没有检测到 Steam 安装。 Steam 和 SteamVR 都需要安装且至少运行过一次才可以安装 SteamVR 驱动。"

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SERVER} $(DESC_SEC_SERVER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_JRE} $(DESC_SEC_JRE)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_WEBVIEW} $(DESC_SEC_WEBVIEW)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_VRDRIVER} $(DESC_SEC_VRDRIVER)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_USBDRIVERS} $(DESC_SEC_USBDRIVERS)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CP210X} $(DESC_SEC_CP210X)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CH340} $(DESC_SEC_CH340)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CH9102x} $(DESC_SEC_CH9102x)
!insertmacro MUI_FUNCTION_DESCRIPTION_END
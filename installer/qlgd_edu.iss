; ============================================================================
; Inno Setup script — QLGD EDU (Windows desktop)
; Biên dịch: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\qlgd_edu.iss
; Đặt phiên bản: ISCC.exe /DAppVersion=1.2.3 installer\qlgd_edu.iss
; Yêu cầu: đã chạy `flutter build windows --release` trước đó.
; ============================================================================

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define AppName "QLGD EDU"
#define AppPublisher "Khoa Quan ly Giao duc"
#define AppExe "qlgd_edu.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{A7F3C2E1-9B4D-4E6A-8C12-3F5D7E9A1B2C}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\QLGD EDU
DefaultGroupName=QLGD EDU
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#AppExe}
OutputDir=..\dist
OutputBaseFilename=qlgd_edu-setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Cài theo người dùng, không cần quyền admin.
PrivilegesRequired=lowest

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\QLGD EDU"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\QLGD EDU"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,QLGD EDU}"; Flags: nowait postinstall skipifsilent

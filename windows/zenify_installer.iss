; Inno Setup Script for Zenify
; 此腳本會將 Flutter 編譯好的 Release 資料夾打包成 Windows 安裝檔

#define MyAppName "Zenify"
#define MyAppPublisher "Zenify"
#define MyAppURL "https://github.com/ChiesiMario/Zenify"
#define MyAppExeName "zenify.exe"
#define MyBuildDir "..\build\windows\x64\runner\Release"
#define MyAppVersion GetStringFileInfo(MyBuildDir + "\" + MyAppExeName, "ProductVersion")
#define PlusPos Pos("+", MyAppVersion)
#if PlusPos > 0
  #define CleanVersion Copy(MyAppVersion, 1, PlusPos - 1)
#else
  #define CleanVersion MyAppVersion
#endif

[Setup]
; 應用程式的基本資訊
AppId={{9A2B3C4D-5E6F-7A8B-9C0D-1E2F3A4B5C6D}
AppName={#MyAppName}
AppVersion={#CleanVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; 安裝路徑預設為 C:\Program Files\Zenify
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

; 輸出的安裝檔名稱與存放位置
OutputDir=..\build\windows\x64\installer
OutputBaseFilename=Zenify-Setup-v{#CleanVersion}

; 安裝圖示與介面設定
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableWelcomePage=no

[Languages]
; 支援預設語言安裝精靈
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 載入 Release 目錄下的所有檔案
Source: "{#MyBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb"

[Icons]
; 在開始菜單與桌面建立捷徑
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; 安裝完成後提供立即執行的選項
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
; 解除安裝時自動清理開機自啟動登錄檔
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "zenify"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "Zenify"; Flags: uninsdeletevalue

[Code]
procedure KillApp();
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM zenify.exe /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup(): Boolean;
begin
  KillApp();
  Result := True;
end;

function InitializeUninstall(): Boolean;
begin
  KillApp();
  Result := True;
end;

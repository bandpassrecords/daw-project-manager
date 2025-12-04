; Script do Inno Setup para DAW Project Manager

[Setup]
; --- Informações do Aplicativo ---
AppName=DAW Project Manager
AppVersion=1.0.2
AppPublisher=DAW Project Manager Co.
AppPublisherURL=https://www.github.com/ggbecker/daw-project-manager
AppSupportURL=https://www.github.com/ggbecker/daw-project-manager
AppUpdatesURL=https://www.github.com/ggbecker/daw-project-manager
DefaultDirName={autopf}\DAW Project Manager
DefaultGroupName=DAW Project Manager
; Nome do arquivo de saída
OutputBaseFileName=DAW_Project_Manager_Installer_v{#SetupSetting("AppVersion")}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; DIRETIVA MOVIDA PARA [Setup] (Esta é a correção principal!)
SetupIconFile=app_icon.ico

; --- Seção de Arquivos (Corrigida da última interação) ---
[Files]
; Inclui todos os arquivos da pasta de release do Flutter em uma ÚNICA LINHA.
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
; Cria atalhos
Name: "{group}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"
Name: "{autodesktop}\DAW Project Manager"; Filename: "{app}\daw_project_manager.exe"

; [Run] e [Code] foram removidos pois não contêm comandos essenciais e podem causar erros de sintaxe se vazios ou mal formatados.
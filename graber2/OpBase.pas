unit OpBase;

interface

uses SysUtils, Messages, GraberU, INIFiles;

var
  FullResList: TResourceList;
  GlobalSettings: TSettingsRec;
  rootdir: string;
  profname: string = 'default.ini';
  langname: string = 'English';

{  TProxyRec = record
    UseProxy: boolean;
    Host: string;
    Port: longint;
    Auth: boolean;
    Login: string;
    Password: string;
    SavePWD: boolean;
  end;

  TDownloadRec = record
    ThreadCount: integer;
    Retries: integer;
    Interval: integer;
    BeforeU: boolean;
    BeforeP: boolean;
    AfterP: boolean;
    Debug: boolean;
  end;

  TSettingsRec = record
    Proxy: TProxyRec;
    Downl: TDownloadRec;
    OneInstance: boolean;
    TrayIcon: boolean;
    HideToTray: boolean;
    SaveConfirm: boolean;
  end;}

procedure LoadProfileSettings;
procedure SaveProfileSettings;

implementation

uses LangString;

procedure LoadProfileSettings;
var
  INI: TINIFile;
begin
  INI := TINIFile.Create(IncludeTrailingPathDelimiter(rootdir) + profname);
  with GlobalSettings do
  begin
    //OneInstance := INI.ReadBool('global','oneinstance',true);

    //Trayicon := INI.ReadBool('GUI','trayicon',true);
    //HideToTray := INI.ReadBool('GUI','hidetotray',true);
    //SaveConfirm := INI.ReadBool('GUI','saveconfirm',true);

    langname := INI.ReadString('global','language',langname);

    with Downl do
    begin
      ThreadCount := INI.ReadInteger('download','threadcount',1);
      Retries := INI.ReadInteger('download','retires',5);
      UsePerRes := INI.ReadBool('download','useperresource',true);
      PerResThreads := INI.ReadInteger('download','perresourcethreadcount',2);
      PicThreads := INI.ReadInteger('download','picturethreadcount',1);
      Debug := false;
    end;

    with Proxy do
    begin
      UseProxy := INI.ReadBool('proxy','useproxy',false);
      Host := INI.ReadString('proxy','host','');
      Port := INI.ReadInteger('proxy','port',0);
      Auth := INI.ReadBool('proxy','authetication',false);
      Login := INI.ReadString('proxy','login','');
      Password := INI.ReadString('proxy','password','');
    end;
  end;
  INI.Free;
end;

procedure SaveProfileSettings;
var
  INI: TINIFile;

begin
  INI := TINIFile.Create(IncludeTrailingPathDelimiter(rootdir) + profname);
  with GlobalSettings do
  begin

    INI.WriteString('Global','Language',langname);

    with Downl do
    begin
      INI.WriteInteger('Download','ThreadCount',ThreadCount);
      INI.WriteInteger('Download','Retires',Retries);
      INI.WriteBool('Download','UsePerResource',UsePerRes);
      INI.WriteInteger('Download','PerResourceThreadCount',PerResThreads);
      INI.WriteInteger('Download','PictureThreadCount',PicThreads);
    end;

    with Proxy do
    begin
      INI.WriteBool('Proxy','UseProxy',UseProxy);
      INI.WriteString('Proxy','Host',Host);
      INI.WriteInteger('Proxy','Port',Port);
      INI.WriteBool('Proxy','Authetication',Auth);
      INI.WriteString('Proxy','Login',Login);
      INI.WriteString('Proxy','Password',Password);
    end;
  end;
  INI.Free;
end;

initialization

FullResList := TResourceList.Create;
rootdir := ExtractFileDir(paramstr(0));

LoadProfileSettings;
LoadLang(IncludeTrailingPathDelimiter(rootdir)+IncludeTrailingPathDelimiter('languages')+langname+'.ini');

finalization

FullResList.Free;

end.

unit MyHTTP;

interface

uses IdHTTP, Classes, SysUtils, SyncObjs, Common;

type
  TMyCookieList = class(TStringList)
    public
      function GetCookieValue(CookieName,CookieDomain: string): string;
      function GetCookieByValue(CookieName,CookieDomain: string): string;
  end;

  TMyIdHTTP = class(TIdCustomHTTP)
    private
      FCookieList: TMyCookieList;
      procedure SetCookieList(Value: TMyCookieList);
    protected
      procedure DoSetCookies(AURL: String; ARequest: TIdHTTPRequest);
      procedure DoProcessCookies(ARequest: TIdHTTPRequest; AResponse: TIdHTTPResponse);
    public
{      procedure Get(AURL: string; AResponseContent: TStream;
        AIgnoreReplies: array of SmallInt);  }
      function Get(AURL: string; AResponse: TStream = nil): string;
      function Post(AURL: string; ASource: TStrings): string;
      procedure ReadCookies(url: string; AResponse: TIdHTTPResponse);
      procedure WriteCookies(url: string; ARequest: TIdHTTPRequest);
      property CookieList: TMyCookieList read FCookieList write SetCookieList;
  end;

  function CreateHTTP{(AOwner: TComponent)}: TMyIdHTTP;

implementation

function CreateHTTP{(AOwner: TComponent)}: TMyIdHTTP;
begin
  Result := TMyIdHTTP.Create{(AOwner)};
  result.HandleRedirects := true;
  result.AllowCookies := False;
  result.Request.UserAgent :=
    'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; en)';
{  result.ReadTimeout := 30000;
  result.ConnectTimeout := 10000;    }
end;

var
  cs: TCriticalSection;

function GetCookieName(Cookie: string): string;
  var i: integer;
begin
  Result:='';
  i:=Pos('=',Cookie);
  if i=0 then Exit;
  Result:=Copy(Cookie,1,i-1);
end;

function GetCookieDomain(Cookie: string): string;
  var i,j: integer;
begin
  Result:=''; Cookie := lowercase(Cookie);
  i:=Pos('domain=',Cookie);
  if i=0 then Exit;
{  j := PosEx('www.',Cookie,i + 1);
  if j > 0 then
    i := i + 4;    }
  j:=CharPos(Cookie,';',[],i);
  if j=0 then j:=Length(Cookie)+1;
  Result:=Copy(Cookie,i+7,j-i-7);
  // Remove dot
{  if (Result<>'') and (Result[1]='.') then
    Result:=Copy(Result,2,Length(Result)-1);   }
end;

function GetURLDomain(url: string): string;
  var i,j,l: integer;
begin
  Result:=SysUtils.StringReplace(LowerCase(url),'http://','',[]);
//  Result:=SysUtils.StringReplace(Result,'www.','.',[]);
  if Pos('www.',Result) = 1 then
    i:=CharPos(Result,'.',[],4)
  else
    i := Pos('.',Result);
  if i=0 then Exit;
  j:=CharPos(Result,'/',[],i);
  if j=0 then j:=CharPos(Result,'\',[],i);
  if j>0 then Result:=Copy(Result,1,j-1);
  j:=0;
  l:=Length(Result);
  for i:=1 to l do
    if Result[i]='.' then inc(j);
  if j>1 then
  begin
    j:=0;
    for i:=l downto 1 do
    if Result[i]='.' then
    begin
      inc(j);
      if j=2 then
      begin
        Result:=Copy(Result,i+1,l-1);
        Exit;
      end;
    end;
  end;
end;

function GetCookieValue(Cookie: String): string;
begin
  Result:='';
  if Pos('=',Cookie) = 0 then Exit;
  Result := CopyFromTo(Cookie,'=',';');
end;

function TMyCookieList.GetCookieValue(CookieName,CookieDomain: string): string;
var i: integer;
begin
  Result := '';
  for i := 0 to Self.Count - 1 do
  if (GetCookieDomain(Self[i])=CookieDomain)
  and (GetCookieName(Self[i])=CookieName) then
  begin
    Result := MyHTTP.GetCookieValue(Self[i]);
    Exit
  end;
end;

function TMyCookieList.GetCookieByValue(CookieName,CookieDomain: string): string;
var i: integer;
begin
  Result := '';
  for i := 0 to Self.Count - 1 do
  if (GetCookieDomain(Self[i])=CookieDomain)
  and (GetCookieName(Self[i])=CookieName) then
  begin
    Result := Self[i];
    Exit
  end;
end;

function TMyIdHTTP.Get(AURL: string; AResponse: TStream): string;
begin
{  if Assigned(FCookieList) then
    WriteCookies(AURL); }
  if AResponse = nil then
    Result := inherited Get(AURL)
  else
    inherited Get(AURL,AResponse);
{  if Assigned(FCookieList) then
    ReadCookies(AURL);  }
end;

function TMyIdHTTP.Post(AURL: string; ASource: TStrings): string;
begin
{  if Assigned(FCookieList) then
    WriteCookies(AURL);  }
  Result := inherited Post(AURL,ASource);
{  if Assigned(FCookieList) then
    ReadCookies(AURL);      }
end;

procedure TMyIdHTTP.ReadCookies(url: string; AResponse: TIdHTTPResponse);
  var i: integer;
      Cookie: string;

  function DelleteIfExist(Cookie: string): boolean;
    var i: integer;
  begin
    Result:=false;
    for i := 0 to FCookieList.Count - 1 do
    if (GetCookieDomain(FCookieList[i])=GetCookieDomain(Cookie))
    and (GetCookieName(FCookieList[i])=GetCookieName(Cookie)) then
    begin
      FCookieList.Delete(i);
      Exit;
    end;
  end;

begin
  for i := 0 to AResponse.RawHeaders.Count - 1 do
  if Pos('Set-Cookie: ',AResponse.RawHeaders[i])>0 then
  begin
    Cookie:=SysUtils.StringReplace(AResponse.RawHeaders[i],'Set-Cookie: ','',[]);
    if GetCookieDomain(Cookie)='' then Cookie:=Cookie+'; domain='+GetURLDomain(url);
    DelleteIfExist(Cookie);
    FCookieList.Add(Cookie);
  end;
end;

procedure TMyIdHTTP.WriteCookies(url: string;  ARequest: TIdHTTPRequest);
  var i,j: integer;
      Cookies: string;
      s: string;
begin
  URL := GetURLDomain(URL);
  if (length(url) > 0) and ((pos('www.',lowercase(url)) = 1) or (url[1] = '.')) then
    URL := DeleteTo(url,'.');

  for i := 0 to FCookieList.Count - 1 do
  begin
    s := GetCookieDomain(FCookieList[i]);
    if (length(s) > 0) and ((pos('www.',lowercase(s)) = 1) or (s[1] = '.')) then
      s := DeleteTo(s,'.');
    if s = url then
    begin
      j:=Pos(';',FCookieList[i]);
      Cookies:=Cookies+Copy(FCookieList[i],1,j)+' ';
    end;
  end;
  if Cookies<>'' then
  begin
    Cookies:='Cookie: '+Copy(Cookies,1,Length(Cookies)-2);
//    ARequest.RawHeaders.Clear;
    ARequest.RawHeaders.Add(Cookies);
  end;
end;

procedure TMyIdHTTP.DoSetCookies(AURL: String; ARequest: TIdHTTPRequest);
begin
  cs.Acquire;
  try
    WriteCookies(AURL,ARequest);
  finally
    cs.Release;
  end;
end;

procedure TMyIdHTTP.DoProcessCookies(ARequest: TIdHTTPRequest; AResponse: TIdHTTPResponse);
begin
  cs.Acquire;
  try
    ReadCookies(ARequest.Host,AResponse);
  finally
    cs.Release;
  end;
//  WriteCookies(ARequest.Host,ARequest);
end;

procedure TMyIdHTTP.SetCookieList(Value: TMyCookieList);
begin
  if Value = nil then
  begin
    OnSetCookies := nil;
    OnProcessCookies := nil;
  end else
  begin
    OnSetCookies := DoSetCookies;
    OnProcessCookies := DoProcessCookies;
  end;
  FCookieList := Value;
end;

initialization

  cs := TCriticalSection.Create;

finalization
  cs.Free;

end.

unit xeNifs;

interface

uses
  Classes,
  // xedit modules
  wbDataFormatNif, wbDataFormat;

{$region 'Native functions'}
{$region 'Helpers'}
function NifElementNotFound(const element: TdfElement; path: PWideChar): Boolean;

// Temporarily copied from xeElements.pas
function ParseIndex(const key: string; var index: Integer): Boolean;
function CheckIndex(maxIndex: Integer; var index: Integer): Boolean;
procedure SplitPath(const path: String; var key, nextPath: String);
{$endregion}

function NativeNifLoad(const filePath: string): TwbNifFile;

function ResolveByIndex(const element: TdfElement; index: Integer; const nextPath: String): TdfElement;
function ResolveFromNif(const element: TwbNifFile; const path: String): TdfElement;
function ResolveByPath(const element: TdfElement; const key: String; const nextPath: String): TdfElement;
function ResolveElement(const element: TdfElement; const path: String): TdfElement;
function NativeNifGetElement(_id: Cardinal; path: PWideChar): TdfElement;
{$endregion}

{$region 'API functions'}
function NifLoad(filePath: PWideChar; _res: PCardinal): WordBool; cdecl;
function NifFree(_id: Cardinal): WordBool; cdecl;

function NifGetElement(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;

//Properties
function NifGetName(_id: Cardinal; len: PInteger): WordBool; cdecl;
{$endregion}

implementation

uses
  SysUtils, StrUtils, Types, System.RegularExpressions,
  // xedit modules
  wbInterface,
  // xelib modules
  xeMessages, xeMeta;

{$region 'Native functions'}
{$region 'Helpers'}
function NifElementNotFound(const element: TdfElement; path: PWideChar): Boolean;
begin
  Result := not Assigned(element);
  if Result then
    SoftException('Failed to resolve element at path: ' + string(path));
end;

// Temporarily copied from xeElements.pas
function ParseIndex(const key: string; var index: Integer): Boolean;
var
  len: Integer;
begin
  len := Length(key);
  Result := (len > 2) and (key[1] = '[') and (key[len] = ']')
    and TryStrToInt(Copy(key, 2, len - 2), index);
end;

function CheckIndex(maxIndex: Integer; var index: Integer): Boolean;
begin
  if index = -1 then
    index := maxIndex;
  Result := (index > -1) and (index <= maxIndex);
end;
procedure SplitPath(const path: String; var key, nextPath: String);
var
  i: Integer;
begin
  i := Pos('\', path);
  if i > 0 then begin
    key := Copy(path, 1, i - 1);
    nextPath := Copy(path, i + 1, Length(path));
  end
  else
    key := path;
end;
{$endregion}

//Change to default nil
function NativeNifLoad(const filePath: string): TwbNifFile;
var
  _nif: TwbNifFile;
  arrStr: TStringDynArray;
  pathToFile: string;
  sl: TStringList;
  bExists: Boolean;
begin
  _nif := TwbNifFile.Create;
  bExists := False;

  //if not ContainsText('.nif.bto.btr',RightStr(filePath, 4)) then //Workaround for xEdit bug that allows loading any file
  //  raise Exception.Create(Format('%s is believed to not be a nif file, skipping', [filePath]));

  if wbContainerHandler.ResourceExists(filePath) then //relative
  begin
    //path\to\mesh.nif
    _nif.LoadFromResource(filePath);
  end
  else if FileExists(filePath) then //absolute
  begin
    //c:\path\to\mesh.nif
    _nif.LoadFromFile(filePath);
  end
  else
  begin //spcific resource
    arrStr := SplitString(filePath, '\');
    pathToFile := String.Join('\', arrStr, 1, Length(arrStr) - 1);

    if arrStr[0] = 'data' then //data\path\to\mesh.nif
    begin
      if not FileExists(wbDataPath + pathToFile) then
        raise Exception.Create(Format('File %s doesn''t exist in %s resource', [arrStr[0], pathTofile]));

      _nif.LoadFromFile(wbDataPath + pathToFile);
    end
    else if wbContainerHandler.ContainerExists(wbDataPath + arrStr[0]) then //Some.BSA\path\to\mesh.nif
    begin
      sl := TStringList.Create; //xEdit bug workaround

      wbContainerHandler.ContainerResourceList(wbDataPath + arrStr[0], sl, '');
      if sl.IndexOf(pathToFile) <> -1 then
        bExists := True;

      sl.Free;

      if not bExists then
        raise Exception.Create(Format('Unable to find %s in resource %s', [pathTofile, arrStr[0]]));

      _nif.LoadFromResource(wbDataPath + arrStr[0], pathToFile);

    end
    else
    begin //catch all
      raise Exception.Create(Format('Unable to find %s', [filePath]));
    end;
  end;

  if _nif = nil then
    raise Exception.Create(Format('Unable to open File at %s.', [filePath]));

  Result := _nif;
end;

function ResolveByIndex(const element: TdfElement; index: Integer; const nextPath: String): TdfElement;
begin
  Result := nil;

  if element is TwbNifFile then begin
    if CheckIndex((element as TwbNifFile).BlocksCount - 1, index) then
      Result := (element as TwbNifFile).Blocks[index]
  end
  else begin
    if CheckIndex(element.Count - 1, index) then
      Result := element.Items[index]
  end;

  if Assigned(Result) and (nextPath <> '') then
    Result := ResolveElement(Result, nextPath);
end;

function ResolveFromNif(const element: TwbNifFile; const path: String): TdfElement;
begin
  Result := nil;

  if path = 'Roots' then
  begin
    Result := element.Footer.Elements['Roots'];
  end
  else if path = 'Header' then
  begin
    Result := element.Header;
  end
  else if path = 'Footer' then
  begin
    Result := element.Footer;
  end;
end;

function ResolveByPath(const element: TdfElement; const key: String; const nextPath: String): TdfElement;
begin
  Result := nil;

  if element is TwbNifFile then
    Result := ResolveFromNif(element as TwbNifFile, key);

  if not Assigned(Result) then
    Result := element.Elements[key];

  if Assigned(Result) and (nextPath <> '') then
    Result := ResolveElement(Result, nextPath);
end;

function ResolveElement(const element: TdfElement; const path: String): TdfElement;
var
  key, nextPath: String;
  index: Integer;
begin
  SplitPath(path, key, nextPath);
  if ParseIndex(key, index) then begin
    Result := ResolveByIndex(element, index, nextPath);
  end
  else
    Result := ResolveByPath(element, key, nextPath);
end;

function NativeNifGetElement(_id: Cardinal; path: PWideChar): TdfElement;
begin
  if string(path) = '' then
    Result := ResolveObjects(_id) as TdfElement
  else
    Result := ResolveElement(ResolveObjects(_id) as TdfElement, string(path));
end;
{$endregion}

{$region 'API functions'}
function NifLoad(filePath: PWideChar; _res: PCardinal): WordBool; cdecl;
begin
  Result := False;
  try
    _res^ := StoreObjects(NativeNifLoad(string(filePath)));
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function NifFree(_id: Cardinal): WordBool; cdecl;
begin
  Result := False;
  try
    if not (ResolveObjects(_id) is TwbNifFile) then
      raise Exception.Create('Interface must be a nif file.');
    Result := ReleaseObjects(_id);
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function NifGetElement(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
Result := False;
  try
    element := NativeNifGetElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    _res^ := StoreObjects(element);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function NifGetName(_id: Cardinal; len: PInteger): WordBool; cdecl;
var
  _obj: TdfElement;
begin
  Result := False;
  try
    if not (ResolveObjects(_id) is TdfElement) then
      raise Exception.Create('Interface must be a TdfElement.')
    else
    begin
      _obj := ResolveObjects(_id) as TdfElement;
      resultStr := _obj.Name;
      len^ := Length(resultStr);
      Result := True;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;
{$endregion}

end.


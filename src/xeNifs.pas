unit xeNifs;

interface

uses
  Classes,
  // xedit modules
  wbDataFormatNif, wbDataFormat;

{$region 'Native functions'}
{$region 'Helpers'}
function NifElementNotFound(const element: TdfElement; path: PWideChar): Boolean;

function ParseResolveReference(var key: String): Boolean;
// Temporarily copied from xeElements.pas
function ParseIndex(const key: string; var index: Integer): Boolean;
function ParseFullName(const value: String; var fullName: String): Boolean;
function CheckIndex(maxIndex: Integer; var index: Integer): Boolean;
procedure SplitPath(const path: String; var key, nextPath: String);
{$endregion}

function NativeLoadNif(const filePath: string): TwbNifFile;

function ResolveByIndex(const element: TdfElement; index: Integer): TdfElement;
function ResolveKeyword(const nif: TwbNifFile; const keyword: String): TdfElement;
function ResolveFromNif(const nif: TwbNifFile; const path: string): TdfElement;
function ResolvePath(const element: TdfElement; const path: string): TdfElement;
function ResolveElement(const element: TdfElement; const path: String): TdfElement;
function NativeGetNifElement(_id: Cardinal; path: PWideChar): TdfElement;

procedure NativeGetBlocks(_id: Cardinal; search: String; lst: TList);
{$endregion}

{$region 'API functions'}
function LoadNif(filePath: PWideChar; _res: PCardinal): WordBool; cdecl;
function FreeNif(_id: Cardinal): WordBool; cdecl;

function HasNifElement(_id: Cardinal; path: PWideChar; bool: PWordBool): WordBool; cdecl;
function GetNifElement(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;
function GetBlocks(_id: Cardinal; search: PWideChar; len: PInteger): WordBool; cdecl;

//Properties
function GetNifName(_id: Cardinal; len: PInteger): WordBool; cdecl;
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

function ParseResolveReference(var key: String): Boolean;
begin
  Result := key[1] = '@';
  if Result then
    key := Copy(key, 2, Length(key) - 1);
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
function ParseFullName(const value: String; var fullName: String): Boolean;
begin
  Result := (value[1] = '"') and (value[Length(value)] = '"');
  if Result then
    fullName := Copy(value, 2, Length(value) - 2);
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
function NativeLoadNif(const filePath: string): TwbNifFile;
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

function ResolveByIndex(const element: TdfElement; index: Integer): TdfElement;
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
end;

function ResolveKeyword(const nif: TwbNifFile; const keyword: String): TdfElement;
begin
  Result := nil;

  if keyword = 'Roots' then
    Result := nif.Footer.Elements['Roots']
  else if keyword = 'Header' then
    Result := nif.Header
  else if keyword = 'Footer' then
    Result := nif.Footer;
end;

function ResolveFromNif(const nif: TwbNifFile; const path: string): TdfElement;
var
  name: String;
begin
  Result := ResolveKeyword(nif, path);

  if not Assigned(Result) then
    if (ParseFullName(path, name)) then
      Result := nif.BlockByName(name);
end;

function ResolvePath(const element: TdfElement; const path: string): TdfElement;
var
  index: Integer;
begin
  Result := nil;

  if ParseIndex(path, index) then
    Result := ResolveByIndex(element, index);

  if not Assigned(Result) and (element is TwbNifFile) then
    Result := ResolveFromNif(element as TwbNifFile, path);

  if not Assigned(Result) then
    Result := element.Elements[path];
end;

function ResolveElement(const element: TdfElement; const path: String): TdfElement;
var
  key, nextPath: String;
  resolveReference: Boolean;
begin
  SplitPath(path, key, nextPath);
  resolveReference := ParseResolveReference(key);

  if key <> '' then
    Result := ResolvePath(element, key)
  else
    Result := element;

  if Assigned(Result) then begin
    if resolveReference then
      Result := Result.LinksTo;

    if nextPath <> '' then
      Result := ResolveElement(Result, nextPath);
  end;
end;

function NativeGetNifElement(_id: Cardinal; path: PWideChar): TdfElement;
begin
  if string(path) = '' then
    Result := ResolveObjects(_id) as TdfElement
  else
    Result := ResolveElement(ResolveObjects(_id) as TdfElement, string(path));
end;

procedure NativeGetBlocks(_id: Cardinal; search: String; lst: TList);
var
  element: TdfElement;
  allBlocks: Boolean;
  i: Integer;
  block: TwbNifBlock;
begin
  element := ResolveObjects(_id) as TdfElement;
  allBlocks := search = '';

  if element is TwbNifFile then begin
    for i := 0 to Pred((element as TwbNifFile).BlocksCount) do begin
      block := (element as TwbNifFile).Blocks[i];
      if (allBlocks or (block.BlockType = search)) then
        lst.Add(Pointer(block));
    end;
  end
  else if element is TwbNifBlock then begin
    for i := 0 to Pred((element as TwbNifBlock).RefsCount) do begin
      block := (element as TwbNifBlock).Refs[i].LinksTo as TwbNifBlock;
      if Assigned(block) and
      (allBlocks or (block.BlockType = search)) then
        lst.Add(Pointer(block));
      end;
  end
  else
    raise Exception.Create('Element must be a Nif file.');
end;
{$endregion}

{$region 'API functions'}
function LoadNif(filePath: PWideChar; _res: PCardinal): WordBool; cdecl;
begin
  Result := False;
  try
    _res^ := StoreObjects(NativeLoadNif(string(filePath)));
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function FreeNif(_id: Cardinal): WordBool; cdecl;
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

function HasNifElement(_id: Cardinal; path: PWideChar; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    bool^ := Assigned(element);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifElement(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    _res^ := StoreObjects(element);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetBlocks(_id: Cardinal; search: PWideChar; len: PInteger): WordBool; cdecl;
var
  lst: TList;
begin
  Result := False;
  try
    lst := TList.Create;
    try
      NativeGetBlocks(_id, String(search), lst);
      StoreObjectList(lst, len);
    Result := True;
    finally
      lst.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifName(_id: Cardinal; len: PInteger): WordBool; cdecl;
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


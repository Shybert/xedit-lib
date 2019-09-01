unit xeNifs;

interface

uses
  Argo, Classes,
  // xedit modules
  wbInterface, wbDataFormatNif, wbDataFormat;

{$region 'Native functions'}
{$region 'Helpers'}
function NifElementNotFound(const element: TdfElement; path: PWideChar): Boolean;
function GetCorrespondingNifVersion(const gameMode: TwbGameMode): TwbNifVersion;
function IsFilePathRelative(const filePath: string): Boolean;
procedure MakeRelativeFilePathAbsolute(var filePath: string);
function IsFileInContainer(const containerName, pathToFile: string): Boolean;

function IsVector(element: TdfElement): Boolean;
function IsQuaternion(element: TdfElement): Boolean;
function IsTexCoords(element: TdfElement): Boolean;
function IsTriangle(element: TdfElement): Boolean;

function ParseResolveReference(var key: String): Boolean;
// Temporarily copied from xeElements.pas
function ParseIndex(const key: string; var index: Integer): Boolean;
function ParseFullName(const value: String; var fullName: String): Boolean;
function CheckIndex(maxIndex: Integer; var index: Integer): Boolean;
procedure SplitPath(const path: String; var key, nextPath: String);
{$endregion}

function NativeLoadNif(const filePath: string): TwbNifFile;
procedure NativeSaveNif(const nif: TwbNifFile; filePath: string);
function NativeCreateNif(filePath: string; ignoreExists: Boolean): TwbNifFile;

function ResolveByIndex(const element: TdfElement; index: Integer): TdfElement;
function ResolveKeyword(const nif: TwbNifFile; const keyword: String): TdfElement;
function ResolveFromNif(const nif: TwbNifFile; const path: string): TdfElement;
function ResolvePath(const element: TdfElement; const path: string): TdfElement;
function ResolveElement(const element: TdfElement; const path: String): TdfElement;
function ResolveElementEx(const element: TdfElement; const path: String): TdfElement;
function NativeGetNifElement(_id: Cardinal; path: PWideChar): TdfElement;

function NifReferenceMatches(const ref: TwbNiRef; const value: String): Boolean;
function NativeNifElementMatches(element: TdfElement; const path, value: string): Boolean;

function NativeGetNifArrayItem(const arr: TdfArray; const path, value: string): TdfElement;
function NativeGetNifArrayItemEx(const arr: TdfArray; const path, value: string): TdfElement;
function NativeAddNifArrayItem(const arr: TdfArray; const path, value: string): TdfElement;
procedure NativeRemoveNifArrayItem(const arr: TdfArray; const path, value: string);
procedure NativeMoveNifArrayItem(const element: TdfElement; index: Integer);

function AddBlockFromReference(const ref: TwbNiRef; const blockType: string): TwbNifBlock;
function AddBlockFromArray(const arr: TdfArray; const blockType: string): TwbNifBlock;

procedure NativeRemoveNifBlock(block: TwbNifBlock; recursive: WordBool);
procedure NativeGetNifBlocks(element: TdfElement; search: String; lst: TList);

function NativeGetNifContainer(element: TdfElement): TdfElement;

function NativeIsNifHeader(const element: TdfElement): Boolean;
function NativeIsNifFooter(const element: TdfElement): Boolean;

function GetMergedElementNativeValues(const element: TdfMerge): String;
procedure SetMergedElementNativeValues(const element: TdfMerge; const json: String);
{$endregion}

{$region 'API functions'}
function LoadNif(filePath: PWideChar; _res: PCardinal): WordBool; cdecl;
function FreeNif(_id: Cardinal): WordBool; cdecl;
function SaveNif(_id: Cardinal; filePath: PWideChar): WordBool; cdecl;
function CreateNif(filePath: PWideChar; ignoreExists: WordBool; _res: PCardinal): WordBool; cdecl;

function HasNifElement(_id: Cardinal; path: PWideChar; bool: PWordBool): WordBool; cdecl;
function GetNifElement(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;
function GetNifElements(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function AddNifBlock(_id: Cardinal; path, blockType: PWideChar; _res: PCardinal): WordBool; cdecl;
function RemoveNifBlock(_id: Cardinal; path: PWideChar; recursive: WordBool): WordBool; cdecl;
function MoveNifBlock(_id: Cardinal; path: PWideChar; newIndex: Integer): WordBool; cdecl;
function GetNifBlocks(_id: Cardinal; search: PWideChar; len: PInteger): WordBool; cdecl;
function GetNifLinksTo(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;
function SetNifLinksTo(_id: Cardinal; path: PWideChar; _id2: Cardinal): WordBool; cdecl;
function NifElementCount(_id: Cardinal; count: PInteger): WordBool; cdecl;
function NifElementEquals(_id, _id2: Cardinal; bool: PWordBool): WordBool; cdecl;
function NifElementMatches(_id: Cardinal; path, value: PWideChar; bool: PWordBool): WordBool; cdecl;
function HasNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar; bool: PWordBool): WordBool; cdecl;
function GetNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar; _res: PCardinal): WordBool; cdecl;
function AddNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar; _res: PCardinal): WordBool; cdecl;
function MoveNifArrayItem(_id: Cardinal; index: Integer): WordBool; cdecl;
function RemoveNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar): WordBool; cdecl;
function GetNifElementIndex(_id: Cardinal; index: PInteger): WordBool; cdecl;
function GetNifElementFile(_id: Cardinal; _res: PCardinal): WordBool; cdecl;
function GetNifElementBlock(_id: Cardinal; _res: PCardinal): WordBool; cdecl;
function GetNifContainer(_id: Cardinal; _res: PCardinal): WordBool; cdecl;

function HasNifBlockType(_id: Cardinal; path, blockType: PWideChar; _inherited: WordBool; bool: PWordBool): WordBool; cdecl;
function GetNifTemplate(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function IsNiPtr(_id: Cardinal; path: PWideChar; bool: PWordBool): WordBool; cdecl;

//Properties
function NifName(_id: Cardinal; len: PInteger): WordBool; cdecl;
function GetNifBlockType(_id: Cardinal; len: PInteger): WordBool; cdecl;

{$region 'Value functions'}
function GetNifValue(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function SetNifValue(_id: Cardinal; path, value: PWideChar): WordBool; cdecl;
function GetNifIntValue(_id: Cardinal; path: PWideChar; value: PInteger): WordBool; cdecl;
function SetNifIntValue(_id: Cardinal; path: PWideChar; value: Integer): WordBool; cdecl;
function GetNifUIntValue(_id: Cardinal; path: PWideChar; value: PCardinal): WordBool; cdecl;
function GetNifFloatValue(_id: Cardinal; path: PWideChar; value: PDouble): WordBool; cdecl;
function SetNifFloatValue(_id: Cardinal; path: PWideChar; value: Double): WordBool; cdecl;
function GetNifVector(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function SetNifVector(_id: Cardinal; path, coords: PWideChar): WordBool; cdecl;
function GetNifQuaternion(_id: Cardinal; path: PWideChar; eulerRotation: WordBool; len: PInteger): WordBool; cdecl;
function GetNativeNifQuaternion(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function SetNativeNifQuaternion(_id: Cardinal; path, coords: PWideChar): WordBool; cdecl;
function GetNifTexCoords(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function SetNifTexCoords(_id: Cardinal; path, coords: PWideChar): WordBool; cdecl;
function GetNifTriangle(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function SetNifTriangle(_id: Cardinal; path, vertexIndices: PWideChar): WordBool; cdecl;
function GetNifFlag(_id: Cardinal; path, name: PWideChar; enabled: PWordBool): WordBool; cdecl;
function SetNifFlag(_id: Cardinal; path, name: PWideChar; enable: WordBool): WordBool; cdecl;
function GetAllNifFlags(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function GetEnabledNifFlags(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
function SetEnabledNifFlags(_id: Cardinal; path, flags: PWideChar): WordBool; cdecl;
function GetNifEnumOptions(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
{$endregion}

function IsNifHeader(_id: Cardinal; bool: PWordBool): WordBool; cdecl;
function IsNifFooter(_id: Cardinal; bool: PWordBool): WordBool; cdecl;
{$endregion}

implementation

uses
  SysUtils, StrUtils, Types, System.RegularExpressions,
  // xedit modules
  wbDataFormatNifTypes,
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

function GetCorrespondingNifVersion(const gameMode: TwbGameMode): TwbNifVersion;
begin
  case gameMode of
    gmFO3, gmFNV:
      Result := nfFO3;
    gmTES3:
      Result := nfTES3;
    gmTES4:
      Result := nfTES4;
    gmTES5:
      Result := nfTES5;
    gmSSE, gmTES5VR:
      Result := nfSSE;
    gmFO4, gmFO4VR:
      Result := nfFO4;
  else
    Result := nfUnknown;
  end;
end;

function IsFilePathRelative(const filePath: string): Boolean;
begin
  Result := ExtractFileDrive(filePath) = '';
end;

procedure MakeRelativeFilePathAbsolute(var filePath: string);
begin
  if AnsiLowerCase(filePath).StartsWith('data\') then
    filePath := wbDataPath + Copy(filePath, 6, Length(filePath))
  else
    filePath := wbDataPath + filePath;
end;

function IsFileInContainer(const containerName, pathToFile: string): Boolean;
var
  ResourceList: TStringList;
begin
  if not wbContainerHandler.ContainerExists(containerName) then
    raise Exception.Create(containerName + ' not loaded.');
  ResourceList := TStringList.Create;
  try
    wbContainerHandler.ContainerResourceList(containerName, ResourceList);
    Result := ResourceList.IndexOf(pathToFile) <> -1
  finally
    ResourceList.Free;
  end;
end;

function IsVector(element: TdfElement): Boolean;
begin
  Result := (element.DataType = dtVector3) or (element.DataType = dtVector4);
end;

function IsQuaternion(element: TdfElement): Boolean;
begin
  Result := element.DataType = dtQuaternion;
end;

function IsTexCoords(element: TdfElement): Boolean;
begin
  Result := element.DataType = dtTexCoords;
end;

function IsTriangle(element: TdfElement): Boolean;
begin
  Result := element.DataType = dtTriangle;
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

function NativeLoadNif(const filePath: string): TwbNifFile;
var
  nif: TwbNifFile;
  pathRoot: string;
  remainingPath: string;
begin
  Result := nil;
  nif := TwbNifFile.Create;

  // Absolute path
  if FileExists(filePath) then begin
     nif.LoadFromFile(filePath);
     Result := nif;
  end

  // Relative path
  else if wbContainerHandler.ResourceExists(filePath) then begin
    nif.LoadFromResource(filePath);
    Result := nif;
  end

  else begin
    SplitPath(filePath, pathRoot, remainingPath);

    // Relative path starting with data\
    if AnsiLowerCase(pathRoot) = 'data' then begin
      if wbContainerHandler.ResourceExists(remainingPath) then begin
        nif.LoadFromResource(remainingPath);
        Result := nif;
      end;
    end

    // From a specific container
    else if wbContainerHandler.ContainerExists(wbDataPath + pathRoot) then begin
      if IsFileInContainer(wbDataPath + pathRoot, remainingPath) then begin
        nif.LoadFromResource(wbDataPath + pathRoot, remainingPath);
        Result := nif;
      end;
    end;
  end;

  if not Assigned(Result) then
    raise Exception.Create('Unable to find nif file at path: ' + filePath);
end;

procedure NativeSaveNif(const nif: TwbNifFile; filePath: string);
begin
  if IsFilePathRelative(filePath) then
    MakeRelativeFilePathAbsolute(filePath);
  ForceDirectories(ExtractFileDir(filePath));
  nif.SaveToFile(filePath);
end;

function NativeCreateNif(filePath: string; ignoreExists: Boolean): TwbNifFile;
var
  nif: TwbNifFile;
begin
  nif := TwbNifFile.Create;
  nif.NifVersion := GetCorrespondingNifVersion(wbGameMode);

  if filePath <> '' then begin
    if IsFilePathRelative(filePath) then
      MakeRelativeFilePathAbsolute(filePath);
    if not ignoreExists and FileExists(filePath) then
      raise Exception.Create(Format('Nif with filepath %s already exists.', [filePath]));
    NativeSaveNif(nif, filePath);
  end;

  Result := nif;
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

function ResolveElementEx(const element: TdfElement; const path: String): TdfElement;
begin
  Result := ResolveElement(element, path);
  if not Assigned(Result) then
    raise Exception.Create('Failed to resolve element at path: ' + path);
end;

function NativeGetNifElement(_id: Cardinal; path: PWideChar): TdfElement;
begin
  if string(path) = '' then
    Result := ResolveObjects(_id) as TdfElement
  else
    Result := ResolveElement(ResolveObjects(_id) as TdfElement, string(path));
end;

function NifReferenceMatches(const ref: TwbNiRef; const value: String): Boolean;
var
  block: TwbNifBlock;
  index: Integer;
  fullName: String;
begin
  Result := False;
  block := TwbNifBlock(ref.LinksTo);
  if Assigned(block) then begin
    if ParseIndex(value, index) then
      Result := index = block.Index
    else if ParseFullName(value, fullName) then
      Result := fullName = block.EditValues['Name']
    else
      Result := value = block.BlockType;     
  end;
end;

function NativeNifElementMatches(element: TdfElement; const path, value: string): Boolean;
var
  editValue: String;
  e1, e2: Extended;
begin
  if path <> '' then
    element := ResolveElement(element, path);

  if not Assigned(element) then
    Result := False
  else if element is TwbNiRef then
    Result := NifReferenceMatches(TwbNiRef(element), value)  
  else begin
    editValue := element.EditValue;
    Result := (TryStrToFloat(value, e1) and TryStrToFloat(editValue, e2) and (e1 = e2)) or (value = editValue);
  end;
end;

function NativeGetNifArrayItem(const arr: TdfArray; const path, value: string): TdfElement;
var
  i: Integer;
begin
  for i := 0 to Pred(arr.Count) do begin
    Result := arr[i];
    if NativeNifElementMatches(Result, path, value) then exit;
  end;
  Result := nil;
end;

function NativeGetNifArrayItemEx(const arr: TdfArray; const path, value: string): TdfElement;
begin
  Result := NativeGetNifArrayItem(arr, path, value);
  if not Assigned(Result) then
    raise Exception.Create('Could not find matching array element.');
end;

function NativeAddNifArrayItem(const arr: TdfArray; const path, value: string): TdfElement;
var
  element: TdfElement;
begin
  Result := arr.Add;
  if value = '' then exit;
  if path = '' then
    Result.EditValue := value
  else begin
    element := ResolveElementEx(Result, path);
    element.EditValue := value;
  end;
end;

procedure NativeRemoveNifArrayItem(const arr: TdfArray; const path, value: string);
var
  i: Integer;
begin
  for i := 0 to Pred(arr.Count) do
    if NativeNifElementMatches(arr[i], path, value) then begin
      arr[i].Remove;
      break;
    end;
end;

procedure NativeMoveNifArrayItem(const element: TdfElement; index: Integer);
var
  container: TdfElement;
begin
  container := NativeGetNifContainer(element);
  if not (container is TdfArray) then
    raise Exception.Create('Cannot move elements in non-array containers.');
  if index = -1 then index := container.Count - 1;
  container.Move(element.Index, index);
end;

function AddBlockFromReference(const ref: TwbNiRef; const blockType: string): TwbNifBlock;
begin
  if not wbIsNiObject(blockType, ref.Template) then
    raise Exception.Create('Reference cannot link to the block type "' + blockType + '".');

  Result := TwbNifBlock(ref.LinksTo);
  if not Assigned(Result) or (Result.BlockType <> blockType) then begin
    Result := TwbNifFile(ref.Root).AddBlock(blockType) as TwbNifBlock;
    ref.NativeValue := Result.Index;
  end;
end;

function AddBlockFromArray(const arr: TdfArray; const blockType: string): TwbNifBlock;
var
  ref: TwbNiRef;
  i: Integer;
begin
  if not (arr.Def.Defs[0] is TwbNiRefDef) then
    raise Exception.Create('Array cannot have references.');
  if not wbIsNiObject(blockType, TwbNiRefDef(arr.Def.Defs[0]).Template) then
    raise Exception.Create('Array cannot have references to the block type "' + blockType + '".');

  ref := nil;
  // Find existing None reference, if any
  for i := 0 to Pred(arr.Count) do
    if arr[i].NativeValue = -1 then begin
      ref := TwbNiRef(arr[i]);
      Break;
    end;
  if not Assigned(ref) then
    ref := TwbNiRef(arr.Add);
  Result := AddBlockFromReference(ref, blockType)
end;

procedure NativeRemoveNifBlock(block: TwbNifBlock; recursive: WordBool);
var
  i: Integer;
  ref: TwbNiRef;
begin
  if recursive then begin
    for i := 0 to Pred(block.RefsCount) do begin
      ref := block.Refs[i];
      if Assigned(ref.LinksTo()) and not ref.Ptr then
        NativeRemoveNifBlock(ref.LinksTo as TwbNifBlock, True);
    end;
  end;

  block.NifFile.Delete(block.Index);
end;

procedure NativeGetNifBlocks(element: TdfElement; search: String; lst: TList);
var
  allBlocks: Boolean;
  i: Integer;
  block: TwbNifBlock;
begin
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
    raise Exception.Create('Element must be a Nif file or a Nif block.');
end;

function NativeGetNifContainer(element: TdfElement): TdfElement;
begin
  Result := element.Parent;
  if not Assigned(Result) then
    raise Exception.Create('Could not find container for ' + element.Name);
end;

function NativeIsNifHeader(const element: TdfElement): Boolean;
begin
  Result := element is TwbNifBlock and (TwbNifBlock(element).BlockType = 'NiHeader')
end;
function NativeIsNifFooter(const element: TdfElement): Boolean;
begin
  Result := element is TwbNifBlock and (TwbNifBlock(element).BlockType = 'NiFooter')
end;

function GetMergedElementNativeValues(const element: TdfMerge): String;
var
  obj: TJSONObject;
  i: Integer;
begin
  obj := TJSONObject.Create;
  try
    with TdfMergeDef(element.Def) do
    for i := Low(Defs) to High(Defs) do
      obj.D[Defs[i].Name] := element.NativeValues[Defs[i].Name];
    Result := obj.ToString;
  finally
    obj.Free;
  end;
end;

procedure SetMergedElementNativeValues(const element: TdfMerge; const json: String);
var
  obj: TJSONObject;
  i: Integer;
begin
  obj := TJSONObject.Create(json);
  try
    with TdfMergeDef(element.Def) do
    for i := Low(Defs) to High(Defs) do
      if obj.HasKey(Defs[i].Name) then begin
        if not (obj[Defs[i].Name].JSONValueType in [jtDouble, jtInt]) then
          raise Exception.Create('The value of property "' + Defs[i].Name + '" is not a number.');

        element.NativeValues[Defs[i].Name] := obj[Defs[i].Name].AsVariant;
      end;
  finally
    obj.Free;
  end;
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

function SaveNif(_id: Cardinal; filePath: PWideChar): WordBool; cdecl;
begin
  Result := False;
  try
    if not (ResolveObjects(_id) is TwbNifFile) then
      raise Exception.Create('Interface must be a Nif file.');
    NativeSaveNif(ResolveObjects(_id) as TwbNifFile, filePath);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function CreateNif(filePath: PWideChar; ignoreExists: WordBool; _res: PCardinal): WordBool; cdecl;
begin
  Result := False;
  try
    _res^ := StoreObjects(NativeCreateNif(string(filePath), ignoreExists));
    Result := True;
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

function GetNifElements(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
  i: Integer;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element is TdfContainer) then
      raise Exception.Create('Element is not a container.');
    SetLength(resultArray, element.Count);
    for i := 0 to Pred(element.Count) do
      resultArray[i] := StoreObjects(element[i]);
    len^ := Length(resultArray);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function AddNifBlock(_id: Cardinal; path, blockType: PWideChar; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;

    if element is TwbNifFile then
      _res^ := StoreObjects(TwbNifFile(element).AddBlock(blockType))
    else if element is TdfArray then
      _res^ := StoreObjects(AddBlockFromArray(TdfArray(element), blockType))
    else if element is TwbNiRef then
      _res^ := StoreObjects(AddBlockFromReference(TwbNiRef(element), blockType))
    else
      raise Exception.Create('Element must either be a nif file, an array, or a reference.');

    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function RemoveNifBlock(_id: Cardinal; path: PWideChar; recursive: WordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if not (element is TwbNifBlock) then
      raise Exception.Create('Interface must be a nif block.');
    if NativeIsNifHeader(element) or NativeIsNifFooter(element) then
      raise Exception.Create('The header and the footer of a nif file cannot be removed.');
    NativeRemoveNifBlock(TwbNifBlock(element), recursive);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function MoveNifBlock(_id: Cardinal; path: PWideChar; newIndex: Integer): WordBool; cdecl;
var
  element: TdfElement;
  nif: TwbNifFile;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element is TwbNifBlock) then
      raise Exception.Create('Interface must be a nif block.');

    nif := TwbNifBlock(element).NifFile;
    if newIndex = -1 then
      nif.Move(element.Index, Pred(nif.BlocksCount))
    else
      nif.Move(element.Index, newIndex);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifBlocks(_id: Cardinal; search: PWideChar; len: PInteger): WordBool; cdecl;
var
  lst: TList;
begin
  Result := False;
  try
    lst := TList.Create;
    try
      NativeGetNifBlocks(ResolveObjects(_id) as TdfElement, String(search), lst);
      StoreObjectList(lst, len);
      Result := True;
    finally
      lst.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifLinksTo(_id: Cardinal; path: PWideChar; _res: PCardinal): WordBool; cdecl;
var
  element, linkedElement: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if not (element is TwbNiRef) then
      raise Exception.Create('Element cannot hold references.');
    linkedElement := element.LinksTo;
    if not Assigned(linkedElement) then
      _res^ := 0
    else
      _res^ := StoreObjects(linkedElement);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifLinksTo(_id: Cardinal; path: PWideChar; _id2: Cardinal): WordBool; cdecl;
var
  element, element2: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if not (element is TwbNiRef) then
      raise Exception.Create('Element cannot hold references.');
    element2 := ResolveObjects(_id2) as TdfElement;
    if not (element2 is TwbNifBlock) then
      raise Exception.Create('Second interface is not a block.');
    if not TwbNifBlock(element2).IsNiObject(TwbNiRef(element).Template) then
      raise Exception.Create('Element cannot hold a reference to the block type "' + TwbNifBlock(element2).BlockType + '".');

    element.NativeValue := element2.Index;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;


function NifElementCount(_id: Cardinal; count: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if NifElementNotFound(element, '') then exit;
    count^ := element.Count;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function NifElementEquals(_id, _id2: Cardinal; bool: PWordBool): WordBool; cdecl;
var
  element, element2: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if NifElementNotFound(element, '') then exit;
    element2 := ResolveObjects(_id2) as TdfElement;
    if NifElementNotFound(element2, '') then exit;
    bool^ := element.Equals(element2);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function NifElementMatches(_id: Cardinal; path, value: PWideChar; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    bool^ := NativeNifElementMatches(element, '', value);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function HasNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element is TdfArray) then
      raise Exception.Create('Element must be an array.');
    bool^ := Assigned(NativeGetNifArrayItem(TdfArray(element), subpath, value));
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element is TdfArray) then
      raise Exception.Create('Element must be an array.');
    _res^ := StoreObjects(NativeGetNifArrayItemEx(TdfArray(element), subpath, value));
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function AddNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element is TdfArray) then
      raise Exception.Create('Element must be an array.');
    _res^ := StoreObjects(NativeAddNifArrayItem(TdfArray(element), subpath, value));
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function RemoveNifArrayItem(_id: Cardinal; path, subpath, value: PWideChar): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element is TdfArray) then
      raise Exception.Create('Element must be an array.');
    NativeRemoveNifArrayItem(TdfArray(element), subpath, value);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function MoveNifArrayItem(_id: Cardinal; index: Integer): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if NifElementNotFound(element, '') then exit;
    NativeMoveNifArrayItem(element, index);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifElementIndex(_id: Cardinal; index: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if (element is TwbNifFile) or NativeIsNifHeader(element) or NativeIsNifFooter(element) then
      raise Exception.Create('Unable to get the index of nif files, nif headers, and nif footers.');
    index^ := element.Index;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifElementFile(_id: Cardinal; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    _res^ := StoreObjects(element.Root);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifElementBlock(_id: Cardinal; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if element is TwbNifFile then
      raise Exception.Create('Element cannot be a nif file.');
    while not (element is TwbNifBlock) and Assigned(element.Parent) do
      element := element.Parent;
    if not (element is TwbNifBlock) then
      raise Exception.Create('Could not find the containing block for ' + element.Name);
    _res^ := StoreObjects(element);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifContainer(_id: Cardinal; _res: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if NifElementNotFound(element, '') then exit;
    if element is TwbNifFile then
      raise Exception.Create('Element cannot be a nif file.');
    _res^ := StoreObjects(NativeGetNifContainer(element));
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function HasNifBlockType(_id: Cardinal; path, blockType: PWideChar; _inherited: WordBool; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if not (element is TwbNifBlock) then
      raise Exception.Create('Element must be a nif block.');
    bool^ := TwbNifBlock(element).IsNiObject(blockType, _inherited);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifTemplate(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if not (element is TwbNiRef) then
      raise Exception.Create('Element must be a reference.');
    resultStr := TwbNiRef(element).Template;
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function IsNiPtr(_id: Cardinal; path: PWideChar; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if not (element is TwbNiRef) then
      raise Exception.Create('Element must be a reference.');
    bool^ := TwbNiRef(element).Ptr;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function NifName(_id: Cardinal; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if NifElementNotFound(element, '') then exit;
    resultStr := element.Name;
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifBlockType(_id: Cardinal; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    if not (element is TwbNifBlock) then
      raise Exception.Create('Interface must be a nif block.');
    resultStr := (element as TwbNifBlock).BlockType;
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

{$region 'Value functions'}
function GetNifValue(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    resultStr := element.EditValue;
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifValue(_id: Cardinal; path, value: PWideChar): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    element.EditValue := value;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifIntValue(_id: Cardinal; path: PWideChar; value: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    value^ := Integer(element.NativeValue);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifIntValue(_id: Cardinal; path: PWideChar; value: Integer): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    element.NativeValue := value;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifUIntValue(_id: Cardinal; path: PWideChar; value: PCardinal): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    value^ := Cardinal(element.NativeValue);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifFloatValue(_id: Cardinal; path: PWideChar; value: PDouble): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    value^ := Double(element.NativeValue);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifFloatValue(_id: Cardinal; path: PWideChar; value: Double): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    element.NativeValue := value;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifVector(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsVector(element) then
      raise Exception.Create('Element is not a vector.');

    resultStr := GetMergedElementNativeValues(element as TdfMerge);
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifVector(_id: Cardinal; path, coords: PWideChar): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsVector(element) then
      raise Exception.Create('Element is not a vector.');
    SetMergedElementNativeValues(element as TdfMerge, coords);
    Result := True
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifQuaternion(_id: Cardinal; path: PWideChar; eulerRotation: WordBool; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
  obj: TJSONObject;
  values: TStringDynArray;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsQuaternion(element) then
      raise Exception.Create('Element is not a quaternion.');

    wbRotationEuler := eulerRotation;
    values := SplitString(element.EditValue, ' ');
    obj := TJSONObject.Create;
    try
      if eulerRotation then begin
        obj.D['Y'] := StrToFloat(values[0]);
        obj.D['P'] := StrToFloat(values[1]);
        obj.D['R'] := StrToFloat(values[2]);
      end
      else begin
        obj.D['A'] := StrToFloat(values[0]);
        obj.D['X'] := StrToFloat(values[1]);
        obj.D['Y'] := StrToFloat(values[2]);
        obj.D['Z'] := StrToFloat(values[3]);
      end;

      resultStr := obj.ToString;
      len^ := Length(resultStr);
      Result := True;
    finally
      obj.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNativeNifQuaternion(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsQuaternion(element) then
      raise Exception.Create('Element is not a quaternion.');

    resultStr := GetMergedElementNativeValues(element as TdfMerge);
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNativeNifQuaternion(_id: Cardinal; path, coords: PWideChar): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsQuaternion(element) then
      raise Exception.Create('Element is not a quaternion.');
    SetMergedElementNativeValues(element as TdfMerge, coords);
    Result := True
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifTexCoords(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsTexCoords(element) then
      raise Exception.Create('Element is not texture coordinates.');

    resultStr := GetMergedElementNativeValues(element as TdfMerge);
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifTexCoords(_id: Cardinal; path, coords: PWideChar): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsTexCoords(element) then
      raise Exception.Create('Element is not texture coordinates.');
    SetMergedElementNativeValues(element as TdfMerge, coords);
    Result := True
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifTriangle(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsTriangle(element) then
      raise Exception.Create('Element is not a triangle.');

    resultStr := GetMergedElementNativeValues(element as TdfMerge);
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifTriangle(_id: Cardinal; path, vertexIndices: PWideChar): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not IsTriangle(element) then
      raise Exception.Create('Element is not a triangle.');
    SetMergedElementNativeValues(element as TdfMerge, vertexIndices);
    Result := True
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifFlag(_id: Cardinal; path, name: PWideChar; enabled: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element.Def is TdfFlagsDef) then
      raise Exception.Create('Element does not have flags');
    if TdfFlagsDef(element.Def).IndexOfValue(name) <> -1 then begin
      enabled^ := element.NativeValues[name];
      Result := True;
    end
    else
      SoftException('Flag "' + name + '" not found.');
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetNifFlag(_id: Cardinal; path, name: PWideChar; enable: WordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := NativeGetNifElement(_id, path);
    if NifElementNotFound(element, path) then exit;
    if not (element.Def is TdfFlagsDef) then
      raise Exception.Create('Element does not have flags');
    if TdfFlagsDef(element.Def).IndexOfValue(name) <> -1 then begin
      element.NativeValues[name] := enable;
      Result := True;
    end
    else
      SoftException('Flag "' + name + '" not found.');
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetAllNifFlags(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  slFlags: TStringList;
  element: TdfElement;
  i: Integer;
begin
  Result := False;
  try
    slFlags := TStringList.Create;
    slFlags.StrictDelimiter := True;
    slFlags.Delimiter := ',';

    try
      element := NativeGetNifElement(_id, path);
      if NifElementNotFound(element, path) then exit;
      if not (element.Def is TdfFlagsDef) then
        raise Exception.Create('Element does not have flags');
      for i := 0 to Pred(TdfFlagsDef(element.Def).ValuesMapCount) do
        slFlags.Add(TdfFlagsDef(element.Def).Values[i]);

      resultStr := slFlags.DelimitedText;
      len^ := Length(resultStr);
      Result := True;
    finally
      slFlags.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetEnabledNifFlags(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  slFlags: TStringList;
  element: TdfElement;
  i: Integer;
  flagName: String;
begin
  Result := False;
  try
    slFlags := TStringList.Create;
    slFlags.StrictDelimiter := True;
    slFlags.Delimiter := ',';

    try
      element := NativeGetNifElement(_id, path);
      if NifElementNotFound(element, path) then exit;
      if not (element.Def is TdfFlagsDef) then
        raise Exception.Create('Element does not have flags');
      for i := 0 to Pred(TdfFlagsDef(element.Def).ValuesMapCount) do begin
        flagName := TdfFlagsDef(element.Def).Values[i];
        if element.NativeValues[flagName] then
          slFlags.Add(flagName);
      end;

      resultStr := slFlags.DelimitedText;
      len^ := Length(resultStr);
      Result := True;
    finally
      slFlags.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetEnabledNifFlags(_id: Cardinal; path, flags: PWideChar): WordBool; cdecl;
var
  slFlags: TStringList;
  element: TdfElement;
  i: Integer;
  flagName: String;
begin
  Result := False;
  try
    slFlags := TStringList.Create;
    slFlags.StrictDelimiter := True;
    slFlags.Delimiter := ',';
    slFlags.DelimitedText := flags;

    try
      element := NativeGetNifElement(_id, path);
      if NifElementNotFound(element, path) then exit;
      if not (element.Def is TdfFlagsDef) then
        raise Exception.Create('Element does not have flags');
      for i := 0 to Pred(TdfFlagsDef(element.Def).ValuesMapCount) do begin
        flagName := TdfFlagsDef(element.Def).Values[i];
        element.NativeValues[flagName] := slFlags.IndexOf(flagName) <> -1;
      end;
      Result := True;
    finally
      slFlags.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetNifEnumOptions(_id: Cardinal; path: PWideChar; len: PInteger): WordBool; cdecl;
var
  slOptions: TStringList;
  element: TdfElement;
  i: Integer;
begin
  Result := False;
  try
    slOptions := TStringList.Create;
    slOptions.StrictDelimiter := True;
    slOptions.Delimiter := ',';

    try
      element := NativeGetNifElement(_id, path);
      if NifElementNotFound(element, path) then exit;
      if not (element.Def is TdfEnumDef) then
        raise Exception.Create('Element does not have enumeration');
      for i := 0 to Pred(TdfEnumDef(element.Def).ValuesMapCount) do
        slOptions.Add(TdfEnumDef(element.Def).Values[i]);

      resultStr := slOptions.DelimitedText;
      len^ := Length(resultStr);
      Result := True;
    finally
      slOptions.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;
{$endregion}

function IsNifHeader(_id: Cardinal; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    bool^ := NativeIsNifHeader(element);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function IsNifFooter(_id: Cardinal; bool: PWordBool): WordBool; cdecl;
var
  element: TdfElement;
begin
  Result := False;
  try
    element := ResolveObjects(_id) as TdfElement;
    bool^ := NativeIsNifFooter(element);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;
{$endregion}

end.


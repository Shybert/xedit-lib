unit txNifs;

interface
  // PUBLIC TESTING INTERFACE
  procedure BuildFileHandlingTests;

implementation

uses
  Windows,
  SysUtils,
  Classes,
  Variants,
  Argo,
  Mahogany,
  txMeta,
{$IFDEF USE_DLL}
  txImports;
{$ENDIF}
{$IFNDEF USE_DLL}
  xeConfiguration, xeNifs, xeMeta;
{$ENDIF}

procedure ExpectExists(obj: TJSONObject; key: string);
begin
  Expect(obj.HasKey(key), key + ' should exist');
end;

procedure ExpectApproxEqual(actual: Variant; expected: Variant);
begin
  Expect(abs(actual - expected) < 1e-2, Format('Expected "%s" to approximately equal "%s"', [VarToStr(actual), VarToStr(expected)]));
end;

procedure TestLoadNif(filePath: string);
var
  h: Cardinal;
begin
  ExpectSuccess(LoadNif(PWideChar(filePath), @h));
  Expect(h > 0, 'Should return a handle');
end;

procedure TestHasNifElement(h: Cardinal; path: PWideChar; expectedValue: WordBool = True);
var
  exists: WordBool;
begin
  ExpectSuccess(HasNifElement(h, path, @exists));
  ExpectEqual(exists, expectedValue);
end;

procedure TestGetNifElement(h: Cardinal; path: PWideChar);
var
  element: Cardinal;
begin
  ExpectSuccess(GetNifElement(h, path, @element));
  Expect(element > 0, 'Handle should be greater than 0');
end;

procedure TestNames(a: CardinalArray; firstName, lastName: String);
var
  len: Integer;
begin
  ExpectSuccess(NifName(a[Low(a)], @len));
  ExpectEqual(grs(len), firstName);
  ExpectSuccess(NifName(a[High(a)], @len));
  ExpectEqual(grs(len), lastName);
end;

procedure TestRemoveNifBlock(h: Cardinal; path: PWideChar; recursive: Boolean = False);
var
  b: WordBool;
begin
  ExpectSuccess(RemoveNifBlock(h, path, recursive));
  ExpectSuccess(HasNifElement(h, path, @b));
  Expect(not b, 'The element should no longer be present');
end;

procedure TestGetNifBlocks(h: Cardinal; path, search: PWideChar; expectedCount: Integer);
var
  len: Integer;
  a: CardinalArray;
  i: Integer;
begin
  if path <> '' then
    ExpectSuccess(GetNifElement(h, path, @h));
  ExpectSuccess(GetNifBlocks(h, search, @len));
  ExpectEqual(len, expectedCount);
  a := gra(len);
  for i := Low(a) to High(a) do
    ReleaseObjects(a[i]);
end;

procedure TestNifElementCount(h: Cardinal; expectedCount: Integer);
var
  count: Integer;
begin
  ExpectSuccess(NifElementCount(h, @count));
  ExpectEqual(count, expectedCount);
end;

procedure TestNifElementEquals(element1, element2: Cardinal; expectedValue: WordBool = True); overload;
var
  b: WordBool;
begin
  ExpectSuccess(NifElementEquals(element1, element2, @b));
  ExpectEqual(b, expectedValue);
end;

procedure TestNifElementEquals(element1, container: Cardinal; path: PWideChar; expectedValue: WordBool = True); overload;
var
  element2: Cardinal;
begin
  ExpectSuccess(GetNifElement(container, path, @element2));
  TestNifElementEquals(element1, element2, expectedValue);
end;

procedure TestNifElementMatches(h: Cardinal; path, value: PWideChar; expectedValue: WordBool = True);
var
  b: WordBool;
begin
  ExpectSuccess(NifElementMatches(h, path, value, @b));
  ExpectEqual(b, expectedValue);
end;

procedure TestHasNifArrayItem(h: Cardinal; path, subpath, value: PWideChar; expectedValue: WordBool = True);
var
  b: WordBool;
begin
  ExpectSuccess(HasNifArrayItem(h, path, subpath, value, @b));
  ExpectEqual(b, expectedValue);
end;

procedure TestGetNifArrayItem(h: Cardinal; path, subpath, value: PWideChar);
var
  item: Cardinal;
begin
  ExpectSuccess(GetNifArrayItem(h, path, subpath, value, @item));
  Expect(item > 0, 'Handle should be greater than 0');
end;

procedure TestAddNifArrayItem(h: Cardinal; path, subpath, value: PWideChar);
var
  arr, item: Cardinal;
  currentArrLength, len: Integer;
begin
  ExpectSuccess(GetNifElement(h, path, @arr));
  ExpectSuccess(NifElementCount(arr, @currentArrLength));

  ExpectSuccess(AddNifArrayItem(h, path, subpath, value, @item));
  Expect(item > 0, 'Handle should be greater than 0');
  TestNifElementCount(arr, currentArrLength + 1);
  if value <> '' then begin
    ExpectSuccess(GetNifValue(item, subpath, @len));
    ExpectEqual(grs(len), string(value));
  end;
end;

procedure TestRemoveNifArrayItem(h: Cardinal; path, subpath, value: PWideChar);
var
  element: Cardinal;
  count: Integer;
begin
  ExpectSuccess(GetNifElement(h, path, @element));
  ExpectSuccess(NifElementCount(element, @count));
  ExpectSuccess(RemoveNifArrayItem(h, path, subpath, value));
  TestNifElementCount(element, count - 1);
end;

procedure TestMoveNifArrayItem(h: Cardinal; index: Integer);
var
  newIndex: Integer;
begin
  ExpectSuccess(MoveNifArrayItem(h, index));
  ExpectSuccess(GetNifElementIndex(h, @newIndex));
  ExpectEqual(newIndex, index);
end;

procedure TestGetNifDefNames(h: Cardinal; enabledOnly: WordBool; names: TStringArray);
var
  len: Integer;
  returnedNames: TStringList;
  i: Integer;
begin
  ExpectSuccess(GetNifDefNames(h, enabledOnly, @len));
  returnedNames := TStringList.Create;
  try
    returnedNames.Text := grs(len);
    ExpectEqual(returnedNames.Count, High(names) + 1);
    for i := 0 to Pred(returnedNames.Count) do
      ExpectEqual(returnedNames[i], names[i]);
  finally
    returnedNames.Free;
  end;
end;

procedure TestGetNifLinksTo(h: Cardinal; path: PWideChar; expectedBlock: Cardinal);
var
  block: Cardinal;
begin
  ExpectSuccess(GetNifLinksTo(h, path, @block));
  Expect(block > 0, 'Handle should be greater than 0');
  TestNifElementEquals(block, expectedBlock);
end;

procedure TestGetNifElementIndex(h: Cardinal; path: PWideChar; expectedIndex: Integer);
var
  element: Cardinal;
  i: integer;
begin
  ExpectSuccess(GetNifElement(h, path, @element));
  ExpectSuccess(GetNifElementIndex(element, @i));
  ExpectEqual(i, expectedIndex);
end;

procedure TestGetNifElementFile(h, expectedNif: Cardinal);
var
  nif: Cardinal;
begin
  ExpectSuccess(GetNifElementFile(h, @nif));
  Expect(nif > 0, 'Handle should be greater than 0');
  TestNifElementEquals(nif, expectedNif);
end;

procedure TestGetNifElementBlock(h, expectedBlock: Cardinal);
var
  block: Cardinal;
begin
  ExpectSuccess(GetNifElementBlock(h, @block));
  Expect(block > 0, 'Handle should be greater than 0');
  TestNifElementEquals(block, expectedBlock);
end;

procedure TestGetNifContainer(h: Cardinal; path: PWideChar; expectedContainer: Cardinal);
var
  container: Cardinal;
begin
  if path <> '' then
    ExpectSuccess(GetNifElement(h, path, @h));
  ExpectSuccess(GetNifContainer(h, @container));
  Expect(container > 0, 'Handle should be greater than 0');
  TestNifElementEquals(container, expectedContainer);
end;

procedure TestNifBlockTypeExists(blockType: PWideChar; expectedResult: WordBool);
var
  b: WordBool;
begin
  ExpectSuccess(NifBlockTypeExists(blockType, @b));
  ExpectEqual(b, expectedResult);
end;

procedure TestIsNifBlockType(blockType, blockType2: PWideChar; _inherited: WordBool; expectedResult: WordBool);
var
  b: WordBool;
begin
  ExpectSuccess(IsNifBlockType(blockType, blockType2, _inherited, @b));
  ExpectEqual(b, expectedResult);
end;

procedure TestHasNifBlockType(h: Cardinal; path, blockType: PWideChar; _inherited: WordBool; expectedResult: WordBool);
var
  b: WordBool;
begin
  ExpectSuccess(HasNifBlockType(h, path, blockType, _inherited, @b));
  ExpectEqual(b, expectedResult);
end;

procedure TestGetNifBlockTypeAllowed(h: Cardinal; blockType: PWideChar; expectedResult: WordBool);
var
  b: WordBool;
begin
  ExpectSuccess(GetNifBlockTypeAllowed(h, blockType, @b));
  ExpectEqual(b, expectedResult);
end;

procedure TestGetNifBlockType(h: Cardinal; path, expectedBlockType: PWideChar);
var
  block: Cardinal;
  len: Integer;
begin
  ExpectSuccess(GetNifElement(h, path, @block));
  ExpectSuccess(GetNifBlockType(block, @len));
  ExpectEqual(grs(len), string(expectedBlockType));
end;

procedure TestSetNifValue(h: Cardinal; path, value: PWideChar);
var
  len: Integer;
begin
  ExpectSuccess(SetNifValue(h, path, value));
  ExpectSuccess(GetNifValue(h, path, @len));
  ExpectEqual(grs(len), string(value));
end;

procedure TestSetNifIntValue(h: Cardinal; path: PWideChar; value: Integer);
var
  i: Integer;
begin
  ExpectSuccess(SetNifIntValue(h, path, value));
  ExpectSuccess(GetNifIntValue(h, path, @i));
  ExpectEqual(i, value);
end;

procedure TestSetNifFloatValue(h: Cardinal; path: PWideChar; value: Double);
var
  d: Double;
begin
  ExpectSuccess(SetNifFloatValue(h, path, value));
  ExpectSuccess(GetNifFloatValue(h, path, @d));
  ExpectEqual(d, value);
end;

procedure TestSetNifVector(h: Cardinal; path, coordsJSON: PWideChar);
var
  len: Integer;
begin
  ExpectSuccess(SetNifVector(h, path, coordsJSON));
  ExpectSuccess(GetNifVector(h, path, @len));
  ExpectEqual(grs(len), string(coordsJSON));
end;

procedure TestSetNifMatrix(h: Cardinal; path, matrix: PWideChar);
var
  len: Integer;
begin
  ExpectSuccess(SetNifMatrix(h, path, matrix));
  ExpectSuccess(GetNifMatrix(h, path, @len));
  ExpectEqual(grs(len), string(matrix));
end;

procedure TestRotationEquality(rotation: String; expectedY, expectedP, expectedR: Double); overload;
var
  obj: TJSONObject;
begin
  obj := TJSONObject.Create(rotation);
  try
    ExpectApproxEqual(obj['Y'].AsVariant, expectedY);
    ExpectApproxEqual(obj['P'].AsVariant, expectedP);
    ExpectApproxEqual(obj['R'].AsVariant, expectedR);
  finally
    obj.Free;
  end;
end;

procedure TestRotationEquality(rotation: String; expectedAngle, expectedX, expectedY, expectedZ: Double); overload;
var
  obj: TJSONObject;
begin
  obj := TJSONObject.Create(rotation);
  try
    ExpectApproxEqual(obj['angle'].AsVariant, expectedAngle);
    ExpectApproxEqual(obj['X'].AsVariant, expectedX);
    ExpectApproxEqual(obj['Y'].AsVariant, expectedY);
    ExpectApproxEqual(obj['Z'].AsVariant, expectedZ);
  finally
    obj.Free;
  end;
end;

procedure TestGetNifFlag(h: Cardinal; path, flag: PWideChar; expectedValue: WordBool);
var
  b: WordBool;
begin
  ExpectSuccess(GetNifFlag(h, path, flag, @b));
  ExpectEqual(b, expectedValue);
end;

procedure TestSetNifFlag(h: Cardinal; path, flag: PWideChar; enable: WordBool);
var
  b: WordBool;
begin
  ExpectSuccess(SetNifFlag(h, path, flag, enable));
  ExpectSuccess(GetNifFlag(h, path, flag, @b));
  ExpectEqual(b, enable);
end;

procedure TestSetEnabledNifFlags(h: Cardinal; path, flags: PWideChar);
var
  len: Integer;
begin
  ExpectSuccess(SetEnabledNifFlags(h, path, flags));
  ExpectSuccess(GetEnabledNifFlags(h, path, @len));
  ExpectEqual(grs(len), string(flags));
end;

procedure TestGetNifEnumOptions(h: Cardinal; path: PWideChar; expectedOptions: string);
var
  len: Integer;
begin
  ExpectSuccess(GetNifEnumOptions(h, path, @len));
  ExpectEqual(grs(len), expectedOptions);
end;

procedure CopyNifs(filenames: TStringArray);
var
  dataPath, programPath, oldPath, newPath: String;
  i: Integer;
begin
  dataPath := GetDataPath;
  programPath := GetProgramPath;
  for i := Low(filenames) to High(filenames) do begin
    oldPath := programPath + 'nifs\' + filenames[i];
    newPath := dataPath + filenames[i];
    CopyFile(PWideChar(oldPath), PWideChar(newPath), False);
  end;
end;

procedure DeleteNifs(filePaths: TStringArray);
var
  dataPath: String;
  i: Integer;
begin
  dataPath := GetDataPath;
  for i := Low(filePaths) to High(filePaths) do
    DeleteFile(dataPath + filePaths[i]);
end;

procedure BuildFileHandlingTests;
var
  b: WordBool;
  h, h2, h3, nif, header, footer, rootBlock, vectorArray, vector, transformStruct, float, ref, xt1, xt2, refArray, c: Cardinal;
  len, i: Integer;
  f: Double;
  str: String;
  obj, obj2: TJSONObject;
begin
  Describe('Nif File Handling Functions', procedure
    begin
      BeforeAll(procedure
        begin
          ExpectSuccess(LoadNif('meshes\furniture\windhelm\windhelmthrone.nif', @nif));
          ExpectSuccess(GetNifElement(nif, 'Header', @header));
          ExpectSuccess(GetNifElement(nif, 'Footer', @footer));
          ExpectSuccess(GetNifElement(nif, 'BSFadeNode', @rootBlock));
          ExpectSuccess(GetNifElement(nif, 'NiTriShapeData\Tangents', @vectorArray));
          ExpectSuccess(GetNifElement(vectorArray, '[0]', @vector));
          ExpectSuccess(GetNifElement(rootBlock, 'Transform', @transformStruct));
          ExpectSuccess(GetNifElement(transformStruct, 'Scale', @float));
          ExpectSuccess(GetNifElement(rootBlock, 'Children\[0]', @ref));
          CopyNifs(['xtest-1.nif', 'xtest-2.nif']);
          ExpectSuccess(LoadNif('xtest-1.nif', @xt1));
          ExpectSuccess(LoadNif('xtest-2.nif', @xt2));
          ExpectSuccess(GetNifElement(xt2, 'BSFadeNode\Children', @refArray));
        end);

      AfterAll(procedure
        begin
          DeleteNifs(['xtest-1.nif', 'xtest-2.nif'])
        end);

      Describe('LoadNif', procedure
        begin
          It('Should load nifs from absolute paths', procedure
            begin
              TestLoadNif(GetDataPath + 'xtest-1.nif');
            end);

          It('Should load nifs from paths relative to data\', procedure
            begin
              TestLoadNif('xtest-1.nif');
            end);

          It('Should load nifs from relative paths starting with data\', procedure
            begin
              TestLoadNif('data\xtest-1.nif');
            end);

          It('Should load nifs from a specific container', procedure
            begin
              TestLoadNif('Skyrim - Meshes.bsa\meshes\primitivegizmo.nif');
            end);

          It('Should fail if the file doesn''t exist', procedure
            begin
              ExpectFailure(LoadNif(PWideChar(GetDataPath + 'NonExisting.nif'), @h));
              ExpectFailure(LoadNif('NonExisting.nif', @h));
              ExpectFailure(LoadNif('data\NonExisting.nif', @h));
              ExpectFailure(LoadNif('Skyrim - Meshes.bsa\NonExisting.nif', @h));
            end);

          It('Should fail if the file isn''t a nif', procedure
            begin
              ExpectFailure(LoadNif(PWideChar(GetDataPath + 'xtest-1.esp'), @h));
              ExpectFailure(LoadNif('xtest-1.esp', @h));
              ExpectFailure(LoadNif('data\xtest-1.esp', @h));
              ExpectFailure(LoadNif('Skyrim - Textures.bsa\textures\black.dds', @h));
            end);
      end);

      Describe('Free', procedure
        begin
          It('Should free a loaded nif', procedure
            begin
              ExpectSuccess(LoadNif(PWideChar('xtest-1.nif'), @h));
              ExpectSuccess(FreeNif(h));
            end);

          It('Should fail if the nif has already been freed', procedure
            begin
              ExpectSuccess(LoadNif(PWideChar('xtest-1.nif'), @h));
              ExpectSuccess(FreeNif(h));
              ExpectFailure(FreeNif(h));
            end);

          It('Should fail if the handle isn''t a nif', procedure
            begin
              ExpectFailure(FreeNif(rootBlock));
            end);

          It('Should fail if the handle is invalid', procedure
            begin
              ExpectFailure(FreeNif($FFFFFF));
            end);
        end);

      Describe('SaveNif', procedure
        begin
          AfterAll(procedure
            begin
              DeleteNifs(['test.nif', 'meshes\test.nif', 'meshes\test\test.nif']);
            end);

          It('Should save nifs at absolute paths', procedure
            begin
              ExpectSuccess(SaveNif(nif, PWideChar(GetDataPath + 'test.nif')));
              ExpectSuccess(FileExists(GetDataPath + 'test.nif'));
            end);

          It('Should save nifs at paths relative to data\', procedure
            begin
              ExpectSuccess(SaveNif(nif, 'meshes\test.nif'));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test.nif'));
            end);

          It('Should save nifs at relative paths starting with data\', procedure
            begin
              ExpectSuccess(SaveNif(nif, 'data\meshes\test\test.nif'));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test\test.nif'));
            end);

          It('Should fail if interface is not a nif file', procedure
            begin
              ExpectFailure(SaveNif(rootBlock, ''));
            end);

          It('Should fail if the handle is invalid', procedure
            begin
              ExpectFailure(SaveNif($FFFFFF, ''));
            end);
        end);

      Describe('CreateNif', procedure
        begin
          AfterAll(procedure
            begin
              DeleteNifs(['test.nif', 'meshes\test.nif', 'meshes\test\test.nif']);
            end);

          It('Should return true for an absolute path', procedure
            begin
              ExpectSuccess(CreateNif(PWideChar(GetDataPath + 'test.nif'), true, @h));
              ExpectSuccess(FileExists(GetDataPath + 'test.nif'));
            end);

          It('Should return true for a path relative to data\', procedure
            begin
              ExpectSuccess(CreateNif('meshes\test.nif', true, @h));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test.nif'));
            end);

          It('Should return true for a relative path starting with data\', procedure
            begin
              ExpectSuccess(CreateNif('data\meshes\test\test.nif', true, @h));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test\test.nif'));
            end);

          It('Should return false if the file exists and ignoreExists is false', procedure
            begin
              ExpectFailure(CreateNif('test.nif', false, @h));
            end);

          It('Should return true if the file exists and ignoreExists is true', procedure
            begin
              ExpectSuccess(CreateNif('test.nif', true, @h));
            end);

          It('Should let you create a nif without saving it to the disk, by passing an empty filepath', procedure
            begin
              ExpectSuccess(CreateNif('', false, @h));
            end);

          It('Should set the correct Nif version', procedure
            begin
              // TODO
            end);
        end);

      Describe('HasNifElement', procedure
        begin
          It('Should return true for blocks that exist', procedure
            begin
              TestHasNifElement(nif, 'BSFadeNode');
            end);

          It('Should return true for block properties that exist', procedure
            begin
              TestHasNifElement(rootBlock, 'Name');
            end);

          It('Should return true for assigned handles', procedure
            begin
              TestHasNifElement(nif, '');
            end);

          It('Should return false for blocks that do not exist', procedure
            begin
              TestHasNifElement(nif, 'NonExistingBlock', false);
            end);

          It('Should return false for block properties that do not exist', procedure
            begin
              TestHasNifElement(rootBlock, 'NonExistingElement', false);
            end);

          It('Should fail if the handle is unassigned', procedure
            begin
              ExpectFailure(HasNifElement($FFFFFF, '', @b));
            end);
        end);

      Describe('GetNifElement', procedure
        begin
          Describe('Block resolution by index', procedure
            begin
              It('Should return a handle if the index is in bounds', procedure
                begin
                  TestGetNifElement(nif, '[0]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectFailure(GetNifElement(nif, '[-9]', @h));
                end);
            end);

          Describe('Block resolution by block type', procedure
            begin
              It('Should return a handle if a matching block exists', procedure
                begin
                  TestGetNifElement(nif, 'BSFadeNode');
                  TestGetNifElement(nif, 'NiNode');
                end);

              It('Should fail if a matching block does not exist', procedure
                begin
                  ExpectFailure(GetNifElement(nif, 'NonExistingBlock', @h));
                end);
            end);

          Describe('Block resolution by name', procedure
            begin
              It('Should return a handle if a matching block exists', procedure
                begin
                  TestGetNifElement(nif, '"WindhelmThrone"');
                end);

              It('Should fail if a matching block does not exist', procedure
                begin
                  ExpectFailure(GetNifElement(nif, '"John Doe"', @h));
                end);
            end);

          Describe('Block property resolution by index', procedure
            begin
              It('Should return a handle if the index is in bounds', procedure
                begin
                  TestGetNifElement(rootBlock, '[0]');

                  ExpectSuccess(GetNifElement(rootBlock, 'Children', @h));
                  TestGetNifElement(h, '[1]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectFailure(GetNifElement(rootBlock, '[-9]', @h));

                  ExpectSuccess(GetNifElement(rootBlock, 'Children', @h));
                  ExpectFailure(GetNifElement(h, '[20]', @h));
                end);
            end);

          Describe('Block property resolution by name', procedure
            begin
              It('Should return a handle if a matching element exists', procedure
                begin
                  TestGetNifElement(rootBlock, 'Name');
                end);

              It('Should fail if a matching element does not exist', procedure
                begin
                  ExpectFailure(GetNifElement(rootBlock, 'NonExistingElement', @h));
                end);
            end);

          Describe('Reference resolution', procedure
            begin
              It('Should return a handle if the property exists and has a reference', procedure
                begin
                  TestGetNifElement(rootBlock, 'Children\@[0]');
                  TestGetNifElement(rootBlock, 'Extra Data List\@[0]');
                  TestGetNifElement(rootBlock, '@Collision Object');
                end);

              It('Should fail if the property exists, but does not have a reference', procedure
                begin
                  ExpectSuccess(GetNifElement(nif, 'NiTriShape', @h));
                  ExpectFailure(GetNifElement(h, '@Collision Object', @h));
                end);

              It('Should fail if the property does not exist', procedure
                begin
                  ExpectSuccess(GetNifElement(nif, 'NiTriShape', @h));
                  ExpectFailure(GetNifElement(h, '@NonExistingProperty', @h));
                end);

              Describe('Get reference of self', procedure
                begin
                  It('Should return a handle if the property has a reference', procedure
                    begin
                      ExpectSuccess(GetNifElement(nif, 'BSFadeNode\Collision Object', @h));
                      TestGetNifElement(h, '@');
                    end);

                  It('Should fail if the property does not have a reference', procedure
                    begin
                      ExpectSuccess(GetNifElement(nif, 'NiTriShape\Collision Object', @h));
                      ExpectFailure(GetNifElement(h, '@', @h));
                    end);
                end);
            end);

          Describe('Keyword resolution', procedure
            begin
              It('Should return a handle for the roots element', procedure
                begin
                  TestGetNifElement(nif, 'Roots');
                end);

              It('Should return a handle for the header', procedure
                begin
                  TestGetNifElement(nif, 'Header');
                end);

              It('Should return a handle for the footer', procedure
                begin
                  TestGetNifElement(nif, 'Footer');
                end);
            end);

          Describe('Nested resolution', procedure
            begin
              It('Should resolve nested paths, if all are valid', procedure
                begin
                  TestGetNifElement(nif, 'BSFadeNode\Children\@[0]\Children\@[0]\@Shader Property\@Texture Set\Textures\[1]');
                end);

              It('Should fail if any subpath is invalid', procedure
                begin
                  ExpectFailure(GetNifElement(nif, 'BSFadeNode\Children\@[0]\Children\@[0]\@NonExistingProperty', @h));
                end);
            end);
        end);

      Describe('GetNifElements', procedure
        begin
          It('Should resolve blocks in a nif file', procedure
            begin
              ExpectSuccess(GetNifElements(nif, '', @len));
              ExpectEqual(len, 39);
              TestNames(gra(len), 'NiHeader', 'NiFooter');
            end);

          It('Should resolve elements in a block', procedure
            begin
              ExpectSuccess(GetNifElements(rootBlock, '', @len));
              ExpectEqual(len, 13);
              TestNames(gra(len), 'Name', 'Effects');
            end);

          It('Should resolve elements in a struct', procedure
            begin
              ExpectSuccess(GetNifElements(transformStruct, '', @len));
              ExpectEqual(len, 3);
              TestNames(gra(len), 'Translation', 'Scale');
            end);     

          It('Should resolve elements in an array', procedure
            begin
              ExpectSuccess(GetNifElements(vectorArray, '', @len));
              ExpectEqual(len, 111);
              TestNames(gra(len), 'Tangents #0', 'Tangents #110');
            end);

          It('Should fail if element isn''t a container', procedure
            begin
              ExpectFailure(GetNifElements(vector, '', @len));
            end);
        end);

       Describe('AddNifBlock', procedure
         begin
           Describe('Adding blocks to nif files', procedure
             begin
               It('Should add a new block with the passed block type', procedure
                 begin
                   ExpectSuccess(AddNifBlock(xt1, '', 'BSXFlags', @h));
                   Expect(h > 0, 'Handle should be greater than 0');
                   TestHasNifElement(xt1, 'BSXFlags');
                 end);

               It('Should add the first added NiNode type block as a root', procedure
                 begin
                   ExpectSuccess(CreateNif('', false, @h));
                   ExpectSuccess(GetNifElement(h, 'Roots', @h2));
                   
                   ExpectSuccess(AddNifBlock(h, '', 'BSFurnitureMarkerNode', @h3));
                   TestNifElementCount(h2, 0);
                   ExpectSuccess(AddNifBlock(h, '', 'BSFadeNode', @h3));
                   TestNifElementCount(h2, 1);
                   ExpectSuccess(AddNifBlock(h, '', 'BSFadeNode', @h3));
                   TestNifElementCount(h2, 1);
                 end);

               It('Should fail if the block type is invalid', procedure
                 begin
                   ExpectFailure(AddNifBlock(xt1, '', 'NonExistingBlockType', @h));
                 end);
             end);

           Describe('Adding blocks to arrays of references', procedure
             begin
               It('Should add a new block with the passed block type', procedure
                 begin
                   ExpectSuccess(AddNifBlock(xt1, 'BSFadeNode\Children', 'NiParticles', @h));
                   Expect(h > 0, 'Handle should be greater than 0');
                   TestHasNifElement(xt1, 'NiParticles');
                 end);

               It('Should add a new reference to the array, if there are no None references', procedure
                 begin
                   ExpectSuccess(NifElementCount(refArray, @i));
                   ExpectSuccess(AddNifBlock(refArray, '', 'NiNode', @h));
                   TestNifElementCount(refArray, i + 1);
                 end);

               It('Should make the newly added reference link to the newly added block', procedure
                 begin
                  ExpectSuccess(AddNifBlock(refArray, '', 'NiNode', @h));
                  ExpectSuccess(GetNifElement(refArray, '@[-1]', @h2));
                  TestNifElementEquals(h, h2);
                 end);                                  

               It('Should reuse existing None references in the array', procedure
                 begin
                   ExpectSuccess(NifElementCount(refArray, @i));
                   ExpectSuccess(RemoveNifBlock(refArray, '@[-1]', false));
                   ExpectSuccess(AddNifBlock(refArray, '', 'NiNode', @h));
                   TestNifElementCount(refArray, i);
                 end);

               It('Should fail if the array cannot have references to the passed block type', procedure
                begin
                  ExpectFailure(AddNifBlock(rootBlock, 'Extra Data List', 'NiNode', @h));
                end);                 

               It('Should fail if the array cannot have references', procedure
                 begin
                  ExpectFailure(AddNifBlock(nif, 'Header\Block Size', 'NiNode', @h));
                  ExpectFailure(AddNifBlock(nif, 'NiTriShapeData\Triangles', 'NiNode', @h));
                 end);
             end);

           Describe('Adding blocks to references', procedure
             begin
               It('Should add a new block with the passed block type', procedure
                 begin
                   ExpectSuccess(AddNifBlock(refArray, '[-1]', 'NiParticles', @h));
                   Expect(h > 0, 'Handle should be greater than 0');
                   TestHasNifElement(xt2, 'NiParticles');
                 end);

               It('Should make the reference link to the newly added block', procedure
                 begin
                   ExpectSuccess(AddNifBlock(refArray, '[-1]', 'NiNode', @h));
                   ExpectSuccess(GetNifElement(refArray, '@[-1]', @h2));
                   TestNifElementEquals(h, h2);
                 end);

               It('Should return the currently linked block if the reference already links to a block with the passed block type', procedure
                 begin
                   ExpectSuccess(GetNifElement(refArray, '@[-1]', @h));
                   ExpectSuccess(AddNifBlock(refArray, '[-1]', 'NiNode', @h2));
                   TestNifElementEquals(h, h2);
                 end);

               It('Should not add a new block if the reference already links to a block with the passed block type', procedure
                 begin
                  ExpectSuccess(NifElementCount(xt1, @i));
                  ExpectSuccess(AddNifBlock(refArray, '[-1]', 'NiNode', @h));
                  TestNifElementCount(xt1, i)
                 end);                 

               It('Should fail if the reference cannot link to the passed block type', procedure
                 begin
                   ExpectFailure(AddNifBlock(rootBlock, 'Extra Data List\[1]', 'NiNode', @h));
                 end);
             end);

           It('Should fail if interface is neither a nif file, an array, nor a reference', procedure
             begin
               ExpectFailure(AddNifBlock(rootBlock, '', 'NiNode', @h));
               ExpectFailure(AddNifBlock(transformStruct, '', 'NiNode', @h));
               ExpectFailure(AddNifBlock(vector, '', 'NiNode', @h));
             end);
         end);

        Describe('RemoveNifBlock', procedure
          begin
            BeforeAll(procedure
              begin
                ExpectSuccess(LoadNif('meshes\furniture\windhelm\windhelmthrone.nif', @h));
              end);

            It('Should be able to remove blocks', procedure
              begin
                TestRemoveNifBlock(h, 'BSXFlags');
              end);

            It('Should clear references to the removed block', procedure
              begin
                TestRemoveNifBlock(h, 'bhkCompressedMeshShapeData');
                ExpectFailure(GetNifElement(h, 'bhkCompressedMeshShape\@Data', @h2));
                ExpectSuccess(GetNifIntValue(h, 'bhkCompressedMeshShape\Data', @i));
                ExpectEqual(i, -1);
              end);

            It('Should remove the block passed if no path is given', procedure
              begin
                ExpectSuccess(GetNifElement(h, 'bhkMoppBvTreeShape', @h2));
                ExpectSuccess(RemoveNifBlock(h2, '', False));
                ExpectSuccess(HasNifElement(h, 'bhkMoppBvTreeShape', @b));
                Expect(not b, 'The element should no longer be present');
              end);

            Describe('Recursion', procedure
              begin
                It('Should recursively remove all NiRef type linked blocks in the removed block', procedure
                  begin
                    TestNifElementCount(h, 36);
                    TestRemoveNifBlock(h, 'NiNode', True);
                    TestNifElementCount(h, 27);
                  end);

                It('Should not remove NiPtr type linked blocks in the removed block', procedure
                  begin
                    TestRemoveNifBlock(h, 'bhkCollisionObject', True);
                    TestNifElementCount(h, 25);
                    TestHasNifElement(h, 'BSFadeNode');
                  end);
              end);

            It('Should not be able to remove the header', procedure
              begin
                ExpectFailure(RemoveNifBlock(h, 'Header', False));
                TestHasNifElement(h, 'Header');
              end);

            It('Should not be able to remove the footer', procedure
              begin
                ExpectFailure(RemoveNifBlock(h, 'Footer', False));
                TestHasNifElement(h, 'Footer');
              end);

            It('Should fail if the element is not a nif block', procedure
              begin
                ExpectFailure(RemoveNifBlock(h, '', False));
                ExpectFailure(RemoveNifBlock(h, 'BSFadeNode\Name', False));
                ExpectFailure(RemoveNifBlock(h, 'BSFadeNode\Children\[0]', False));
              end);
          end);

        Describe('MoveNifBlock', procedure
          begin
            It('Should move blocks to the passed index', procedure
              begin
                ExpectSuccess(MoveNifBlock(xt1, 'BSBlastNode', 11));
                TestGetNifElementIndex(xt1, 'BSBlastNode', 11);
              end);

            It('Should treat the index "-1" as the max index', procedure
              begin
                ExpectSuccess(NifElementCount(xt1, @i));
                ExpectSuccess(GetNifElement(xt1, 'BSBlastNode', @h));
                ExpectSuccess(MoveNifBlock(h, '', -1));
                TestGetNifElementIndex(h, '', i - 3); // -3 to account for header/footer
              end);

            It('Should fail if the passed index is out of bonds', procedure
              begin
                ExpectFailure(MoveNifBlock(rootBlock, '', -2));
                ExpectFailure(MoveNifBlock(rootBlock, '', 40));
              end);

            It('Should fail if the element is not a nif block', procedure
              begin
                ExpectFailure(MoveNifBlock(nif, '', 0));
                ExpectFailure(MoveNifBlock(nif, 'BSFadeNode\Name', 0));
                ExpectFailure(MoveNifBlock(nif, 'BSFadeNode\Children\[0]', 0));
              end);
          end);

      Describe('GetNifBlocks', procedure
        begin
          Describe('No search', procedure
            begin
              It('Should return all blocks in a Nif file', procedure
                begin
                  TestGetNifBlocks(nif, '', '', 37);
                end);

              It('Should return all referenced blocks in a Nif block', procedure
                begin
                  TestGetNifBlocks(nif, 'BSFadeNode', '', 9);
                  TestGetNifBlocks(nif, 'BSFurnitureMarkerNode', '', 0);
                end);
            end);

          Describe('Search', procedure
            begin
              It('Should return all blocks of a given block type in a Nif file', procedure
                begin
                  TestGetNifBlocks(nif, '', 'NiTriShape', 7);
                end);

              It('Should return all referenced blocks of a given block type in a Nif block', procedure
                begin
                  TestGetNifBlocks(nif, 'BSFadeNode', 'NiTriShape', 5);
                  TestGetNifBlocks(nif, 'BSFurnitureMarkerNode', 'NiTriShape', 0);
                end);
            end);

          It('Should fail if interface is neither a nif file nor a nif block', procedure
            begin
              ExpectFailure(GetNifBlocks(float, '', @len));
              ExpectFailure(GetNifBlocks(ref, '', @len));
            end);
        end);

      Describe('GetNifDefNames', procedure
        begin
          It('Should work with blocks', procedure
            begin
              TestGetNifDefNames(rootBlock, True, TStringArray.Create('Name', 'Extra Data List', 'Controller', 'Flags', 
                'Transform', 'Collision Object', 'Children', 'Effects'));
              TestGetNifDefNames(rootBlock, False, TStringArray.Create('Name', 'Extra Data', 'Extra Data List', 'Controller',
                'Flags', 'Transform', 'Velocity', 'Properties', 'Has Bounding Volume', 'Bounding Volume',
                'Collision Object', 'Children', 'Effects'));
            end);

          It('Should work with structs', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'Header\Export Info', @h));
              TestGetNifDefNames(h, True, TStringArray.Create('Author', 'Process Script', 'Export Script'));
              TestGetNifDefNames(h, False, TStringArray.Create('Unknown Int', 'Author', 'Process Script', 'Export Script'));
            end);

          It('Should work with arrays', procedure
            begin
              TestGetNifDefNames(vectorArray, True, TStringArray.Create('Tangents'));
            end);

          It('Should resolve unions', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'BSXFlags', @h));
              TestGetNifDefNames(h, True, TStringArray.Create('Name', 'Flags'));
            end);            

          It('Should fail if the element is a nif file', procedure
            begin
              ExpectFailure(GetNifDefNames(nif, True, @len));
            end);
        end);        

      Describe('GetNifLinksTo', procedure
        begin
          It('Should return the referenced block', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'bhkCollisionObject\@Target', @h));
              TestGetNifLinksTo(nif, 'bhkCollisionObject\Target', h);
              ExpectSuccess(GetNifElement(nif, 'bhkCollisionObject\@Body', @h));
              TestGetNifLinksTo(nif, 'bhkCollisionObject\Body', h);
            end);

          It('Should return 0 if called on a None reference or an invalid reference', procedure
            begin
              ExpectSuccess(GetNifLinksTo(rootBlock, 'Controller', @h));
              ExpectEqual(h, 0);
              ExpectSuccess(SetNifIntValue(rootBlock, 'Controller', 99));
              ExpectSuccess(GetNifLinksTo(rootBlock, 'Controller', @h2));
              ExpectEqual(h2, 0);
            end);

          It('Should fail if path is invalid', procedure
            begin
              ExpectFailure(GetNifLinksTo(vectorArray, '[-2]', @h));
            end);

          It('Should fail on elements that cannot hold a reference', procedure
            begin
              ExpectFailure(GetNifLinksTo(nif, '', @h));
              ExpectFailure(GetNifLinksTo(rootBlock, '', @h));
              ExpectFailure(GetNifLinksTo(vector, '', @h));
            end);
        end);

      Describe('SetNifLinksTo', procedure
        begin
          It('Should set references', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'NiNode', @h));
              ExpectSuccess(SetNifLinksTo(nif, 'BSFadeNode\Children\[-1]', h));
              TestGetNifLinksTo(nif, 'BSFadeNode\Children\[-1]', h);
            end);

          It('Should fail if the first element cannot hold a reference', procedure
            begin
              ExpectFailure(SetNifLinksTo(nif, '', h));
              ExpectFailure(SetNifLinksTo(rootBlock, '', h));
              ExpectFailure(SetNifLinksTo(vector, '', h));
            end);

          It('Should fail if the first element cannot hold a reference to the second element''s block type', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'NiTriShape', @h));
              ExpectFailure(SetNifLinksTo(rootBlock, 'Controller', h));
            end);

          It('Should fail if the second element isn''t a block', procedure
            begin
              ExpectFailure(SetNifLinksTo(nif, 'BSFadeNode\Children\[0]', vector));
            end);
        end);

      Describe('NifElementCount', procedure
        begin
          It('Should return the number of blocks in a nif file', procedure
            begin
              TestNifElementCount(nif, 39);
            end);

          It('Should return the number of elements in a block', procedure
            begin
              TestNifElementCount(rootBlock, 13);
            end);

          It('Should return the number of elements in a struct', procedure
            begin
              ExpectSuccess(GetNifElement(header, 'Export Info', @h));
              TestNifElementCount(h, 4);
            end);

          It('Should return the number of elements in an array', procedure
            begin
              ExpectSuccess(GetNifElement(rootBlock, 'Children', @h));
              TestNifElementCount(h, 6);
            end);

          It('Should return 0 if there are no children', procedure
            begin
              ExpectSuccess(GetNifElement(rootBlock, 'Name', @h));
              TestNifElementCount(h, 0);
            end);
        end);

      Describe('NifElementEquals', procedure
        begin
          It('Should return true for equal elements', procedure
            begin
              TestNifElementEquals(rootBlock, nif, '[0]');
              TestNifElementEquals(transformStruct, rootBlock, 'Transform');
              TestNifElementEquals(vector, vectorArray, '[0]');
              TestNifElementEquals(float, transformStruct, 'Scale');
            end);

          It('Should return false for different elements holding the same value', procedure
            begin
              TestNifElementEquals(float, nif, 'NiNode\Transform\Scale', False);
            end);

          It('Should return false for different elements', procedure
            begin
              TestNifElementEquals(rootBlock, transformStruct, False);
              TestNifElementEquals(transformStruct, refArray, False);
              TestNifElementEquals(refArray, ref, False);
              TestNifElementEquals(ref, vector, False);
              TestNifElementEquals(vector, float, False);
            end);

          It('Should fail if the handles are unassigned', procedure
            begin
              ExpectFailure(NifElementEquals($FFFFFF, 999999, @b));
            end);
        end);

      Describe('NifElementMatches', procedure
        begin
          It('Should return true if the edit value matches', procedure
            begin
              TestNifElementMatches(rootBlock, 'Name', 'WindhelmThrone');
              TestNifElementMatches(float, '', '1.0');
              TestNifElementMatches(float, '', '1');
              TestNifElementMatches(vector, '', '0.000006 -1.000000 -0.000350');
            end);

          It('Should return false if the edit value doesn''t match', procedure
            begin
              TestNifElementMatches(rootBlock, 'Name', 'WiNdHeLmThRoNe', false);
              TestNifElementMatches(float, '', '1.000001', false);
              TestNifElementMatches(vector, '', '0.000000 0.000000 1.000000', false);
            end);            

         Describe('References', procedure
           begin
             It('Should be able to match indexes', procedure
              begin
                TestNifElementMatches(ref, '', '[8]');
                TestNifElementMatches(ref, '', '[9]', false);
              end);

             It('Should be able to match block types', procedure
              begin
                TestNifElementMatches(ref, '', 'NiNode');
                TestNifElementMatches(ref, '', 'NiTriShape', false);
              end);         

            It('Should be able to match names', procedure
              begin
                TestNifElementMatches(ref, '', '"SteelShield"');
                TestNifElementMatches(ref, '', '"SteelArmor"', false);
                TestNifElementMatches(ref, '', 'SteelShield', false);
              end);     
           end);
        end);

      Describe('HasNifArrayItem', procedure
        begin
          Describe('Without subpath', procedure
            begin
              It('Should return true if array item is present', procedure
                begin
                  TestHasNifArrayItem(refArray, '', '', 'BSTriShape');
                  TestHasNifArrayItem(nif, 'Header\Strings', '', 'SteelShield');
                end);

              It('Should return false if array item is not present', procedure
                begin
                  TestHasNifArrayItem(refArray, '', '', 'BSFadeNode', false);
                  TestHasNifArrayItem(nif, 'Header\Strings', '', 'Nope', false);
                end);
            end);

          Describe('With subpath', procedure
            begin
              It('Should return true if array item is present', procedure
                begin
                  TestHasNifArrayItem(xt1, 'NiRangeLODData\LOD Levels', 'Near Extent', '-1');
                  TestHasNifArrayItem(refArray, '', '@\Transform\Scale', '1');
                end);

              It('Should return false if no element has the provided value', procedure
                begin
                  TestHasNifArrayItem(xt1, 'NiRangeLODData\LOD Levels', 'Near Extent', '-3', false);
                  TestHasNifArrayItem(refArray, '', '@\Transform\Scale', '2', false);
                  TestHasNifArrayItem(refArray, '', '@\Non\Existing\Path', '2', false);
                end);
            end);

          It('Should fail if the element at path isn''t an array', procedure
            begin
              ExpectFailure(HasNifArrayItem(nif, '', '', 'Test', @h));
              ExpectFailure(HasNifArrayItem(nif, 'BSFadeNode', '', 'Test', @h));
            end);            
        end);  

      Describe('GetNifArrayItem', procedure
        begin
          Describe('Without subpath', procedure
            begin
              It('Should succeed if array item is present', procedure
                begin
                  TestGetNifArrayItem(refArray, '', '', 'BSTriShape');
                  TestGetNifArrayItem(nif, 'Header\Strings', '', 'SteelShield');
                end);

              It('Should fail if array item isn''t present', procedure
                begin
                  ExpectFailure(GetNifArrayItem(refArray, '', '', 'BSFadeNode', @h));
                  ExpectFailure(GetNifArrayItem(nif, 'Header\Strings', '', 'Nope', @h));
                  ExpectFailure(GetNifArrayItem(nif, 'Non\Existing\Path', '', 'Nope', @h));
                end);
            end);

          Describe('With subpath', procedure
            begin
              It('Should succeed if array item is present', procedure
                begin
                  TestGetNifArrayItem(xt1, 'NiRangeLODData\LOD Levels', 'Near Extent', '-1');
                  TestGetNifArrayItem(refArray, '', '@\Transform\Scale', '1');
                end);

              It('Should fail if no element has the provided value', procedure
                begin
                  ExpectFailure(GetNifArrayItem(xt1, 'NiRangeLODData\LOD Levels', 'Near Extent', '-3', @h));
                  ExpectFailure(GetNifArrayItem(refArray, '', '@\Transform\Scale', '2', @h));
                  ExpectFailure(GetNifArrayItem(refArray, '', '@\Non\Existing\Path', '2', @h));
                end);
            end);

          It('Should fail if the element at path isn''t an array', procedure
            begin
              ExpectFailure(GetNifArrayItem(nif, '', '', 'Test', @h));
              ExpectFailure(GetNifArrayItem(nif, 'BSFadeNode', '', 'Test', @h));
            end);
        end);     

      Describe('AddNifArrayItem', procedure
        begin
          It('Should be able to add an array item', procedure
            begin
              TestAddNifArrayItem(nif, 'Header\Strings', '', '');
              TestAddNifArrayItem(nif, 'NiTriShapeData\Normals', '', '');
            end);

          Describe('Without subpath', procedure
            begin
              It('Should be able to set the value of the added array item', procedure
                begin
                  TestAddNifArrayItem(nif, 'Header\Strings', '', 'TestString');
                end);

              It('Should work with references', procedure
                begin
                  TestAddNifArrayItem(refArray, '', '', '5 NiNode');
                end);
            end);

          Describe('With subpath', procedure
            begin
              It('Should be able to set the value of the element at the subpath', procedure
                begin
                  TestAddNifArrayItem(xt1, 'NiRangeLODData\LOD Levels', 'Far Extent', '-5.000000');
                end);

              It('Should work with references', procedure
                begin
                  // TODO
                end);                

              It('Should fail if the subpath is invalid', procedure
                begin
                  ExpectFailure(AddNifArrayItem(h, '', 'Fake\Path', '-5.000000', @h));
                end);
            end);

          It('Should fail if the element at path isn''t an array', procedure
            begin
              ExpectFailure(AddNifArrayItem(nif, '', '', 'Test', @h));
              ExpectFailure(AddNifArrayItem(nif, 'BSFadeNode', '', 'Test', @h));
            end);
        end);

      Describe('RemoveNifArrayItem', procedure
        begin
          BeforeAll(procedure
            begin
              ExpectSuccess(LoadNif('xtest-1.nif', @h));
            end);

          Describe('Without subpath', procedure
            begin
              It('Should succeed if array item is present', procedure
                begin
                  TestRemoveNifArrayItem(h, 'BSFadeNode\Children', '', 'BSTriShape');
                  TestRemoveNifArrayItem(h, 'Header\Strings', '', 'Blocky McBlockFace');
                end);
            end);

          Describe('With subpath', procedure
            begin
              It('Should succeed if array item is present', procedure
                begin
                  TestRemoveNifArrayItem(h, 'NiRangeLODData\LOD Levels', 'Far Extent', '23');
                  TestRemoveNifArrayItem(h, 'BSFadeNode\Children', '@\Transform\Scale', '1');
                end);
            end);

          It('Should fail if the element at path isn''t an array', procedure
            begin
              ExpectFailure(RemoveNifArrayItem(nif, '', '', 'Test'));
              ExpectFailure(RemoveNifArrayItem(nif, 'BSFadeNode', '', 'Test'));
            end);
        end);

      Describe('MoveNifArrayItem', procedure
        begin
          It('Should move the array item to the provided index', procedure
            begin
              ExpectSuccess(GetNifElement(refArray, '[0]', @h));
              TestMoveNifArrayItem(h, 2);
              ExpectSuccess(GetNifElement(nif, 'NiTriShapeData\Bitangents\[7]', @h));
              TestMoveNifArrayItem(h, 17);
            end);

          It('Should treat the index "-1" as the max index of the array', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'NiTriShapeData\Normals\[5]', @h));
              ExpectSuccess(MoveNifArrayItem(h, -1));
              ExpectSuccess(GetNifElementIndex(h, @i));
              ExpectEqual(i, 111);
            end);

          It('Should fail if the index is out of bounds', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'NiTriShapeData\Tangents\[0]', @h));
              ExpectFailure(MoveNifArrayItem(h, -2));
              ExpectFailure(MoveNifArrayItem(h, 9001));
            end);

          It('Should fail if the container isn''t an array', procedure
            begin
              ExpectFailure(MoveNifArrayItem(float, 2));
            end);
        end);        

      Describe('GetNifElementIndex', procedure
        begin
          It('Should return the index of blocks', procedure
            begin
              TestGetNifElementIndex(rootBlock, '', 0);
              TestGetNifElementIndex(nif, 'NiTriShape', 9);
            end);

          It('Should return the index of block elements', procedure
            begin
              TestGetNifElementIndex(transformStruct, '', 5);
              TestGetNifElementIndex(vectorArray, '', 11);
            end);

          It('Should return the index of elements in a struct', procedure
            begin
              TestGetNifElementIndex(header, 'Export Info\Export Script', 3);
              TestGetNifElementIndex(transformStruct, 'Rotation', 1);
            end);

          It('Should return the index of elements in arrays', procedure
            begin
              TestGetNifElementIndex(vectorArray, '[2]', 2);
              TestGetNifElementIndex(nif, 'BSShaderTextureSet\Textures\[4]', 4);
            end);

          It('Should fail if the element is a nif file', procedure
            begin
              ExpectFailure(GetNifElementIndex(nif, @i));
            end);

          It('Should fail if the element is a nif header', procedure
            begin
              ExpectFailure(GetNifElementIndex(header, @i));
            end);

          It('Should fail if the element is a nif footer', procedure
            begin
              ExpectFailure(GetNifElementIndex(footer, @i));
            end);
        end);

      Describe('GetNifElementFile', procedure
        begin
          It('Should return the input if the input is a nif file', procedure
            begin
              TestGetNifElementFile(nif, nif);
            end);

          It('Should return the file containing a nif block', procedure
            begin
              TestGetNifElementFile(rootBlock, nif);
            end);

          It('Should return the file containing a nif element', procedure
            begin
              TestGetNifElementFile(transformStruct, nif);
              TestGetNifElementFile(vectorArray, nif);
              TestGetNifElementFile(ref, nif);
              TestGetNifElementFile(vector, nif);
            end);
        end);

      Describe('GetNifElementBlock', procedure
        begin
          It('Should fail if the input is a nif file', procedure
            begin
              ExpectFailure(GetNifElementBlock(nif, @h));
            end);

          It('Should return the input if the input is a nif block', procedure
            begin
              TestGetNifElementBlock(rootBlock, rootBlock);
            end);

          It('Should return the block containing a nif element', procedure
            begin
              TestGetNifElementBlock(transformStruct, rootBlock);
              TestGetNifElementBlock(float, rootBlock);
              TestGetNifElementBlock(ref, rootBlock);
            end);
        end);

      Describe('GetNifContainer', procedure
        begin
          It('Should fail if the input is a nif file', procedure
            begin
              ExpectFailure(GetNifContainer(nif, @h));
            end);

          It('Should return the file containing a nif block', procedure
            begin
              TestGetNifContainer(rootBlock, '', nif);
              TestGetNifContainer(nif, 'Header', nif);
            end);

          It('Should return the block containing a block property', procedure
            begin
              TestGetNifContainer(transformStruct, '', rootBlock);
            end);

          It('Should return the parent element containing a child element', procedure
            begin
              TestGetNifContainer(vector, '', vectorArray);
              TestGetNifContainer(float, '', transformStruct);
            end);
        end);

     Describe('NifBlockTypeExists', procedure
       begin
         It('Should return true if the block type exists', procedure
           begin
             TestNifBlockTypeExists('BSFadeNode', true);
             TestNifBlockTypeExists('NiBSplinePoint3Interpolator', true);
             TestNifBlockTypeExists('BSSkin::BoneData', true);
           end);

         It('Should return false if the block type doesn''t exist', procedure
           begin
             TestNifBlockTypeExists('Invalid', false);
           end);
       end);        

     Describe('IsNifBlockType', procedure
       begin
         It('Should return true if the block types are equal', procedure
           begin
             TestIsNifBlockType('BSFadeNode', 'BSFadeNode', true, true);
           end);

         It('Should return true if the first block type is a descendant of the second block type, if _inherited is true', procedure
           begin
             TestIsNifBlockType('BSFadeNode', 'NiNode', true, true);
           end);

         It('Should return false even if the first block type is a descendant of the second block type, if _inherited is false', procedure
           begin
             TestIsNifBlockType('BSFadeNode', 'NiNode', false, false);
           end);

         It('Should return false if the first block type neither equals the second block type, nor is a descendant of it', procedure
           begin
             TestIsNifBlockType('BSFadeNode', 'BSTriShape', true, false);
             TestIsNifBlockType('BSFadeNode', 'BSTriShape', false, false);
           end);           

         It('Should fail if either of the two block types don''t exist', procedure
           begin
             ExpectFailure(IsNifBlockType('Invalid', 'NiNode', true, @len));
             ExpectFailure(IsNifBlockType('NiNode', 'Invalid', true, @len));
             ExpectFailure(IsNifBlockType('Invalid', 'Invalid', true, @len));
           end);
       end);

     Describe('HasNifBlockType', procedure
       begin
         It('Should return true if the block has the provided block type', procedure
           begin
             TestHasNifBlockType(rootBlock, '', 'BSFadeNode', true, true);
             TestHasNifBlockType(nif, 'NiTriShape', 'NiTriShape', true, true);
           end);

         It('Should return true if the block''s block type is a descendant of the provided block type, if _inherited is true', procedure
           begin
             TestHasNifBlockType(rootBlock, '', 'NiNode', true, true);
             TestHasNifBlockType(nif, 'bhkRigidBody', 'bhkWorldObject', true, true);
           end);

         It('Should return false even if the block''s block type is a descendant of the provided block type, if _inherited is false', procedure
           begin
             TestHasNifBlockType(rootBlock, '', 'NiNode', false, false);
             TestHasNifBlockType(nif, 'bhkRigidBody', 'bhkWorldObject', false, false);
           end);

         It('Should return false if the block''s block type neither equals the provided block type, nor is a descendant of it', procedure
           begin
             TestHasNifBlockType(rootBlock, '', 'NiTriShape', true, false);
             TestHasNifBlockType(nif, 'NiTriShape', 'NiNode', true, false);
           end);

         It('Should fail if the provided element isn''t a nif block', procedure
           begin
             ExpectFailure(HasNifBlockType(nif, '', 'NiNode', true, @b));
             ExpectFailure(HasNifBlockType(ref, '', 'NiNode', true, @b));
             ExpectFailure(HasNifBlockType(vector, '', 'NiNode', true, @b));
           end);

         It('Should fail if the provided block type doesn''t exist', procedure
           begin
             ExpectFailure(HasNifBlockType(rootBlock, '', 'Invalid', true, @b));
           end);
       end);

      Describe('GetNifTemplate', procedure
        begin
          It('Should resolve the template of references', procedure
            begin
              ExpectSuccess(GetNifTemplate(ref, '', @len));
              ExpectEqual(grs(len), 'NiAVObject');
              ExpectSuccess(GetNifTemplate(rootBlock, 'Controller', @len));
              ExpectEqual(grs(len), 'NiTimeController');
            end);

          It('Should fail if the input isn''t a reference', procedure
            begin
              ExpectFailure(GetNifTemplate(nif, '', @len));
              ExpectFailure(GetNifTemplate(rootBlock, '', @len));
              ExpectFailure(GetNifTemplate(vector, '', @len));
            end);
        end);

      Describe('GetNifBlockTypeAllowed', procedure
        begin
          It('Should return true if the block type is allowed', procedure
            begin
              TestGetNifBlockTypeAllowed(ref, 'NiAVObject', true);
              TestGetNifBlockTypeAllowed(ref, 'BSFadeNode', true);
              TestGetNifBlockTypeAllowed(ref, 'NiTriShape', true);
              ExpectSuccess(GetNifElement(nif, 'NiTriShape\Shader Property', @h));
              TestGetNifBlockTypeAllowed(h, 'BSShaderProperty', true);
              TestGetNifBlockTypeAllowed(h, 'BSLightingShaderProperty', true);
            end);

          It('Should return false if the block type isn''t allowed', procedure
            begin
              TestGetNifBlockTypeAllowed(ref, 'BSXFlags', false);
              TestGetNifBlockTypeAllowed(ref, 'bhkCollisionObject', false);
              TestGetNifBlockTypeAllowed(ref, 'BSShaderProperty', false);
              ExpectSuccess(GetNifElement(nif, 'NiTriShape\Shader Property', @h));
              TestGetNifBlockTypeAllowed(h, 'NiAVObject', false);
              TestGetNifBlockTypeAllowed(h, 'BSFadeNode', false);
            end);

          It('Should fail if the input isn''t a reference', procedure
            begin
              ExpectFailure(GetNifBlockTypeAllowed(nif, 'BSFadeNode', @b));
              ExpectFailure(GetNifBlockTypeAllowed(rootBlock, 'BSFadeNode', @b));
              ExpectFailure(GetNifBlockTypeAllowed(vector, 'BSFadeNode', @b));
            end);
        end);        

      Describe('IsNiPtr', procedure
        begin
          It('Should return true if the reference is a NiPtr', procedure
            begin
              ExpectSuccess(IsNiPtr(nif, 'bhkCompressedMeshShape\Target', @b));
              ExpectEqual(b, true);
              ExpectSuccess(IsNiPtr(nif, 'bhkCollisionObject\Target', @b));
              ExpectEqual(b, true);
            end);

          It('Should return false if the reference is a NiRef', procedure
            begin
              ExpectSuccess(IsNiPtr(ref, '', @b));
              ExpectEqual(b, false);
              ExpectSuccess(IsNiPtr(rootBlock, 'Controller', @b));
              ExpectEqual(b, false);
            end);

          It('Should fail if the input isn''t a reference', procedure
            begin
              ExpectFailure(IsNiPtr(nif, '', @len));
              ExpectFailure(IsNiPtr(rootBlock, '', @len));
              ExpectFailure(IsNiPtr(vector, '', @len));
            end);
        end);

      Describe('NifName', procedure
        begin
          It('Should return "NIF" if input is a Nif file', procedure
            begin
              ExpectSuccess(NifName(nif, @len));
              ExpectEqual(grs(len), 'NIF');
            end);

          It('Should resolve block names', procedure
            begin
              ExpectSuccess(NifName(rootBlock, @len));
              ExpectEqual(grs(len), '0 BSFadeNode');
            end);

          It('Should resolve block property names', procedure
            begin
              ExpectSuccess(NifName(transformStruct, @len));
              ExpectEqual(grs(len), 'Transform');
              ExpectSuccess(NifName(float, @len));
              ExpectEqual(grs(len), 'Scale');
              ExpectSuccess(NifName(ref, @len));
              ExpectEqual(grs(len), 'Children #0');
            end);
        end);

      Describe('GetNifBlockType', procedure
        begin
          It('Should return the block type of a nif block', procedure
            begin
              TestGetNifBlockType(rootBlock, '', 'BSFadeNode');
              TestGetNifBlockType(rootBlock, 'Children\@[0]', 'NiNode');
              TestGetNifBlockType(rootBlock, 'Children\@[1]', 'NiTriShape');
              TestGetNifBlockType(rootBlock, 'Children\@[1]\@Shader Property', 'BSLightingShaderProperty');
            end);

          It('Should fail if the handle isn''t a nif block', procedure
            begin
              ExpectFailure(GetNifBlockType(nif, @len));
              ExpectFailure(GetNifBlockType(transformStruct, @len));
            end);
        end);

      Describe('GetNifValue', procedure
        begin
          It('Should resolve element values', procedure
            begin
              ExpectSuccess(GetNifElement(rootBlock, 'Transform\Scale', @h));
              ExpectSuccess(GetNifValue(h, '', @len));
              ExpectEqual(grs(len), '1.000000');
            end);

          It('Should resolve element value at path', procedure
            begin
              ExpectSuccess(GetNifValue(rootBlock, 'Transform\Scale', @len));
              ExpectEqual(grs(len), '1.000000');
              ExpectSuccess(GetNifValue(rootBlock, 'Children\[1]', @len));
              ExpectEqual(grs(len), '17 NiTriShape "WindhelmThrone:0"');
              ExpectSuccess(GetNifValue(rootBlock, 'Children\@[1]\@Data\Num Triangles', @len));
              ExpectEqual(grs(len), '1128');
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(GetNifValue(nif, 'Non\Existent\Path', @len));
            end);
        end);

      Describe('SetNifValue', procedure
        begin
          It('Should set element values', procedure
            begin
              TestSetNifValue(vector, '', '-1.300000 4.300000 29.000000');
              ExpectSuccess(GetNifElement(nif, 'NiTriShape\Transform\Scale', @h));
              TestSetNifValue(h, '', '14.100000');
              ExpectSuccess(GetNifElement(refArray, '[2]', @h));
              TestSetNifValue(h, '', '3 BSTriShape');
            end);

          It('Should set element value at path', procedure
            begin
              TestSetNifValue(rootBlock, 'Name', 'Test Name');
              TestSetNifValue(rootBlock, 'Children\[5]', '28 BSShaderTextureSet');
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(SetNifValue(rootBlock, 'Non\Existent\Path', 'Test'));
            end);
        end);

      Describe('GetNifIntValue', procedure
        begin
          It('Should resolve element integer values', procedure
            begin
              ExpectSuccess(GetNifElement(xt1, 'NiTriShape\Material Data\Material Extra Data\[0]', @h));
              ExpectSuccess(GetNifIntValue(h, '', @i));
              ExpectEqual(i, -12);
            end);

          It('Should resolve element integer values at paths', procedure
            begin
              ExpectSuccess(GetNifIntValue(xt1, 'NiPSysRotationModifier\Rotation Angle', @i));
              ExpectEqual(i, -6);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(GetNifIntValue(nif, 'Non\Existent\Path', @i));
            end);
        end);

      Describe('SetNifIntValue', procedure
        begin
          It('Should set element values', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'bhkCompressedMeshShapeData\Bits Per Index', @h));
              TestSetNifIntValue(h, '', 5);
              ExpectSuccess(GetNifElement(refArray, '[4]', @h));
              TestSetNifIntValue(h, '', 29);
            end);

          It('Should set element value at path', procedure
            begin
              TestSetNifIntValue(nif, 'NiTriShape\Transform\Scale', 2);
              TestSetNifIntValue(rootBlock, 'Children\[5]', 28);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(SetNifIntValue(rootBlock, 'Non\Existent\Path', 1));
            end);
        end);

      Describe('GetNifUIntValue', procedure
        begin
          It('Should resolve element unsigned integer values', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'NiTriShapeData\Num Triangles', @h));
              ExpectSuccess(GetNifUIntValue(h, '', @c));
              ExpectEqual(c, 158);
            end);

          It('Should resolve element unsigned integer values at paths', procedure
            begin
              ExpectSuccess(GetNifUIntValue(nif, 'NiTriShapeData\Num Vertices', @c));
              ExpectEqual(c, 111);
              ExpectSuccess(GetNifUIntValue(nif, 'NiTriShape\Shader Property', @c));
              ExpectEqual(c, 11);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(GetNifUIntValue(nif, 'Non\Existent\Path', @c));
            end);
        end);

      Describe('GetNifFloatValue', procedure
        begin
          It('Should resolve element float values', procedure
            begin
              ExpectSuccess(GetNifFloatValue(float, '', @f));
              ExpectEqual(f, 1.0);
            end);

          It('Should resolve element float values at paths', procedure
            begin
              ExpectSuccess(GetNifFloatValue(nif, 'BSLightingShaderProperty\Glossiness', @f));
              ExpectEqual(f, 80.0);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(GetNifFloatValue(nif, 'Non\Existent\Path', @f));
            end);
        end);

      Describe('SetNifFloatValue', procedure
        begin
          It('Should set element values', procedure
            begin
              TestSetNifFloatValue(float, '', -5.625);
            end);

          It('Should set element value at path', procedure
            begin
              TestSetNifFloatValue(rootBlock, 'Transform\Scale', 1.125);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(SetNifFloatValue(rootBlock, 'Non\Existent\Path', 0.33));
            end);
        end);

      Describe('GetNifVector', procedure
        begin
          It('Should resolve vectors coordinates', procedure
            begin
              ExpectSuccess(GetNifVector(xt1, 'BSFadeNode\Transform\Translation', @len));
              ExpectEqual(grs(len), '{"X":-2,"Y":-2.625,"Z":101}');
              ExpectSuccess(GetNifVector(xt1, 'bhkCompressedMeshShapeData\Bounds Min', @len));
              ExpectEqual(grs(len), '{"X":-42,"Y":31,"Z":1.125,"W":6.625}');
            end);

          It('Should fail if the element isn''t a vector', procedure
            begin
              ExpectFailure(GetNifVector(nif, '', @len));
              ExpectFailure(GetNifVector(nif, 'bhkRigidBody\Rotation', @len));
            end);
        end);

      Describe('SetNifVector', procedure
        begin
          It('Should be able to set vector coordinates', procedure
            begin
              TestSetNifVector(nif, 'BSFadeNode\Transform\Translation', '{"X":2,"Y":1.25,"Z":-1.625}');
              TestSetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Min', '{"X":8.15625,"Y":-25,"Z":-29.78125,"W":1.25}');
            end);

          It('Should support coordinates in any order', procedure
            begin
              ExpectSuccess(SetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Max', '{"W":0.625,"Y":29.1953125,"X":5.625,"Z":7.125}'));
              ExpectSuccess(GetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Max', @len));
              ExpectEqual(grs(len), '{"X":5.625,"Y":29.1953125,"Z":7.125,"W":0.625}');
            end);

          It('Should not require setting all coordinates at the same time', procedure
            begin
              ExpectSuccess(SetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Max', '{"Y":3.125,"W":-25.15625}'));
              ExpectSuccess(GetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Max', @len));
              ExpectEqual(grs(len), '{"X":5.625,"Y":3.125,"Z":7.125,"W":-25.15625}');
            end);

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Min', '{"X":"s","Y":-3.25,"Z":-29.78125,"W":1.25}'));
              ExpectFailure(SetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Min', '{"X":35,"Y":-3.25,"Z":[],"W":1.25}'));
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifVector(nif, 'bhkMoppBvTreeShape\Origin', 'Invalid'));
            end);

          It('Should fail if the element isn''t a vector', procedure
            begin
              ExpectFailure(SetNifVector(nif, '', '{"X": 1.0, "Y": 1.0, "Z": 1.0}'));
              ExpectFailure(SetNifVector(nif, 'bhkRigidBody\Rotation', '{"X": 1.0, "Y": 1.0, "Z": 1.0}'));
              ExpectFailure(SetNifVector(nif, 'BSLightingShaderProperty\UV Offset', '{"X": 1.0, "Y": 1.0, "Z": 1.0}'));
            end);
        end);

      Describe('GetNifTriangle', procedure
        begin
          It('Should resolve triangle vertex indices', procedure
            begin
              ExpectSuccess(GetNifTriangle(nif, 'NiTriShapeData\Triangles\[5]', @len));
              ExpectEqual(grs(len), '{"V1":10,"V2":9,"V3":6}');
              ExpectSuccess(GetNifTriangle(nif, 'NiTriShapeData\Triangles\[11]', @len));
              ExpectEqual(grs(len), '{"V1":12,"V2":16,"V3":17}');
            end);

          It('Should fail if the element isn''t a triangle', procedure
            begin
              ExpectFailure(GetNifVector(nif, '', @len));
              ExpectFailure(GetNifVector(rootBlock, '', @len));
              ExpectFailure(GetNifVector(nif, 'bhkRigidBody\Rotation', @len));
            end);
        end);

      Describe('SetNifTriangle', procedure
        begin
          It('Should be able to set vertex indices', procedure
            begin
              ExpectSuccess(SetNifTriangle(nif, 'NiTriShapeData\Triangles\[0]', '{"V1":21,"V2":2,"V3":13}'));
              ExpectSuccess(GetNifTriangle(nif, 'NiTriShapeData\Triangles\[0]', @len));
              ExpectEqual(grs(len), '{"V1":21,"V2":2,"V3":13}');
            end);

          It('Should support vertex indices in any order', procedure
            begin
              ExpectSuccess(SetNifTriangle(nif, 'NiTriShapeData\Triangles\[1]', '{"V2":19,"V3":2,"V1":13}'));
              ExpectSuccess(GetNifTriangle(nif, 'NiTriShapeData\Triangles\[1]', @len));
              ExpectEqual(grs(len), '{"V1":13,"V2":19,"V3":2}');
            end);

          It('Should not require setting all vertex indices at the same time', procedure
            begin
              ExpectSuccess(SetNifTriangle(nif, 'NiTriShapeData\Triangles\[2]', '{"V2":19}'));
              ExpectSuccess(GetNifTriangle(nif, 'NiTriShapeData\Triangles\[2]', @len));
              ExpectEqual(grs(len), '{"V1":5,"V2":19,"V3":7}');
            end);

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifTriangle(nif, 'NiTriShapeData\Triangles\[3]', '{"V1":"s","V2":19,"V3":7}'));
              ExpectFailure(SetNifTriangle(nif, 'NiTriShapeData\Triangles\[3]', '{"V1":2,"V2":19,"V3":[]}'));
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifTriangle(nif, 'NiTriShapData\Triangles\[4]', 'Invalid'));
            end);

          It('Should fail if the element isn''t a triangle', procedure
            begin
              ExpectFailure(SetNifTriangle(nif, '', '{"V1":1,"V2":1,"V3":1}'));
              ExpectFailure(SetNifTriangle(rootBlock, '', '{"V1":1,"V2":1,"V3":1}'));
              ExpectFailure(SetNifTriangle(nif, 'bhkRigidBody\Rotation', '{"V1":1,"V2":1,"V3":1}'));
            end);
        end);

      Describe('GetNifMatrix', procedure
        begin
          It('Should resolve matrices', procedure
            begin
              ExpectSuccess(GetNifMatrix(xt1, 'NiTexturingProperty\Bump Map Matrix', @len));
              ExpectEqual(grs(len), '[[1,-1],[0,0.625]]');
              ExpectSuccess(GetNifMatrix(xt1, 'NiTextureEffect\Model Projection Matrix', @len));
              ExpectEqual(grs(len), '[[-1,2,3],[4,5,42],[6.625,2,-0.125]]');
              ExpectSuccess(GetNifMatrix(xt1, 'bhkRigidBody\Inertia Tensor', @len));
              ExpectEqual(grs(len), '[[1,0,-1],[1.125,-6.625,42],[-42,5,3.125]]');
              ExpectSuccess(GetNifMatrix(xt1, 'BSFadeNode\Transform\Rotation', @len));
              ExpectEqual(grs(len), '[[9,8,7],[-1,-2,-3.125],[0.125,6,-3]]');
              ExpectSuccess(GetNifMatrix(xt1, 'bhksimpleShapePhantom\Transform', @len));
              ExpectEqual(grs(len), '[[3,4,5,6],[-3,-4,-5,-6],[42,-42,42.125,42.625],[0,-1,0,1]]');
            end);

           It('Should fail if the element isn''t a matrix', procedure
             begin
               ExpectFailure(GetNifMatrix(xt1, '', @len));
               ExpectFailure(GetNifMatrix(xt1, 'BSFadeNode\Transform\Translation', @len));
               ExpectFailure(GetNifMatrix(xt1, 'bhkRigidBody\Rotation', @len));
             end);
        end);

      Describe('SetNifMatrix', procedure
        begin
          It('Should be able to set matrices', procedure
            begin
              TestSetNifMatrix(xt1, 'NiTexturingProperty\Bump Map Matrix',
                '[[-3,-1.125],[0,6.625]]'
              );
              TestSetNifMatrix(xt1, 'NiTextureEffect\Model Projection Matrix',
                '[[1,-1,23],[42,-42,1.125],[42.625,0,3]]'
              );
              TestSetNifMatrix(xt1, 'bhkRigidBody\Inertia Tensor',
                '[[2,-2,5],[8,-3,1],[0,3.625,1.125]]'
              );
              TestSetNifMatrix(xt1, 'BSFadeNode\Transform\Rotation',
                '[[7,5,2],[42,-3.125,2],[1,0,-1]]'
              );              
              TestSetNifMatrix(xt1, 'bhksimpleShapePhantom\Transform',
                '[[1,2,3,4],[5,6.625,7,42],[-3,2,1,6],[23,6,7,1]]'
              );                            
            end);

          It('Should fail if the provided matrix is too small', procedure
            begin
              ExpectFailure(SetNifMatrix(xt1, 'BSFadeNode\Transform\Rotation',
                '[[1,0],[0,1]]'
              ));            
              ExpectFailure(SetNifMatrix(xt1, 'bhksimpleShapePhantom\Transform',
                '[[1,0],[0,1]]'
              ));
              ExpectFailure(SetNifMatrix(xt1, 'bhksimpleShapePhantom\Transform',
                '[[1,0,0],[0,1,0],[0,0,1]]'
              ));              
            end);          

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifMatrix(xt1, 'NiTexturingProperty\Bump Map Matrix',
                '[["string",[]],[null,0]]'
              ));            
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifMatrix(xt1, 'NiTexturingProperty\Bump Map Matrix', 'invalid'));  
              ExpectFailure(SetNifMatrix(xt1, 'NiTexturingProperty\Bump Map Matrix', '{"matrix":[]}'));             
            end);

          It('Should fail if the element isn''t a matrix', procedure
            begin
              ExpectFailure(SetNifMatrix(xt1, '', '[[1,0],[0,1]]'));
              ExpectFailure(SetNifMatrix(xt1, 'BSFadeNode\Transform\Translation', '[[1,0],[0,1]]'));
              ExpectFailure(SetNifMatrix(xt1, 'bhkRigidBody\Rotation', '[[1,0],[0,1]]'));
            end);
        end);        

      Describe('GetNifQuaternion', procedure
        begin
          It('Should resolve quaternion coordinates', procedure
            begin
              ExpectSuccess(GetNifQuaternion(xt1, 'bhkRigidBody\Rotation', @len));
              ExpectEqual(grs(len), '{"X":0,"Y":-23,"Z":-42.625,"W":0.125}');
            end);

          It('Should fail if the element isn''t a quaternion', procedure
            begin
              ExpectFailure(GetNifQuaternion(nif, '', @len));
              ExpectFailure(GetNifQuaternion(rootBlock, '', @len));
            end);
        end);

      Describe('SetNifQuaternion', procedure
        begin
          It('Should be able to set quaternion coordinates', procedure
            begin
              ExpectSuccess(SetNifQuaternion(xt1, 'bhkRigidBody\Rotation', '{"X":-2,"Y":2.125,"Z":-44.625,"W":39}'));
              ExpectSuccess(GetNifQuaternion(xt1, 'bhkRigidBody\Rotation', @len));
              ExpectEqual(grs(len), '{"X":-2,"Y":2.125,"Z":-44.625,"W":39}');
            end);

          It('Should support coordinates in any order', procedure
            begin
              ExpectSuccess(SetNifQuaternion(xt1, 'bhkRigidBody\Rotation', '{"Z":0.625,"Y":1.125,"X":0,"W":-25}'));
              ExpectSuccess(GetNifQuaternion(xt1, 'bhkRigidBody\Rotation', @len));
              ExpectEqual(grs(len), '{"X":0,"Y":1.125,"Z":0.625,"W":-25}');
            end);

          It('Should not require setting all coordinates at the same time', procedure
            begin
              ExpectSuccess(SetNifQuaternion(xt1, 'bhkRigidBody\Rotation', '{"Z":-23.125}'));
              ExpectSuccess(GetNifQuaternion(xt1, 'bhkRigidBody\Rotation', @len));
              ExpectEqual(grs(len), '{"X":0,"Y":1.125,"Z":-23.125,"W":-25}');
            end);

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifQuaternion(xt1, 'bhkRigidBody\Rotation', '{"X":"s","Y":1,"Z":1,"W":1}'));
              ExpectFailure(SetNifQuaternion(xt1, 'bhkRigidBody\Rotation', '{"X":1,"Y":1,"Z":[],"W":1}'));
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifQuaternion(xt1, 'bhkRigidBody\Rotation', 'Invalid'));
            end);

          It('Should fail if the element isn''t a quaternion', procedure
            begin
              ExpectFailure(SetNifQuaternion(nif, '', '{"X":1,"Y":1,"Z":1,"W":1}'));
              ExpectFailure(SetNifQuaternion(rootBlock, '', '{"X":1,"Y":1,"Z":1,"W":1}'));
            end);
        end);

      Describe('GetNifRotation', procedure
        begin
          AfterAll(procedure
            begin
              obj.Free;
            end);

          It('Should resolve rotations as euler YPR when eulerYPR is true', procedure
            begin
              ExpectSuccess(GetNifRotation(xt1, 'BSBlastNode\Transform\Rotation', true, @len));
              TestRotationEquality(grs(len), -115, 6.34, 7.16);
              ExpectSuccess(GetNifRotation(xt1, 'NiKeyframeData\Quaternion Keys\[0]\Value', true, @len));
              TestRotationEquality(grs(len), -45.23, -32.55, -1.12);
            end);

          It('Should resolve rotations as an angle and an axis when eulerYPR is false', procedure
            begin
              ExpectSuccess(GetNifRotation(xt1, 'BSBlastNode\Transform\Rotation', false, @len));
              TestRotationEquality(grs(len), 114.86, -0.99511, 0.09758, -0.01548);
              ExpectSuccess(GetNifRotation(xt1, 'NiKeyframeData\Quaternion Keys\[0]\Value', false, @len));
              TestRotationEquality(grs(len), 54.97, -0.79429, -0.56833, 0.21473);
            end);

          It('Should fail if the element doesn''t represent a rotation', procedure 
            begin
              ExpectFailure(GetNifRotation(nif, '', true, @len));
              ExpectFailure(GetNifRotation(vector, '', true, @len));
              ExpectFailure(GetNifRotation(xt1, 'NiTexturingProperty\Bump Map Matrix', true, @len));
            end);            
        end);

      Describe('GetNifTexCoords', procedure
        begin
          It('Should resolve texture coordinates', procedure
            begin
              ExpectSuccess(GetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', @len));
              ExpectEqual(grs(len), '{"U":53,"V":-42.625}');
            end);

          It('Should fail if the element isn''t texture coordinates', procedure
            begin
              ExpectFailure(GetNifTexCoords(nif, '', @len));
              ExpectFailure(GetNifTexCoords(rootBlock, '', @len));
              ExpectFailure(GetNifTexCoords(nif, 'bhkRigidBody\Rotation', @len));
            end);
        end);

      Describe('SetNifTexCoords', procedure
        begin
          It('Should be able to set texture coordinates', procedure
            begin
              ExpectSuccess(SetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', '{"U":-0.625,"V":1.125}'));
              ExpectSuccess(GetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', @len));
              ExpectEqual(grs(len), '{"U":-0.625,"V":1.125}');
            end);

          It('Should support texture coordinates in any order', procedure
            begin
              ExpectSuccess(SetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', '{"V":1,"U":25}'));
              ExpectSuccess(GetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', @len));
              ExpectEqual(grs(len), '{"U":25,"V":1}');
            end);

          It('Should not require setting both texture coordinates at the same time', procedure
            begin
              ExpectSuccess(SetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', '{"V":-23.125}'));
              ExpectSuccess(GetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', @len));
              ExpectEqual(grs(len), '{"U":25,"V":-23.125}');
            end);

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', '{"U":"s","V":1}'));
              ExpectFailure(SetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', '{"U":1,"V":[]}'));
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifTexCoords(xt1, 'BSLightingShaderProperty\UV Offset', 'Invalid'));
            end);

          It('Should fail if the element isn''t texture coordinates', procedure
            begin
              ExpectFailure(SetNifTexCoords(nif, '', '{"U":1,"V":1}'));
              ExpectFailure(SetNifTexCoords(rootBlock, '', '{"U":1,"V":1}'));
              ExpectFailure(SetNifTexCoords(nif, 'bhkRigidBody\Rotation', '{"U":1,"V":1}'));
            end);
        end);

      Describe('GetNifFlag', procedure
        begin
          It('Should return false for disabled flags', procedure
            begin
              TestGetNifFlag(nif, 'BSXFlags\Flags', 'Animated', false);
              TestGetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Specular', false);
            end);

          It('Should return true for enabled flags', procedure
            begin
              TestGetNifFlag(nif, 'BSXFlags\Flags', 'Havok', true);
              TestGetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Cast_Shadows', true);
            end);

          It('Should fail if the flag is not found', procedure
            begin
              ExpectFailure(GetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'NonExistingFlag', @b));
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(GetNifFlag(nif, '', 'Test', @b));
              ExpectFailure(GetNifFlag(rootBlock, '', 'Enabled', @b));
              ExpectFailure(GetNifFlag(header, 'Endian Type', 'ENDIAN_BIG', @b));
            end);
        end);

      Describe('GetEnabledNifFlags', procedure
        begin
          It('Should return an empty string if no flags are enabled', procedure
            begin
              ExpectSuccess(GetEnabledNifFlags(xt1, 'BSTriShape\VertexDesc\VF', @len));
              ExpectEqual(grs(len), '');
            end);

          It('Should return a comma separated string of flag names', procedure
            begin
              ExpectSuccess(GetEnabledNifFlags(nif, 'BSXFlags\Flags', @len));
              ExpectEqual(grs(len), 'Havok,Articulated');
              ExpectSuccess(GetEnabledNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 2', @len));
              ExpectEqual(grs(len), 'ZBuffer_Write,EnvMap_Light_Fade');
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(GetEnabledNifFlags(nif, '', @len));
              ExpectFailure(GetEnabledNifFlags(rootBlock, '', @len));
              ExpectFailure(GetEnabledNifFlags(header, 'Endian Type', @len));
            end);
        end);


      Describe('SetNifFlag', procedure
        begin
          It('Should be able to enable disabled flags', procedure
            begin
              TestSetNifFlag(nif, 'BSXFlags\Flags', 'Animated', true);
              TestSetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Specular', true);
            end);

          It('Should be able to disable enabled flags', procedure
            begin
              TestSetNifFlag(nif, 'BSXFlags\Flags', 'Havok', false);
              TestSetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Cast_Shadows', false);
            end);

          It('Should fail if the flag doesn''t exist', procedure
            begin
              ExpectFailure(SetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'NonExistingFlag', true));
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(SetNifFlag(nif, '', 'Test', true));
              ExpectFailure(SetNifFlag(rootBlock, '', 'Enabled', true));
              ExpectFailure(SetNifFlag(header, 'Endian Type', 'ENDIAN_BIG', true));
            end);
        end);


      Describe('SetEnabledNifFlags', procedure
        begin
          It('Should enable flags that are present', procedure
            begin
              TestSetEnabledNifFlags(nif, 'BSXFlags\Flags', 'Havok,Articulated,External Emit');
              TestSetEnabledNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Recieve_Shadows,Cast_Shadows,Landscape,Refraction,Own_Emit');
            end);

          It('Should disable flags that are not present', procedure
            begin
              TestSetEnabledNifFlags(nif, 'BSXFlags\Flags', '');
              TestSetEnabledNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Recieve_Shadows,Cast_Shadows');
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(SetEnabledNifFlags(nif, '', @len));
              ExpectFailure(SetEnabledNifFlags(rootBlock, '', @len));
              ExpectFailure(SetEnabledNifFlags(header, 'Endian Type', @len));
            end);
        end);

      Describe('GetAllNifFlags', procedure
        begin
          It('Should return a comma separated list of all flag names', procedure
            begin
              ExpectSuccess(GetAllNifFlags(nif, 'BSXFlags\Flags', @len));
              str := grs(len);
              Expect(Pos('Animated', str) = 1, 'Animated should be the first flag');
              Expect(Pos('Ragdoll', str) > 0, 'Ragdoll should be included');
              Expect(Pos('Editor Marker', str) > 0, 'Editor Marker should be included');
              Expect(Pos('Articulated', str) > 0, 'Articulated should be included');

              ExpectSuccess(GetAllNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 1', @len));
              str := grs(len);
              Expect(Pos('Specular', str) = 1, 'Specular should be the first flag');
              Expect(Pos('Use_Falloff', str) > 0, 'Use_Falloff should be included');
              Expect(Pos('Parallax', str) > 0, 'Parallax should be included');
              Expect(Pos('Soft_Effect', str) > 0, 'Soft_Effect should be included');
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(GetAllNifFlags(nif, '', @len));
              ExpectFailure(GetAllNifFlags(rootBlock, '', @len));
              ExpectFailure(GetAllNifFlags(header, 'Endian Type', @len));
            end);
        end);

      Describe('GetNifEnumOptions', procedure
        begin
          It('Should return a comma seperated list of enum options', procedure
            begin
              TestGetNifEnumOptions(header, 'Endian Type', 'ENDIAN_BIG,ENDIAN_LITTLE');
              TestGetNifEnumOptions(nif, 'bhkRigidBody\Broad Phase Type', 'BROAD_PHASE_INVALID,BROAD_PHASE_ENTITY,BROAD_PHASE_PHANTOM,BROAD_PHASE_BORDER');
              TestGetNifEnumOptions(nif, 'BSLightingShaderProperty\Texture Clamp Mode', 'CLAMP_S_CLAMP_T,CLAMP_S_WRAP_T,WRAP_S_CLAMP_T,WRAP_S_WRAP_T');
            end);

          It('Should fail if the element isn''t an enum', procedure
            begin
              ExpectFailure(GetNifEnumOptions(nif, '', @len));
              ExpectFailure(GetNifEnumOptions(rootBlock, '', @len));
              ExpectFailure(GetNifEnumOptions(nif, 'NiTriShape\Flags', @len));
            end);
        end);

      Describe('IsNifHeader', procedure
        begin
          It('Should return true if the element is a nif header', procedure
            begin
              ExpectSuccess(IsNifHeader(header, @b));
              ExpectEqual(b, true);
            end);

          It('Should return false if the element isn''t a nif header', procedure
            begin
              ExpectSuccess(IsNifHeader(nif, @b));
              ExpectEqual(b, false);
              ExpectSuccess(IsNifHeader(rootBlock, @b));
              ExpectEqual(b, false);
              ExpectSuccess(IsNifHeader(vector, @b));
              ExpectEqual(b, false);
            end);
        end);

      Describe('IsNifFooter', procedure
        begin
          It('Should return true if the element is a nif footer', procedure
            begin
              ExpectSuccess(IsNifFooter(footer, @b));
              ExpectEqual(b, true);
            end);

          It('Should return false if the element isn''t a nif footer', procedure
            begin
              ExpectSuccess(IsNifFooter(nif, @b));
              ExpectEqual(b, false);
              ExpectSuccess(IsNifFooter(rootBlock, @b));
              ExpectEqual(b, false);
              ExpectSuccess(IsNifFooter(vector, @b));
              ExpectEqual(b, false);
            end);
        end);

      Describe('NifElementToJson', procedure
        begin
          Describe('File serialization', procedure
          begin
            AfterAll(procedure
              begin
                obj.Free;
              end);

              It('Should succeed', procedure
                begin
                  ExpectSuccess(NifElementToJson(nif, '', @len));
                  obj := TJSONObject.Create(grs(len));
                end, True);

              It('Should have the expected number of blocks', procedure
              begin
                ExpectEqual(obj.Count, 39);
              end);

              Describe('NiHeader', procedure
                begin
                  It('Should be present', procedure
                    begin
                      ExpectExists(obj, 'NiHeader');
                      obj2 := obj.O['NiHeader'];
                    end, true);

                  It('Should have the correct version', procedure
                    begin
                      ExpectEqual(obj2.S['Magic'], 'Gamebryo File Format, Version 20.2.0.7');
                    end);

                  It('Should have the expected number of blocks (which excludes header and footer)', procedure
                    begin
                      ExpectEqual(obj2.I['Num Blocks'], 37);
                    end);                    

                  It('Should have the expected block types', procedure
                    const
                      ExpectedBlockTypes: array[0..12] of string = (
                        'BSFadeNode',
                        'BSFurnitureMarkerNode',
                        'BSXFlags',
                        'bhkCompressedMeshShapeData',
                        'bhkCompressedMeshShape',
                        'bhkMoppBvTreeShape',
                        'bhkRigidBody',
                        'bhkCollisionObject',
                        'NiNode',
                        'NiTriShape',
                        'NiTriShapeData',
                        'BSLightingShaderProperty',
                        'BSShaderTextureSet'
                      );
                    var
                      i: Integer;
                    begin
                      for i := Low(ExpectedBlockTypes) to High(ExpectedBlockTypes) do
                        ExpectEqual(obj2.A['Block Types'].S[i], ExpectedBlockTypes[i]);
                    end);                    
                end);

              It('Should have a NiFooter', procedure
                begin
                  ExpectExists(obj, 'NiFooter');
                end);             
          end);

          It('Should serialize blocks as objects with each element as a property', procedure
          begin
            ExpectSuccess(NifElementToJson(xt1, 'BSXFlags', @len));
            ExpectEqual(grs(len), '{"1 BSXFlags":{"Name":"BSX","Flags":"Complex | Dynamic | Articulated"}}');                
          end);

          Describe('Element serialization', procedure
          begin
            It('Should serialize integers as their native value', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'Header\User Version', @len));
                ExpectEqual(grs(len), '{"User Version":12}');              
              end);

            It('Should serialize floats as their native value', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'BSFadeNode\Transform\Scale', @len));
                ExpectEqual(grs(len), '{"Scale":20}');
              end);

            It('Should serialize integers and floats with FOnGetTexts as their edit value', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'Header\Version', @len));
                ExpectEqual(grs(len), '{"Version":"20.2.0.7"}');
                ExpectSuccess(NifElementToJson(xt1, 'BSFadeNode\Children\[0]', @len));
                ExpectEqual(grs(len), '{"Children #0":"2 BSTriShape \"Blocky McBlockFace\""}');                     
              end);

            It('Should serialize flags as |-seperated strings', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'BSLightingShaderProperty\Shader Flags 1', @len));
                ExpectEqual(grs(len), '{"Shader Flags 1":"Specular | Recieve_Shadows | Cast_Shadows | Own_Emit | Remappable_Textures | ZBuffer_Test"}');                  
              end);

            It('Should serialize enums as strings', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'Header\Endian Type', @len));
                ExpectEqual(grs(len), '{"Endian Type":"ENDIAN_LITTLE"}');                   
              end);      

            It('Should serialize value unions as strings', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'bhkPlaneShape\Material', @len));
                ExpectEqual(grs(len), '{"Material":"SKY_HAV_MAT_STONE"}');                  
              end);                                                             

            It('Should serialize chars as strings', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'Header\Magic', @len));
                ExpectEqual(grs(len), '{"Magic":"Gamebryo File Format, Version 20.2.0.7"}');
              end);

            It('Should serialize byte arrays as strings', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'bhkRigidBody\Unknown Bytes 1', @len));
                ExpectEqual(grs(len), '{"Unknown Bytes 1":"FF 22 00 42 00 45 03 2A 00 37 00 01"}');
              end);          

            It('Should serialize the active element of a union', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'BSXFlags\Flags', @len));  
                ExpectEqual(grs(len), '{"Flags":"Complex | Dynamic | Articulated"}');                    
              end);                            

            It('Should serialize merges as objects with each virtual child element as a property', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'BSTriShape\Transform\Translation', @len));  
                ExpectEqual(grs(len), '{"Translation":{"X":1.125,"Y":-5,"Z":200}}');
                ExpectSuccess(NifElementToJson(xt1, 'BSLightingShaderProperty\UV Scale', @len));  
                ExpectEqual(grs(len), '{"UV Scale":{"U":-23,"V":42}}');                        
              end);      

            It('Should serialize structs as objects with each child element as a property', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'Header\Export Info', @len));
                ExpectEqual(grs(len), '{"Export Info":{"Author":"Shybert","Process Script":"No","Export Script":"Yes"}}');
              end);                                      

            It('Should serialize arrays properly', procedure
              begin
                ExpectSuccess(NifElementToJson(xt1, 'BSShaderTextureSet\Textures', @len));
                ExpectEqual(grs(len), '{"Textures":["textures.exe","galore.jpg","3.png","4.png","5.png","6.png"]}');                
              end);         
          end);
        end);             
  end);
end;
end.

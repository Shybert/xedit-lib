unit txNifs;

interface

uses
  SysUtils;

  // PUBLIC TESTING INTERFACE
  procedure BuildFileHandlingTests;
implementation

uses
  Mahogany,
  txMeta,
{$IFDEF USE_DLL}
  txImports;
{$ENDIF}
{$IFNDEF USE_DLL}
  xeConfiguration, xeNifs, xeMeta;
{$ENDIF}

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

procedure TestAddNifBlock(h: Cardinal; blockType: PWideChar);
var
  element: Cardinal;
  exists: WordBool;
begin
  ExpectSuccess(AddNifBlock(h, blockType, @element));
  ExpectSuccess(HasNifElement(h, blockType, @exists));
  Expect(exists, 'The block should be present');
  Expect(element > 0, 'Handle should be greater than 0');
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

procedure DeleteNifs(filePaths: TStringArray);
var
  i: Integer;
begin
  for i := Low(filePaths) to High(filePaths) do
    DeleteFile(filePaths[i]);
end;

procedure BuildFileHandlingTests;
var
  b: WordBool;
  h, h2, nif, header, footer, rootNode, childrenArray, ref, transformStruct, vector, float, xt2, xt3, c: Cardinal;
  len, i: Integer;
  f: Double;
  str: String;
begin
  Describe('Nif File Handling Functions', procedure
    begin
      BeforeAll(procedure
        begin
          ExpectSuccess(LoadNif(PWideChar(GetDataPath + 'xtest-1.nif'), @nif));
          ExpectSuccess(GetNifElement(nif, 'Header', @header));
          ExpectSuccess(GetNifElement(nif, 'Footer', @footer));
          ExpectSuccess(GetNifElement(nif, 'BSFadeNode', @rootNode));
          ExpectSuccess(GetNifElement(rootNode, 'Children', @childrenArray));
          ExpectSuccess(GetNifElement(childrenArray, '[0]', @ref));
          ExpectSuccess(GetNifElement(rootNode, 'Transform', @transformStruct));
          ExpectSuccess(GetNifElement(transformStruct, 'Translation', @vector));
          ExpectSuccess(GetNifElement(transformStruct, 'Scale', @float));
          ExpectSuccess(LoadNif(PWideChar('xtest-2.nif'), @xt2));
          ExpectSuccess(LoadNif(PWideChar('xtest-3.nif'), @xt3));
        end);

      Describe('LoadNif', procedure
        begin
          It('Should load nifs from absolute paths', procedure
            begin
              TestLoadNif(GetDataPath + 'xtest-1.nif');
            end);

          It('Should load nifs from relative paths', procedure
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
              ExpectFailure(FreeNif(rootNode));
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
              DeleteNifs([GetDataPath + 'test.nif', GetDataPath + 'meshes\test.nif', GetDataPath + 'meshes\test\test.nif']);
            end);

          It('Should save Nifs at absolute paths', procedure
            begin
              ExpectSuccess(SaveNif(nif, PWideChar(GetDataPath + 'test.nif')));
              ExpectSuccess(FileExists(GetDataPath + 'test.nif'));
            end);

          It('Should save Nifs at relative paths', procedure
            begin
              ExpectSuccess(SaveNif(nif, 'meshes\test.nif'));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test.nif'));
            end);

          It('Should save Nifs at relative paths starting with data\', procedure
            begin
              ExpectSuccess(SaveNif(nif, 'data\meshes\test\test.nif'));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test\test.nif'));
            end);

          It('Should fail if interface is not a file', procedure
            begin
              ExpectFailure(SaveNif(rootNode, ''));
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
              DeleteNifs([GetDataPath + 'test.nif', GetDataPath + 'meshes\test.nif', GetDataPath + 'meshes\test\test.nif']);
            end);

          It('Should return true for an absolute path', procedure
            begin
              ExpectSuccess(CreateNif(PWideChar(GetDataPath + 'test.nif'), false, @h));
              ExpectSuccess(FileExists(GetDataPath + 'test.nif'));
            end);

          It('Should return true for a relative path', procedure
            begin
              ExpectSuccess(CreateNif('meshes\test.nif', false, @h));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test.nif'));
            end);

          It('Should return true for a relative path starting with data\', procedure
            begin
              ExpectSuccess(CreateNif('data\meshes\test\test.nif', false, @h));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test\test.nif'));
            end);

          It('Should return false if the file exists and ignoreExists is false', procedure
            begin
              ExpectFailure(CreateNif(PWideChar(GetDataPath + 'test.nif'), false, @h));
            end);

          It('Should return true if the file exists and ignoreExists is true', procedure
            begin
              ExpectSuccess(CreateNif(PWideChar(GetDataPath + 'test.nif'), true, @h));
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
              TestHasNifElement(rootNode, 'Name');
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
              TestHasNifElement(rootNode, 'NonExistingElement', false);
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
                  TestGetNifElement(rootNode, '[0]');

                  ExpectSuccess(GetNifElement(rootNode, 'Children', @h));
                  TestGetNifElement(h, '[1]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectFailure(GetNifElement(rootNode, '[-9]', @h));

                  ExpectSuccess(GetNifElement(rootNode, 'Children', @h));
                  ExpectFailure(GetNifElement(h, '[20]', @h));
                end);
            end);

          Describe('Block property resolution by name', procedure
            begin
              It('Should return a handle if a matching element exists', procedure
                begin
                  TestGetNifElement(rootNode, 'Name');
                end);

              It('Should fail if a matching element does not exist', procedure
                begin
                  ExpectFailure(GetNifElement(rootNode, 'NonExistingElement', @h));
                end);
            end);

          Describe('Reference resolution', procedure
            begin
              It('Should return a handle if the property exists and has a reference', procedure
                begin
                  TestGetNifElement(rootNode, 'Children\@[0]');
                  TestGetNifElement(rootNode, 'Extra Data List\@[0]');
                  TestGetNifElement(rootNode, '@Collision Object');
                end);

              It('Should fail if the property exists, but does not have a reference', procedure
                begin
                  ExpectSuccess(GetNifElement(nif, 'BSTriShape', @h));
                  ExpectFailure(GetNifElement(h, '@Controller', @h));
                end);

              It('Should fail if the property does not exist', procedure
                begin
                  ExpectSuccess(GetNifElement(nif, 'BSTriShape', @h));
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
                      ExpectSuccess(GetNifElement(nif, 'BSTriShape\Controller', @h));
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

        Describe('AddNifBlock', procedure
          begin
            It('Should be able to add a block to a nif file', procedure
              begin
                TestAddNifBlock(xt2, 'NiTriShape');
              end);

            It('Should add the first added NiNode type block as a root', procedure
              begin
                ExpectSuccess(GetNifElement(xt3, 'Roots', @h));
                TestNifElementCount(h, 0);
                TestAddNifBlock(xt3, 'BSTriShape');
                TestNifElementCount(h, 0);
                TestAddNifBlock(xt3, 'BSFadeNode');
                TestNifElementCount(h, 1);
                TestAddNifBlock(xt3, 'BSFadeNode');
                TestNifElementCount(h, 1);
              end);

            It('Should fail if the block type is invalid', procedure
              begin
                ExpectFailure(AddNifBlock(xt3, 'NonExistingBlockType', @h));
              end);

            It('Should fail if the handle isn''t a nif file', procedure
              begin
                ExpectFailure(AddNifBlock(rootNode, 'BSFadeNode', @h));
              end);
          end);

        Describe('RemoveNifBlock', procedure
          begin
            BeforeAll(procedure
              begin
                ExpectSuccess(LoadNif('xtest-1.nif', @h));
              end);

            It('Should be able to remove blocks', procedure
              begin
                TestRemoveNifBlock(h, 'BSXFlags');
              end);

            It('Should clear links referencing the removed block', procedure
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

            It('Should remap blocks', procedure
              begin
                TestGetNifElementIndex(h, 'BSFurnitureMarkerNode', 1); // Same as before, only blocks after this block have been removed
                TestGetNifElementIndex(h, 'BSTriShape', 6); // Used to be 9, 3 prior blocks have been removed
              end);

            Describe('Recursion', procedure
              begin
                It('Should recursively remove all NiRef type linked blocks in the removed block', procedure
                  begin
                    TestNifElementCount(h, 29);
                    TestRemoveNifBlock(h, 'NiNode', True);
                    TestNifElementCount(h, 22);
                  end);

                It('Should not remove NiPtr type linked blocks in the removed block', procedure
                  begin
                    TestRemoveNifBlock(h, 'bhkCollisionObject', True);
                    TestNifElementCount(h, 20);
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

      Describe('GetNifBlocks', procedure
        begin
          Describe('No search', procedure
            begin
              It('Should return all blocks in a Nif file', procedure
                begin
                  TestGetNifBlocks(nif, '', '', 30);
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
                  TestGetNifBlocks(nif, '', 'BSTriShape', 7);
                end);
              It('Should return all referenced blocks of a given block type in a Nif block', procedure
                begin
                  TestGetNifBlocks(nif, 'BSFadeNode', 'BSTriShape', 5);
                  TestGetNifBlocks(nif, 'BSFurnitureMarkerNode', 'BSTriShape', 0);
                end);
            end);

          It('Should fail if interface is neither a nif file nor a nif block', procedure
            begin
              ExpectFailure(GetNifBlocks(float, '', @len));
              ExpectFailure(GetNifBlocks(ref, '', @len));
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
              ExpectSuccess(GetNifLinksTo(rootNode, 'Controller', @h));
              ExpectEqual(h, 0);
              ExpectSuccess(SetNifIntValue(rootNode, 'Controller', 99));
              ExpectSuccess(GetNifLinksTo(rootNode, 'Controller', @h2));
              ExpectEqual(h2, 0);
            end);

          It('Should fail if path is invalid', procedure
            begin
              ExpectFailure(GetNifLinksTo(childrenArray, '[-2]', @h));
            end);

          It('Should fail on elements that cannot hold a reference', procedure
            begin
              ExpectFailure(GetNifLinksTo(nif, '', @h));
              ExpectFailure(GetNifLinksTo(rootNode, '', @h));
              ExpectFailure(GetNifLinksTo(vector, '', @h));
            end);
        end);

      Describe('SetNifLinksTo', procedure
        begin
          It('Should set references', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'NiNode', @h));
              ExpectSuccess(SetNifLinksTo(childrenArray, '[-1]', h));
              TestGetNifLinksTo(childrenArray, '[-1]', h);
            end);

          It('Should fail if the first element cannot hold a reference', procedure
            begin
              ExpectFailure(SetNifLinksTo(nif, '', h));
              ExpectFailure(SetNifLinksTo(rootNode, '', h));
              ExpectFailure(SetNifLinksTo(vector, '', h));
            end);

          It('Should fail if the first element cannot hold a reference to the second element''s block type', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'BSTriShape', @h));
              ExpectFailure(SetNifLinksTo(rootNode, 'Controller', h));
            end);

          It('Should fail if the second element isn''t a block', procedure
            begin
              ExpectFailure(SetNifLinksTo(childrenArray, '[0]', vector));
            end);
        end);

      Describe('ElementCount', procedure
        begin
          It('Should return the number of blocks in a Nif file', procedure
            begin
              TestNifElementCount(nif, 32);
            end);

          It('Should return the number of elements in a block', procedure
            begin
              TestNifElementCount(rootNode, 13);
            end);

          It('Should return the number of elements in a struct', procedure
            begin
              ExpectSuccess(GetNifElement(header, 'Export Info', @h));
              TestNifElementCount(h, 4);
            end);

          It('Should return the number of elements in an array', procedure
            begin
              ExpectSuccess(GetNifElement(rootNode, 'Children', @h));
              TestNifElementCount(h, 6);
            end);

          It('Should return 0 if there are no children', procedure
            begin
              ExpectSuccess(GetNifElement(rootNode, 'Name', @h));
              TestNifElementCount(h, 0);
            end);
        end);

      Describe('NifElementEquals', procedure
        begin
          It('Should return true for equal elements', procedure
            begin
              TestNifElementEquals(rootNode, nif, '[0]');
              TestNifElementEquals(transformStruct, rootNode, 'Transform');
              TestNifElementEquals(childrenArray, rootNode, 'Children');
              TestNifElementEquals(ref, childrenArray, '[0]');
              TestNifElementEquals(vector, transformStruct, 'Translation');
              TestNifElementEquals(float, transformStruct, 'Scale');
            end);

          It('Should return false for different elements holding the same value', procedure
            begin
              TestNifElementEquals(vector, nif, 'BSTriShape\Transform\Translation', False);
            end);

          It('Should return false for different elements', procedure
            begin
              TestNifElementEquals(rootNode, transformStruct, False);
              TestNifElementEquals(transformStruct, childrenArray, False);
              TestNifElementEquals(childrenArray, ref, False);
              TestNifElementEquals(ref, vector, False);
              TestNifElementEquals(vector, float, False);
            end);

          It('Should fail if the handles are unassigned', procedure
            begin
              ExpectFailure(NifElementEquals($FFFFFF, 999999, @b));
            end);
        end);

      Describe('GetNifElementIndex', procedure
        begin
          It('Should return the index of blocks', procedure
            begin
              TestGetNifElementIndex(rootNode, '', 0);
              TestGetNifElementIndex(nif, 'BSTriShape', 9);
            end);

          It('Should return the index of block elements', procedure
            begin
              TestGetNifElementIndex(transformStruct, '', 5);
              TestGetNifElementIndex(childrenArray, '', 11);
            end);

          It('Should return the index of elements in a struct', procedure
            begin
              TestGetNifElementIndex(header, 'Export Info\Export Script', 3);
              TestGetNifElementIndex(transformStruct, 'Rotation', 1);
            end);

          It('Should return the index of elements in arrays', procedure
            begin
              TestGetNifElementIndex(childrenArray, '[2]', 2);
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
              TestGetNifElementFile(rootNode, nif);
            end);

          It('Should return the file containing a nif element', procedure
            begin
              TestGetNifElementFile(transformStruct, nif);
              TestGetNifElementFile(childrenArray, nif);
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
              TestGetNifElementBlock(rootNode, rootNode);
            end);

          It('Should return the block containing a nif element', procedure
            begin
              TestGetNifElementBlock(transformStruct, rootNode);
              TestGetNifElementBlock(vector, rootNode);
              TestGetNifElementBlock(ref, rootNode);
            end);
        end);

      Describe('GetNifTemplate', procedure
        begin
          It('Should resolve the template of references', procedure
            begin
              ExpectSuccess(GetNifTemplate(ref, '', @len));
              ExpectEqual(grs(len), 'NiAVObject');
              ExpectSuccess(GetNifTemplate(rootNode, 'Controller', @len));
              ExpectEqual(grs(len), 'NiTimeController');
            end);

          It('Should fail if the input isn''t a reference', procedure
            begin
              ExpectFailure(GetNifTemplate(nif, '', @len));
              ExpectFailure(GetNifTemplate(rootNode, '', @len));
              ExpectFailure(GetNifTemplate(vector, '', @len));
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
              ExpectSuccess(IsNiPtr(rootNode, 'Controller', @b));
              ExpectEqual(b, false);
            end);

          It('Should fail if the input isn''t a reference', procedure
            begin
              ExpectFailure(IsNiPtr(nif, '', @len));
              ExpectFailure(IsNiPtr(rootNode, '', @len));
              ExpectFailure(IsNiPtr(vector, '', @len));
            end);
        end);

      Describe('GetNifName', procedure
        begin
          It('Should return true if file handle is valid', procedure
            begin
              ExpectSuccess(GetNifName(nif, @len));
              ExpectEqual(grs(len), 'NIF');
            end);

        end);

      Describe('GetNifBlockType', procedure
        begin
          It('Should return the block type of a nif block', procedure
            begin
              TestGetNifBlockType(rootNode, '', 'BSFadeNode');
              TestGetNifBlockType(rootNode, 'Children\@[0]', 'NiNode');
              TestGetNifBlockType(rootNode, 'Children\@[1]', 'BSTriShape');
              TestGetNifBlockType(rootNode, 'Children\@[1]\@Shader Property', 'BSLightingShaderProperty');
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
              ExpectSuccess(GetNifElement(rootNode, 'Transform\Scale', @h));
              ExpectSuccess(GetNifValue(h, '', @len));
              ExpectEqual(grs(len), '1.000000');
            end);

          It('Should resolve element value at path', procedure
            begin
              ExpectSuccess(GetNifValue(rootNode, 'Transform\Scale', @len));
              ExpectEqual(grs(len), '1.000000');
              ExpectSuccess(GetNifValue(rootNode, 'Children\[1]', @len));
              ExpectEqual(grs(len), '15 BSTriShape "WindhelmThrone:0"');
              ExpectSuccess(GetNifValue(rootNode, 'Children\@[1]\Num Triangles', @len));
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
              ExpectSuccess(GetNifElement(nif, 'BSTriShape\Transform\Scale', @h));
              TestSetNifValue(h, '', '14.100000');
              ExpectSuccess(GetNifElement(childrenArray, '[4]', @h));
              TestSetNifValue(h, '', '28 BSLightingShaderProperty');
            end);

          It('Should set element value at path', procedure
            begin
              TestSetNifValue(rootNode, 'Name', 'Test Name');
              TestSetNifValue(rootNode, 'Children\[5]', '29 BSShaderTextureSet');
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(SetNifValue(rootNode, 'Non\Existent\Path', 'Test'));
            end);
        end);

      Describe('GetNifIntValue', procedure
        begin
          It('Should resolve element integer values', procedure
            begin
              ExpectSuccess(GetNifElement(rootNode, 'Children\@[1]\Vertex Data\[1]\Bitangent X', @h));
              ExpectSuccess(GetNifIntValue(h, '', @i));
              ExpectEqual(i, -1);
            end);

          It('Should resolve element integer values at paths', procedure
            begin
              ExpectSuccess(LoadNif('meshes\mps\mpsfireboltfire01.nif', @h));
              ExpectSuccess(GetNifIntValue(h, 'NiPSysRotationModifier\Rotation Angle', @i));
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
              ExpectSuccess(GetNifElement(childrenArray, '[4]', @h));
              TestSetNifIntValue(h, '', 29);
            end);

          It('Should set element value at path', procedure
            begin
              TestSetNifIntValue(nif, 'BSTriShape\Transform\Scale', 2);
              TestSetNifIntValue(rootNode, 'Children\[5]', 28);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(SetNifIntValue(rootNode, 'Non\Existent\Path', 1));
            end);
        end);

      Describe('GetNifUIntValue', procedure
        begin
          It('Should resolve element unsigned integer values', procedure
            begin
              ExpectSuccess(GetNifElement(nif, 'BSTriShape\Num Triangles', @h));
              ExpectSuccess(GetNifUIntValue(h, '', @c));
              ExpectEqual(c, 158);
            end);

          It('Should resolve element unsigned integer values at paths', procedure
            begin
              ExpectSuccess(GetNifUIntValue(nif, 'BSTriShape\Num Vertices', @c));
              ExpectEqual(c, 111);
              ExpectSuccess(GetNifUIntValue(nif, 'BSTriShape\Shader Property', @c));
              ExpectEqual(c, 10);
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
              TestSetNifFloatValue(rootNode, 'Transform\Scale', 1.125);
            end);

          It('Should fail if path does not exist', procedure
            begin
              ExpectFailure(SetNifFloatValue(rootNode, 'Non\Existent\Path', 0.33));
            end);
        end);

      Describe('GetNifVector', procedure
        begin
          It('Should resolve vectors coordinates', procedure
            begin
              ExpectSuccess(GetNifVector(nif, 'bhkMoppBvTreeShape\Origin', @len));
              ExpectEqual(grs(len), '{"X":-2.16699957847595,"Y":-1.70599961280823,"Z":-0.949999749660492}');
              ExpectSuccess(GetNifVector(nif, 'BSTriShape\Vertex Data\[0]\Normal', @len));
              ExpectEqual(grs(len), '{"X":127,"Y":127,"Z":0}');
              ExpectSuccess(GetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Min', @len));
              ExpectEqual(grs(len), '{"X":-2.16199970245361,"Y":-1.70099973678589,"Z":-0.944999814033508,"W":0}');
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
              TestSetNifVector(nif, 'bhkMoppBvTreeShape\Origin', '{"X":2,"Y":1.25,"Z":-1.625}');
              TestSetNifVector(nif, 'BSTriShape\Vertex Data\[0]\Normal', '{"X":0,"Y":255,"Z":192}');
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
              ExpectFailure(SetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Min', '{"X":True,"Y":-3.25,"Z":-29.78125,"W":1.25}'));
              ExpectFailure(SetNifVector(nif, 'bhkCompressedMeshShapeData\Bounds Min', '{"X":[],"Y":-3.25,"Z":-29.78125,"W":1.25}'));
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
              ExpectSuccess(GetNifTriangle(nif, 'BSTriShape\Triangles\[5]', @len));
              ExpectEqual(grs(len), '{"V1":10,"V2":9,"V3":6}');
              ExpectSuccess(GetNifTriangle(nif, 'BSTriShape\Triangles\[11]', @len));
              ExpectEqual(grs(len), '{"V1":12,"V2":16,"V3":17}');
            end);

          It('Should fail if the element isn''t a triangle', procedure
            begin
              ExpectFailure(GetNifVector(nif, '', @len));
              ExpectFailure(GetNifVector(rootNode, '', @len));
              ExpectFailure(GetNifVector(nif, 'bhkRigidBody\Rotation', @len));
            end);
        end);

      Describe('SetNifTriangle', procedure
        begin
          It('Should be able to set vertex indices', procedure
            begin
              ExpectSuccess(SetNifTriangle(nif, 'BSTriShape\Triangles\[0]', '{"V1":21,"V2":2,"V3":13}'));
              ExpectSuccess(GetNifTriangle(nif, 'BSTriShape\Triangles\[0]', @len));
              ExpectEqual(grs(len), '{"V1":21,"V2":2,"V3":13}');
            end);

          It('Should support vertex indices in any order', procedure
            begin
              ExpectSuccess(SetNifTriangle(nif, 'BSTriShape\Triangles\[1]', '{"V2":19,"V3":2,"V1":13}'));
              ExpectSuccess(GetNifTriangle(nif, 'BSTriShape\Triangles\[1]', @len));
              ExpectEqual(grs(len), '{"V1":13,"V2":19,"V3":2}');
            end);

          It('Should not require setting all vertex indices at the same time', procedure
            begin
              ExpectSuccess(SetNifTriangle(nif, 'BSTriShape\Triangles\[2]', '{"V2":19}'));
              ExpectSuccess(GetNifTriangle(nif, 'BSTriShape\Triangles\[2]', @len));
              ExpectEqual(grs(len), '{"V1":5,"V2":19,"V3":7}');
            end);

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifTriangle(nif, 'BSTriShape\Triangles\[3]', '{"V1":true,"V2":19,"V3":7}'));
              ExpectFailure(SetNifTriangle(nif, 'BSTriShape\Triangles\[3]', '{"V1":[],"V2":19,"V3":7}'));
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifTriangle(nif, 'BSTriShape\Triangles\[4]', 'Invalid'));
            end);

          It('Should fail if the element isn''t a triangle', procedure
            begin
              ExpectFailure(SetNifTriangle(nif, '', '{"V1":1,"V2":1,"V3":1}'));
              ExpectFailure(SetNifTriangle(rootNode, '', '{"V1":1,"V2":1,"V3":1}'));
              ExpectFailure(SetNifTriangle(nif, 'bhkRigidBody\Rotation', '{"V1":1,"V2":1,"V3":1}'));
            end);
        end);

      Describe('GetNifQuaternion', procedure
        begin
          BeforeAll(procedure
            begin
              ExpectSuccess(LoadNif('meshes\animobjects\animobjectbucket.nif', @h));
            end);

          It('Should resolve quaternions as an Euler rotation when eulerRotation is true', procedure
            begin
              ExpectSuccess(GetNifQuaternion(h, 'bhkRigidBody\Rotation', true, @len));
              ExpectEqual(grs(len), '{"Y":94.636955,"P":29.171878,"R":-127.683766}');
            end);

          It('Should resolve quaternions as an angle and axis when eulerRotation is false', procedure
            begin
              ExpectSuccess(GetNifQuaternion(h, 'bhkRigidBody\Rotation', false, @len));
              ExpectEqual(grs(len), '{"A":125.818765,"X":0.180168,"Y":0.801807,"Z":-0.569776}');
            end);

          It('Should fail if the element isn''t a quaternion', procedure
            begin
              ExpectFailure(GetNifQuaternion(nif, '', true, @len));
              ExpectFailure(GetNifQuaternion(nif, 'bhkMoppBvTreeShape\Origin', true, @len));
              ExpectFailure(GetNifQuaternion(nif, 'BSLightingShaderProperty\UV Offset', true, @len));
            end);
        end);

      Describe('GetNativeNifQuaternion', procedure
        begin
          BeforeAll(procedure
            begin
              ExpectSuccess(LoadNif('meshes\animobjects\animobjectbucket.nif', @h));
            end);

          It('Should resolve quaternion coordinates', procedure
            begin
              ExpectSuccess(GetNativeNifQuaternion(h, 'bhkRigidBody\Rotation', @len));
              ExpectEqual(grs(len), '{"X":0.160401180386543,"Y":0.713838517665863,"Z":-0.507264733314514,"W":0.455399125814438}');
            end);

          It('Should fail if the element isn''t a quaternion', procedure
            begin
              ExpectFailure(GetNativeNifQuaternion(nif, '', @len));
              ExpectFailure(GetNativeNifQuaternion(rootNode, '', @len));
            end);
        end);

      Describe('GetNifTexCoords', procedure
        begin
          It('Should resolve texture coordinates', procedure
            begin
              ExpectSuccess(GetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', @len));
              ExpectEqual(grs(len), '{"U":0.5,"V":0.5029296875}');
              ExpectSuccess(GetNifTexCoords(nif, 'BSLightingShaderProperty\UV Scale', @len));
              ExpectEqual(grs(len), '{"U":1,"V":1}');
            end);

          It('Should fail if the element isn''t texture coordinates', procedure
            begin
              ExpectFailure(GetNifTexCoords(nif, '', @len));
              ExpectFailure(GetNifTexCoords(rootNode, '', @len));
              ExpectFailure(GetNifTexCoords(nif, 'bhkRigidBody\Rotation', @len));
            end);
        end);

      Describe('SetNifTexCoords', procedure
        begin
          It('Should be able to set texture coordinates', procedure
            begin
              ExpectSuccess(SetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', '{"U":-0.625,"V":1.125}'));
              ExpectSuccess(GetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', @len));
              ExpectEqual(grs(len), '{"U":-0.625,"V":1.125}');
            end);

          It('Should support texture coordinates in any order', procedure
            begin
              ExpectSuccess(SetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', '{"V":1,"U":25}'));
              ExpectSuccess(GetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', @len));
              ExpectEqual(grs(len), '{"U":25,"V":1}');
            end);

          It('Should not require setting both texture coordinates at the same time', procedure
            begin
              ExpectSuccess(SetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', '{"V":-23.125}'));
              ExpectSuccess(GetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', @len));
              ExpectEqual(grs(len), '{"U":25,"V":-23.125}');
            end);

          It('Should fail if the JSON values are invalid', procedure
            begin
              ExpectFailure(SetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', '{"U":true,"V":1}'));
              ExpectFailure(SetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', '{"U":[],"V":1}'));
            end);

          It('Should fail if the JSON is invalid', procedure
            begin
              ExpectFailure(SetNifTexCoords(nif, 'BSTriShape\Vertex Data\[0]\UV', 'Invalid'));
            end);

          It('Should fail if the element isn''t texture coordinates', procedure
            begin
              ExpectFailure(SetNifTexCoords(nif, '', '{"U":1,"V":1}'));
              ExpectFailure(SetNifTexCoords(rootNode, '', '{"U":1,"V":1}'));
              ExpectFailure(SetNifTexCoords(nif, 'bhkRigidBody\Rotation', '{"U":1,"V":1}'));
            end);
        end);

      Describe('GetNifFlag', procedure
        begin
          It('Should return false for disabled flags', procedure
            begin
              TestGetNifFlag(nif, 'BSXFlags\Flags', 'Animated', false);
              TestGetNifFlag(nif, 'BSTriShape\VertexDesc\VF', 'VF_COLORS', false);
              TestGetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Specular', false);
            end);

          It('Should return true for enabled flags', procedure
            begin
              TestGetNifFlag(nif, 'BSXFlags\Flags', 'Havok', true);
              TestGetNifFlag(nif, 'BSTriShape\VertexDesc\VF', 'VF_VERTEX', true);
              TestGetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Cast_Shadows', true);
            end);

          It('Should fail if the flag is not found', procedure
            begin
              ExpectFailure(GetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'NonExistingFlag', @b));
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(GetNifFlag(nif, '', 'Test', @b));
              ExpectFailure(GetNifFlag(rootNode, '', 'Enabled', @b));
              ExpectFailure(GetNifFlag(header, 'Endian Type', 'ENDIAN_BIG', @b));
            end);
        end);

      Describe('GetEnabledNifFlags', procedure
        begin
          It('Should return an empty string if no flags are enabled', procedure
            begin
              ExpectSuccess(SetEnabledNifFlags(childrenArray, '@[3]\VertexDesc\VF', ''));
              ExpectSuccess(GetEnabledNifFlags(childrenArray, '@[3]\VertexDesc\VF', @len));
              ExpectEqual(grs(len), '');
            end);

          It('Should return a comma separated string of flag names', procedure
            begin
              ExpectSuccess(GetEnabledNifFlags(nif, 'BSXFlags\Flags', @len));
              ExpectEqual(grs(len), 'Havok,Articulated');
              ExpectSuccess(GetEnabledNifFlags(nif, 'BSTriShape\VertexDesc\VF', @len));
              ExpectEqual(grs(len), 'VF_VERTEX,VF_UV,VF_NORMAL,VF_TANGENT');
              ExpectSuccess(GetEnabledNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 2', @len));
              ExpectEqual(grs(len), 'ZBuffer_Write,EnvMap_Light_Fade');
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(GetEnabledNifFlags(nif, '', @len));
              ExpectFailure(GetEnabledNifFlags(rootNode, '', @len));
              ExpectFailure(GetEnabledNifFlags(header, 'Endian Type', @len));
            end);
        end);


      Describe('SetNifFlag', procedure
        begin
          It('Should enable disabled flags', procedure
            begin
              TestSetNifFlag(nif, 'BSXFlags\Flags', 'Animated', true);
              TestSetNifFlag(nif, 'BSTriShape\VertexDesc\VF', 'VF_COLORS', true);
              TestSetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Specular', true);
            end);

          It('Should disable enabled flags', procedure
            begin
              TestSetNifFlag(nif, 'BSXFlags\Flags', 'Havok', false);
              TestSetNifFlag(nif, 'BSTriShape\VertexDesc\VF', 'VF_VERTEX', false);
              TestSetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Cast_Shadows', false);
            end);

          It('Should fail if the flag is not found', procedure
            begin
              ExpectFailure(SetNifFlag(nif, 'BSLightingShaderProperty\Shader Flags 1', 'NonExistingFlag', true));
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(SetNifFlag(nif, '', 'Test', true));
              ExpectFailure(SetNifFlag(rootNode, '', 'Enabled', true));
              ExpectFailure(SetNifFlag(header, 'Endian Type', 'ENDIAN_BIG', true));
            end);
        end);


      Describe('SetEnabledNifFlags', procedure
        begin
          It('Should enable flags that are present', procedure
            begin
              TestSetEnabledNifFlags(nif, 'BSXFlags\Flags', 'Havok,Articulated,External Emit');
              TestSetEnabledNifFlags(nif, 'BSTriShape\VertexDesc\VF', 'VF_VERTEX,VF_UV,VF_NORMAL');
              TestSetEnabledNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Recieve_Shadows,Cast_Shadows,Landscape,Refraction,Own_Emit');
            end);

          It('Should disable flags that are not present', procedure
            begin
              TestSetEnabledNifFlags(nif, 'BSXFlags\Flags', '');
              TestSetEnabledNifFlags(nif, 'BSTriShape\VertexDesc\VF', 'VF_VERTEX');
              TestSetEnabledNifFlags(nif, 'BSLightingShaderProperty\Shader Flags 1', 'Recieve_Shadows,Cast_Shadows');
            end);

          It('Should fail on elements that do not have flags', procedure
            begin
              ExpectFailure(SetEnabledNifFlags(nif, '', @len));
              ExpectFailure(SetEnabledNifFlags(rootNode, '', @len));
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

              ExpectSuccess(GetAllNifFlags(nif, 'BSTriShape\VertexDesc\VF', @len));
              str := grs(len);
              Expect(Pos('VF_Unknown_0', str) = 1, 'VF_Unknown_0 should be the first flag');
              Expect(Pos('VF_VERTEX', str) > 0, 'VF_VERTEX should be included');
              Expect(Pos('VF_SKINNED', str) > 0, 'VF_SKINNED should be included');
              Expect(Pos('VF_FULLPREC', str) > 0, 'VF_FULLPREC should be included');

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
              ExpectFailure(GetAllNifFlags(rootNode, '', @len));
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
              ExpectFailure(GetNifEnumOptions(rootNode, '', @len));
              ExpectFailure(GetNifEnumOptions(nif, 'BSTriShape\Flags', @len));
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
              ExpectSuccess(IsNifHeader(rootNode, @b));
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
              ExpectSuccess(IsNifFooter(rootNode, @b));
              ExpectEqual(b, false);
              ExpectSuccess(IsNifFooter(vector, @b));
              ExpectEqual(b, false);
            end);
        end);        
  end);
end;
end.

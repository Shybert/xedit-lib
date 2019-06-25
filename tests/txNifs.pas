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

procedure TestGetBlocks(h: Cardinal; path, search: PWideChar; expectedCount: Integer);
var
  len: Integer;
  a: CardinalArray;
  i: Integer;
begin
  if path <> '' then
    ExpectSuccess(GetNifElement(h, path, @h));
  ExpectSuccess(GetBlocks(h, search, @len));
  ExpectEqual(len, expectedCount);
  a := gra(len);
  for i := Low(a) to High(a) do
    ReleaseObjects(a[i]);
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
  h, h1, h2, h3, nif, rootNode: Cardinal;
  len: Integer;
begin
  Describe('Nif File Handling Functions', procedure
    begin
      BeforeAll(procedure
        begin
          ExpectSuccess(LoadNif(PWideChar(GetDataPath + 'xtest-1.nif'), @nif));
          ExpectSuccess(GetNifElement(nif, 'BSFadeNode', @rootNode));
        end);

      Describe('LoadNif', procedure
        begin
          Describe('From absolute', procedure
            begin
              It('Should return false with unsupported file', procedure
                begin
                  ExpectFailure(LoadNif(PWideChar(GetDataPath + 'xtest-1.esp'), @h1));
                  Expect(h1 = 0, 'Handle should be NULL.');
                end);

                It('Should return a handle if the filepath is valid', procedure
                  begin
                    ExpectSuccess(LoadNif(PWideChar(GetDataPath + 'xtest-1.nif'), @h1));
                    Expect(h1 > 0, 'Handle should be greater than 0');
                  end);
            end);

          Describe('From data', procedure
            begin
              It('Should return false with file not found', procedure
                begin
                  ExpectFailure(LoadNif(PWideChar('data\file\that\doesnt\exist.nif'), @h2));
                end);
              It('Should return handle of file', procedure
                begin
                  ExpectSuccess(LoadNif(PWideChar('data\xtest-2.nif'), @h2));
                  Expect(h2 > 0, 'Handle should be greater than 0');
                end);

            end);

          Describe('From specific Resource', procedure
            begin
              It('Should return false with unsupported file', procedure
                begin
                  ExpectFailure(LoadNif(PWideChar('Skyrim - Meshes.bsa\file\that\doesnt\exist.nif'), @h3));
                  Expect(h3 = 0, 'Handle should be NULL.');
                end);

              It('Should return a handle if the filepath is valid', procedure
                begin
                  ExpectSuccess(LoadNif(PWideChar('Skyrim - Meshes.bsa\meshes\primitivegizmo.nif'), @h3));
                  Expect(h3 > 0, 'Handle should be greater than 0');
                end);
            end);
      end);

      Describe('Free', procedure
        begin
          It('Should return true.', procedure
            begin
              ExpectSuccess(FreeNif(h2));
            end);
          It('Should return false.', procedure
            begin
              ExpectFailure(FreeNif(h2));
              h2 := 0;
            end);
          It('Should return true.', procedure
            begin
              ExpectSuccess(FreeNif(h3));
            end);
          It('Should return false.', procedure
            begin
              ExpectFailure(FreeNif(h3));
              h3 := 0;
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

      Describe('AddNif', procedure
        begin
          AfterAll(procedure
            begin
              DeleteNifs([GetDataPath + 'test.nif', GetDataPath + 'meshes\test.nif', GetDataPath + 'meshes\test\test.nif']);
            end);

          It('Should return true if it succeeds', procedure
            begin
              ExpectSuccess(AddNif(PWideChar(GetDataPath + 'test.nif'), false, @h));
            end);

          It('Should return true for a relative path', procedure
            begin
              ExpectSuccess(AddNif('meshes\test.nif', false, @h));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test.nif'));
            end);

          It('Should return true for a relative path starting with data\', procedure
            begin
              ExpectSuccess(AddNif('data\meshes\test\test.nif', false, @h));
              ExpectSuccess(FileExists(GetDataPath + 'meshes\test\test.nif'));
            end);

          It('Should return false if the file exists and ignoreExists is false', procedure
            begin
              ExpectFailure(AddNif(PWideChar(GetDataPath + 'test.nif'), false, @h));
            end);

          It('Should return true if the file exists and ignoreExists is true', procedure
            begin
              ExpectSuccess(AddNif(PWideChar(GetDataPath + 'test.nif'), true, @h));
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

      Describe('GetBlocks', procedure
        begin
          Describe('No search', procedure
          begin
            It('Should return all blocks in a Nif file', procedure
              begin
                TestGetBlocks(nif, '', '', 30);
              end);
            It('Should return all referenced blocks in a Nif block', procedure
              begin
                TestGetBlocks(nif, 'BSFadeNode', '', 9);
                TestGetBlocks(nif, 'BSFurnitureMarkerNode', '', 0);
              end);
          end);

          Describe('Search', procedure
          begin
            It('Should return all blocks of a given block type in a Nif file', procedure
              begin
                TestGetBlocks(nif, '', 'BSTriShape', 7);
              end);
            It('Should return all referenced blocks of a given block type in a Nif block', procedure
              begin
                TestGetBlocks(nif, 'BSFadeNode', 'BSTriShape', 5);
                TestGetBlocks(nif, 'BSFurnitureMarkerNode', 'BSTriShape', 0);
              end);
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

      Describe('GetNifVector', procedure
        begin
          It('Should resolve vectors as a JSON string', procedure
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

      Describe('Cleanup', procedure
        begin
          It('Should return true.', procedure
            begin
              ExpectSuccess(FreeNif(h1));;
            end);
          It('Should return false as parent handle should free.', procedure
            begin
              ExpectFailure(FreeNif(h2));;
            end);
      end);
  end);
end;
end.

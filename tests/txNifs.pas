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
    Release(a[i]);
end;

procedure BuildFileHandlingTests;
var
  b: WordBool;
  h, h1, h2, h3: Cardinal;
  len: Integer;
begin
  Describe('Nif File Handling Functions', procedure
    begin
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

      Describe('HasNifElement', procedure
        begin
          It('Should return true for blocks that exist', procedure
            begin
              TestHasNifElement(h1, 'BSFadeNode');
            end);
          It('Should return true for block elements that exist', procedure
            begin
              TestHasNifElement(h1, 'BSFadeNode\Name');
            end);
          It('Should return true for assigned handles', procedure
            begin
              TestHasNifElement(h1, '');
            end);
          It('Should return false for blocks that do not exist', procedure
            begin
              TestHasNifElement(h1, 'NonExistingBlock', false);
            end);
          It('Should return false for block elements that do not exist', procedure
            begin
              TestHasNifElement(h1, 'BSFadeNode\NonExistingElement', false);
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
                  TestGetNifElement(h1, '[0]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectFailure(GetNifElement(h1, '[-9]', @h));
                end);
            end);

          Describe('Block resolution by block type', procedure
            begin
              It('Should return a handle if a matching block exists', procedure
                begin
                  TestGetNifElement(h1, 'BSFadeNode');
                end);

              It('Should fail if a matching block does not exist', procedure
                begin
                  ExpectFailure(GetNifElement(h1, 'NonExistingBlock', @h));
                end);
            end);

          Describe('Block resolution by name', procedure
            begin
              It('Should return a handle if a matching block exists', procedure
                begin
                  TestGetNifElement(h1, '"WindhelmThrone"');
                end);

              It('Should fail if a matching block does not exist', procedure
                begin
                  ExpectFailure(GetNifElement(h1, '"John Doe"', @h));
                end);
            end);

          Describe('Block element resolution by index', procedure
            begin
              It('Should return a handle if the index is in bounds', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  TestGetNifElement(h2, '[0]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  ExpectFailure(GetNifElement(h2, '[-9]', @h3));
                end);
            end);

          Describe('Block element resolution by name', procedure
            begin
              It('Should return a handle if a matching element exists', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  TestGetNifElement(h2, 'Name');
                end);

              It('Should fail if a matching element does not exist', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  ExpectFailure(GetNifElement(h2, 'NonExistingElement', @h3));
                end);
            end);

          Describe('Block reference resolution by block type', procedure
            begin
              It('Should return a handle if a matching reference exists', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  TestGetNifElement(h2, 'NiNode');
                  TestGetNifElement(h2, 'BSFurnitureMarkerNode');
                  TestGetNifElement(h2, 'bhkCollisionObject');
                end);

              It('Should fail if a matching reference does not exist', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  ExpectFailure(GetNifElement(h2, 'NonExistingReference', @h3));
                end);
            end);

          Describe('Block reference resolution by name', procedure
            begin
              It('Should return a handle if a matching reference exists', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  TestGetNifElement(h2, '"SteelShield"');
                  TestGetNifElement(h2, '"FRN"');
                  TestGetNifElement(h2, '"BSX"');
                end);

              It('Should fail if a matching reference does not exist', procedure
                begin
                  ExpectSuccess(GetNifElement(h1, 'BSFadeNode', @h2));
                  ExpectFailure(GetNifElement(h2, '"John Doe"', @h3));
                end);
            end);

          Describe('Keyword resolution', procedure
            begin
              It('Should return a handle for the roots element', procedure
                begin
                  TestGetNifElement(h1, 'Roots');
                end);
              It('Should return a handle for the header', procedure
                begin
                  TestGetNifElement(h1, 'Header');
                end);
              It('Should return a handle for the footer', procedure
                begin
                  TestGetNifElement(h1, 'Footer');
                end);
            end);

          Describe('Nested resolution', procedure
            begin
              It('Should resolve nested paths, if all are valid', procedure
                begin
                  TestGetNifElement(h1, 'BSFadeNode\NiNode\BSTriShape\BSLightingShaderProperty\BSShaderTextureSet\Textures');
                end);
              It('Should fail if any subpath is invalid', procedure
                begin
                  ExpectFailure(GetNifElement(h1, 'BSFadeNode\NiNode\BSTriShape\NonExistingBlock', @h2));
                end);
            end);
        end);

      Describe('GetBlocks', procedure
        begin
          Describe('No search', procedure
          begin
            It('Should return all blocks in a Nif file', procedure
              begin
                TestGetBlocks(h1, '', '', 30);
              end);
            It('Should return all referenced blocks in a Nif block', procedure
              begin
                TestGetBlocks(h1, 'BSFadeNode', '', 9);
                TestGetBlocks(h1, 'BSFurnitureMarkerNode', '', 0);
              end);
          end);

          Describe('Search', procedure
          begin
            It('Should return all blocks of a given block type in a Nif file', procedure
              begin
                TestGetBlocks(h1, '', 'BSTriShape', 7);
              end);
            It('Should return all referenced blocks of a given block type in a Nif block', procedure
              begin
                TestGetBlocks(h1, 'BSFadeNode', 'BSTriShape', 5);
                TestGetBlocks(h1, 'BSFurnitureMarkerNode', 'BSTriShape', 0);
              end);
          end);
        end);

      Describe('GetNifName', procedure
        begin
          It('Should return true if file handle is valid', procedure
            begin
              ExpectSuccess(GetNifName(h1, @len));
              ExpectEqual(grs(len), 'NIF');
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

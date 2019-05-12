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

procedure TestNifGetElement(h: Cardinal; path: PWideChar);
var
  element: Cardinal;
begin
  ExpectSuccess(NifGetElement(h, path, @element));
  Expect(element > 0, 'Handle should be greater than 0');
end;


procedure BuildFileHandlingTests;
var
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
                  ExpectFailure(NifLoad(PWideChar(GetDataPath + 'xtest-1.esp'), @h1));
                  Expect(h1 = 0, 'Handle should be NULL.');
                end);

                It('Should return a handle if the filepath is valid', procedure
                  begin
                    ExpectSuccess(NifLoad(PWideChar(GetDataPath + 'xtest-1.nif'), @h1));
                    Expect(h1 > 0, 'Handle should be greater than 0');
                  end);
            end);

          Describe('From data', procedure
            begin
              It('Should return false with file not found', procedure
                begin
                  ExpectFailure(NifLoad(PWideChar('data\file\that\doesnt\exist.nif'), @h2));
                end);
              It('Should return handle of file', procedure
                begin
                  ExpectSuccess(NifLoad(PWideChar('data\xtest-2.nif'), @h2));
                  Expect(h2 > 0, 'Handle should be greater than 0');
                end);

            end);

          Describe('From specific Resource', procedure
            begin
              It('Should return false with unsupported file', procedure
                begin
                  ExpectFailure(NifLoad(PWideChar('Skyrim - Meshes.bsa\file\that\doesnt\exist.nif'), @h3));
                  Expect(h3 = 0, 'Handle should be NULL.');
                end);

              It('Should return a handle if the filepath is valid', procedure
                begin
                  ExpectSuccess(NifLoad(PWideChar('Skyrim - Meshes.bsa\meshes\primitivegizmo.nif'), @h3));
                  Expect(h3 > 0, 'Handle should be greater than 0');
                end);
            end);
      end);

      Describe('Free', procedure
        begin
          It('Should return true.', procedure
            begin
              ExpectSuccess(NifFree(h2));
            end);
          It('Should return false.', procedure
            begin
              ExpectFailure(NifFree(h2));
              h2 := 0;
            end);
          It('Should return true.', procedure
            begin
              ExpectSuccess(NifFree(h3));
            end);
          It('Should return false.', procedure
            begin
              ExpectFailure(NifFree(h3));
              h3 := 0;
            end);
        end);

      Describe('NifGetElement', procedure
        begin
          Describe('Block resolution by index', procedure
            begin
              It('Should return a handle if the index is in bounds', procedure
                begin
                  TestNifGetElement(h1, '[0]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectFailure(NifGetElement(h1, '[-9]', @h));
                end);
            end);

          Describe('Block resolution by name', procedure
            begin
              It('Should return a handle if a matching block exists', procedure
                begin
                  TestNifGetElement(h1, 'BSFadeNode');
                end);

              It('Should fail if a matching block does not exist', procedure
                begin
                  ExpectFailure(NifGetElement(h1, 'NonExistingBlock', @h));
                end);
            end);

          Describe('Block element resolution by index', procedure
            begin
              It('Should return a handle if the index is in bounds', procedure
                begin
                  ExpectSuccess(NifGetElement(h1, 'BSFadeNode', @h2));
                  TestNifGetElement(h2, '[0]');
                end);

              It('Should fail if index is out of bounds', procedure
                begin
                  ExpectSuccess(NifGetElement(h1, 'BSFadeNode', @h2));
                  ExpectFailure(NifGetElement(h2, '[-9]', @h3));
                end);
            end);

          Describe('Block element resolution by name', procedure
            begin
              It('Should return a handle if a matching element exists', procedure
                begin
                  ExpectSuccess(NifGetElement(h1, 'BSFadeNode', @h2));
                  TestNifGetElement(h2, 'Name');
                end);

              It('Should fail if a matching element does not exist', procedure
                begin
                  ExpectSuccess(NifGetElement(h1, 'BSFadeNode', @h2));
                  ExpectFailure(NifGetElement(h2, 'NonExistingElement', @h3));
                end);
            end);

          Describe('Keyword resolution', procedure
            begin
              It('Should return a handle for the roots element', procedure
                begin
                  TestNifGetElement(h1, 'Roots');
                end);
              It('Should return a handle for the header', procedure
                begin
                  TestNifGetElement(h1, 'Header');
                end);
              It('Should return a handle for the footer', procedure
                begin
                  TestNifGetElement(h1, 'Footer');
                end);
            end);
        end);

      Describe('GetName', procedure
        begin
          It('Should return true if file handle is valid', procedure
            begin
              ExpectSuccess(NifGetName(h1, @len));
              ExpectEqual(grs(len), 'NIF');
            end);

        end);

      Describe('Cleanup', procedure
        begin
          It('Should return true.', procedure
            begin
              ExpectSuccess(NifFree(h1));;
            end);
          It('Should return false as parent handle should free.', procedure
            begin
              ExpectFailure(NifFree(h2));;
            end);
      end);
  end);
end;
end.

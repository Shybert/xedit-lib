unit txMasters;

interface

  // PUBLIC TESTING INTERFACE
  procedure BuildMasterHandlingTests;

implementation

uses
  SysUtils, Mahogany,
  {$IFNDEF USE_DLL}
  xeElementValues, xeElements, xeFiles, xeMasters,
  {$ENDIF}
  {$IFDEF USE_DLL}
  txImports,
  {$ENDIF}
  txMeta;

procedure TestMasterCount(f: Cardinal; expectedCount: Integer);
var
  masters: Cardinal;
  count: Integer;
begin
  ExpectSuccess(GetElement(f, 'File Header\Master Files', @masters));
  ExpectSuccess(ElementCount(masters, @count));
  ExpectEqual(count, expectedCount);
end;

procedure BuildMasterHandlingTests;
var
  xt5: Cardinal;
begin
  Describe('Master handling', procedure
    begin
      BeforeAll(procedure
        begin
          ExpectSuccess(FileByName('xtest-5.esp', @xt5));
          TestMasterCount(xt5, 2);
        end);

      Describe('AddMaster', procedure
        begin
          It('Should add master if matching file is present', procedure
            begin
              ExpectSuccess(AddMaster(xt5, 'xtest-3.esp'));
              TestMasterCount(xt5, 3);
            end);

          It('Should not duplicate masters', procedure
            begin
              ExpectSuccess(AddMaster(xt5, 'xtest-3.esp'));
              TestMasterCount(xt5, 3);
            end);

          It('Should fail if matching file is not present', procedure
            begin
              ExpectFailure(AddMaster(xt5, 'NonExistingFile.esp'));
              TestMasterCount(xt5, 3);
            end);
        end);

      Describe('AddMasters', procedure
        begin
          It('Should add multiple masters', procedure
            begin
              ExpectSuccess(AddMasters(xt5, 'xtest-2.esp'#13#10'xtest-4.esp'));
              TestMasterCount(xt5, 5);
            end);

          It('Should not duplicate masters', procedure
            begin
              ExpectSuccess(AddMasters(xt5, 'xtest-2.esp'#13#10'xtest-1.esp'));
              TestMasterCount(xt5, 6);
            end);

          It('Should fail if one or masters does not exist', procedure
            begin
              ExpectFailure(AddMasters(xt5, 'NonExistingFile.esp'#13#10'xtest-1.esp'#13#10'Blah.esp'));
              TestMasterCount(xt5, 6);
            end);
        end);
    end);
end;

end.

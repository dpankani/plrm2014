unit _PLRMD1LandUseAssignmnt2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, jpeg, ExtCtrls, Grids, DBGrids, GSIO, GSUtils, GSTypes, GSPLRM, GSCatchments,
  UProject;

type
  TPLRMLandUse = class(TForm)
    btnCancel: TButton;
    btnOk: TButton;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label4: TLabel;
    Label1: TLabel;
    Label3: TLabel;
    sgLuse: TStringGrid;
    lbxLuseFrom: TListBox;
    btnToRight: TButton;
    btnToLeft: TButton;
    btnAllToRight: TButton;
    btnAllToLeft: TButton;
    lbxLuseTo: TListBox;
    Image1: TImage;
    statBar: TStatusBar;
    Label5: TLabel;
    Label6: TLabel;
    cbxGlobalSpecfc: TComboBox;
    Label8: TLabel;
    Label7: TLabel;
    lblCatchArea: TLabel;
    btnApply: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnToRightClick(Sender: TObject);
    procedure btnToLeftClick(Sender: TObject);
    procedure btnAllToRightClick(Sender: TObject);
    procedure btnAllToLeftClick(Sender: TObject);
    procedure sgLuseDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure sgLuseSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure sgLuseKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cbxGlobalSpecfcChange(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure rePopulateForm(catch: TPLRMCatch);
    procedure sgLuseKeyPress(Sender: TObject; var Key: Char);
    procedure sgLuseSetEditText(Sender: TObject; ACol, ARow: Integer;
    const Value: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;
     function getCatchLuseInput(CatchID: String): Integer;
var
  FrmLuse: TPLRMLandUse;
  catchArea: Double;
  curGridContents : String;
  initCatchID: String;
  luseDBData: dbReturnFields;
  prevGridVal:String;

implementation

{$R *.dfm}

procedure updateGrid(catchArea:Double; Grd:TStringGrid);
var
  R, lastRow: LongInt;
  acreSum, prcntSum, wtdSum : Double;
begin
  acreSum := 0;
  prcntSum := 0;
  wtdSum := 0;
  lastRow := Grd.RowCount -1;
  for R := 1 to lastRow do
  begin
    //Sum up %catchment area values
      if Grd.Cells[1,R] = '' then
         Grd.Cells[1,R] := '0';
      prcntSum := prcntSum +  StrToFloat(Grd.Cells[1,R]);

      if Grd.Cells[2,R] = '' then
      Grd.Cells[2,R] := '100';

      Grd.Cells[3,R] := FormatFloat(ONEDP,(StrToFloat(Grd.Cells[1,R])/100) * catchArea);

      acreSum := acreSum +   (StrToFloat(Grd.Cells[3,R]));

      wtdSum := wtdSum + ((StrToFloat(Grd.Cells[1,R])/100) * StrToFloat(Grd.Cells[2,R]) * catchArea);
  end;
  Grd.Cells[0,0] := 'Sub-totals';
  Grd.Cells[1,0] := FormatFloat(TWODP,prcntSum);
  if acreSum = 0 then
    Grd.Cells[2,0] := '0'
  else
    Grd.Cells[2,0] := FormatFloat(ONEDP,wtdSum /acreSum);
  Grd.Cells[3,0] := FormatFloat(ONEDP,acreSum);
end;

procedure TPLRMLandUse.btnAllToLeftClick(Sender: TObject);
var I:integer;
begin
    for I := 0 to lbxLuseTo.Items.Count - 1 do
         GSUtils.deleteGridRow(lbxLuseTo.Items[I], 0,'0',sgLuse);
     GSUtils.TransferAllLstBxItems(lbxLuseFrom, lbxLuseTo);
     updateGrid(catchArea,sgLuse);

     btnAllToRight.Enabled := true;
     btnToRight.Enabled := true;
     btnToLeft.Enabled := true;
     btnAllToLeft.Enabled := false;
     PLRMObj.currentCatchment.hasDefDrnXtcs := false;
end;

procedure TPLRMLandUse.btnAllToRightClick(Sender: TObject);
var I, tempInt:integer;
begin
    GSUtils.TransferAllLstBxItems(lbxLuseTo, lbxLuseFrom);
    for I := 0 to lbxLuseTo.Items.Count - 1 do
      if (GSUtils.gridContainsStr(lbxLuseTo.Items[I],0, sgLuse) = false) then
      begin
        tempInt := luseDBData[0].IndexOf(lbxLuseTo.Items[I]);
        GSUtils.AddGridRow(lbxLuseTo.Items[I], sgLuse,0);//add land use name
        if tempInt <>-1 then sgLuse.Cells[2,sgLuse.rowCount-1] := luseDBData[1][tempInt]; // add land use imperviousness
      end;
    updateGrid(catchArea,sgLuse);
    btnAllToRight.Enabled := false;
    btnToRight.Enabled := false;
    btnToLeft.Enabled := true;
    btnAllToLeft.Enabled := true;
    PLRMObj.currentCatchment.hasDefDrnXtcs := false;
end;

procedure TPLRMLandUse.btnToLeftClick(Sender: TObject);
var
  I:integer;
  tempInt:Integer;
begin

 if (lbxLuseTo.SelCount = 0) then
  begin
    ShowMessage('Please select an item first and then click a button');
    Exit;
  end;

    for I := 0 to lbxLuseTo.Items.Count - 1 do
    begin
      tempInt := PLRMObj.currentCatchment.landUseNames.IndexOf(lbxLuseTo.Items[I]);
      if (tempInt <> - 1) then PLRMObj.currentCatchment.landUseNames.Delete(tempInt);
      if lbxLuseTo.Selected[I] then
         GSUtils.deleteGridRow(lbxLuseTo.Items[I], 0,'0',sgLuse);
    end;
    GSUtils.TransferLstBxItems(lbxLuseFrom, lbxLuseTo);
    updateGrid(catchArea,sgLuse);
    btnAllToRight.Enabled := true;
    btnToRight.Enabled := true;
    btnToLeft.Enabled := true;
    btnAllToLeft.Enabled := true;
    PLRMObj.currentCatchment.hasDefDrnXtcs := false;
end;

procedure TPLRMLandUse.btnToRightClick(Sender: TObject);
var I, tempInt:integer;
begin
  if (lbxLuseFrom.SelCount = 0) then
  begin
    ShowMessage('Please select an item first and then click a button');
    Exit;
  end;

  GSUtils.TransferLstBxItems(lbxLuseTo, lbxLuseFrom);
  if lbxLuseFrom.items.count <> 0 then
  begin
  //lbxLuseFrom.ItemIndex := 1;
  end;

  for I := 0 to lbxLuseTo.Items.Count - 1 do
  if (GSUtils.gridContainsStr(lbxLuseTo.Items[I],0, sgLuse) = false) then
  begin
    tempInt := luseDBData[0].IndexOf(lbxLuseTo.Items[I]);
    GSUtils.AddGridRow(lbxLuseTo.Items[I], sgLuse,0); // add land use name
    if tempInt <>-1 then sgLuse.Cells[2,sgLuse.rowCount-1] := luseDBData[1][tempInt]; // add land use imperviousness
  end;

  btnAllToRight.Enabled := true;
  btnToRight.Enabled := true;
  btnToLeft.Enabled := true;
  btnAllToLeft.Enabled := true;
  PLRMObj.currentCatchment.hasDefDrnXtcs := false;
end;

procedure TPLRMLandUse.rePopulateForm(catch: TPLRMCatch);
var I, tempInt:Integer;
begin
  if catch.landUseNames <> nil then
  begin
    for I := 0 to catch.landUseNames.Count - 1 do
    begin
       tempInt := lbxLuseFrom.Items.IndexOf(catch.landUseNames[I]);
       if (tempInt > -1) then
       begin
        lbxLuseFrom.Selected[tempInt] :=true;
        btnToRightClick(TObject.Create);
       end;
    end;
    GSUtils.copyContentsToGridNChk(PLRMObj.currentCatchment.landUseData,0,1,sgLuse);
    updateGrid(catchArea,sgLuse);
  end;
end;

procedure TPLRMLandUse.cbxGlobalSpecfcChange(Sender: TObject);
begin
    //set current catchment to the obj coresponding to selected value
    btnAllToLeftClick(Sender); //empty grid of previous land use selections
    PLRMObj.currentCatchment := GSUtils.getComboBoxSelValue2(Sender) as TPLRMCatch;
    catchArea := PLRMObj.currentCatchment.area;
    lblCatchArea.Caption := 'Selected Catchment Area is: ' + PLRMobj.currentCatchment.swmmCatch.Data[UProject.SUBCATCH_AREA_INDEX] + ' ac';

    if PLRMObj.currentCatchment.hasDefLuse = true then
      repopulateForm(PLRMObj.currentCatchment);
end;

procedure TPLRMLandUse.btnCancelClick(Sender: TObject);
begin
      ModalResult := mrCancel;
end;

procedure TPLRMLandUse.btnOkClick(Sender: TObject);
begin
  if (sgLuse.Cells[1,0] <> '100.00')then
  begin
    ShowMessage('"% of Catchment Area" assignments in Column 1 of the grid must add up to 100%"');
    Exit;
  end;
  //check that first row does not contain blank landuse cell
  if (sgLuse.Cells[0,1] = '')then
  begin
    ShowMessage('"Please add at least one land use and assign imperviousness to proceed"');
    Exit;
  end;
  btnApplyClick(Sender);
  ModalResult := mrOK;
end;

procedure TPLRMLandUse.btnApplyClick(Sender: TObject);
var
  hasLuse :array[0..6] of Boolean;
begin
  GSPLRM.PLRMObj.currentCatchment.landUseData := GSUtils.copyGridContents(0,1,GSPLRM.PLRMObj.currentCatchment.landUseNames, sgLuse,1,0);
  GSPLRM.PLRMObj.currentCatchment.hasDefLuse := true;

     //zero out previously assigned values from screen 5
  //with PLRMObj.currentCatchment do
  //begin
    if(assigned(PLRMObj.currentCatchment.primRdDrng) and (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[0],2,hasLuse[0]) = 0.0)) then
    begin
      PLRMObj.currentCatchment.primRdDrng[0][1] := '0';
      PLRMObj.currentCatchment.primRdDrng[1][1] := '0';
      PLRMObj.currentCatchment.primRdDrng[2][1] := '0';
      PLRMObj.currentCatchment.primRdDrng[0][2] := '0';
      PLRMObj.currentCatchment.primRdDrng[1][2] := '0';
      PLRMObj.currentCatchment.primRdDrng[2][2] := '0';
    end;
    if (assigned(PLRMObj.currentCatchment.secRdDrng) And (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[1],2,hasLuse[1]) = 0)) then
    begin
      PLRMObj.currentCatchment.secRdDrng[0][1] := '0';
      PLRMObj.currentCatchment.secRdDrng[1][1] := '0';
      PLRMObj.currentCatchment.secRdDrng[2][1] := '0';
      PLRMObj.currentCatchment.secRdDrng[0][2] := '0';
      PLRMObj.currentCatchment.secRdDrng[1][2] := '0';
      PLRMObj.currentCatchment.secRdDrng[2][2] := '0';
    end;
    if (assigned(PLRMObj.currentCatchment.sfrDrng) And (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[2],2,hasLuse[2]) = 0)) then
    begin
      PLRMObj.currentCatchment.sfrDrng[0][1] := '0';
      PLRMObj.currentCatchment.sfrDrng[1][1] := '0';
      PLRMObj.currentCatchment.sfrDrng[0][2] := '0';
      PLRMObj.currentCatchment.sfrDrng[1][2] := '0';
    end;
    if (assigned(PLRMObj.currentCatchment.mfrDrng) And (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[3],2,hasLuse[3]) = 0)) then
    begin
      PLRMObj.currentCatchment.mfrDrng[0][1] := '0';
      PLRMObj.currentCatchment.mfrDrng[1][1] := '0';
      PLRMObj.currentCatchment.mfrDrng[0][2] := '0';
      PLRMObj.currentCatchment.mfrDrng[1][2] := '0';
    end;
    if (assigned(PLRMObj.currentCatchment.cicuDrng) And (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[4],2,hasLuse[4]) = 0)) then
    begin
      PLRMObj.currentCatchment.cicuDrng[0][1] := '0';
      PLRMObj.currentCatchment.cicuDrng[1][1] := '0';
      PLRMObj.currentCatchment.cicuDrng[0][2] := '0';
      PLRMObj.currentCatchment.cicuDrng[1][2] := '0';
    end;
    if (assigned(PLRMObj.currentCatchment.vegTDrng) And (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[5],2,hasLuse[5]) = 0)) then
    begin
      PLRMObj.currentCatchment.vegTDrng[0][1] := '0';
      PLRMObj.currentCatchment.vegTDrng[0][2] := '0';
    end;

    if (assigned(PLRMObj.currentCatchment.othrDrng) And (PLRMobj.getCurCatchLuseProp(GSUtils.frmsLuses[6],2,hasLuse[6]) = 0)) then
    begin
      PLRMObj.currentCatchment.othrDrng[0][1] := '0';
      PLRMObj.currentCatchment.othrDrng[0][2] := '0';
    end;
  //end;
end;

procedure TPLRMLandUse.FormCreate(Sender: TObject);
var
  S : TStringList;
  tempInt : Integer;
begin
  statBar.SimpleText := PLRMVERSION;
  Self.Caption := PLRMD1_TITLE;

  tempInt := PLRMObj.getCatchIndex(initCatchID);
  //comes before lookup of index because lookup updates catchID if changed
  cbxGlobalSpecfc.items := PLRMObj.catchments; // loads catchments into combo box
  cbxGlobalSpecfc.ItemIndex := tempInt;
  PLRMObj.currentCatchment := PLRMObj.catchments.Objects[tempInt] as TPLRMCatch;
  catchArea := PLRMObj.currentCatchment.area;
  //lblCatchArea.Caption := 'Selected Catchment Area is: ' + PLRMobj.currentCatchment.swmmCatch.Data[UProject.SUBCATCH_AREA_INDEX] + ' ac';
  lblCatchArea.Caption := 'Catchment ID: ' + PLRMObj.currentCatchment.swmmCatch.ID + '   [ Area: ' + PLRMobj.currentCatchment.swmmCatch.Data[UProject.SUBCATCH_AREA_INDEX] + 'ac ]';

  S := GSIO.getCodes('1%');
  luseDBData := GSIO.lookUpValFrmTable(18,2,3);
  //S := GSIO.getCodes('l1%');
  lbxLuseFrom.Items := S;
  sgLuse.ColWidths[0] := 260;
  if PLRMObj.currentCatchment.hasDefLuse = true then
    rePopulateForm(PLRMObj.currentCatchment);
end;

function getCatchLuseInput(CatchID: String): Integer;
  var
    FrmPLRMLuse: TPLRMLandUse;
    tempInt : Integer;
  begin
    initCatchID := catchID;
    FrmPLRMLuse := TPLRMLandUse.Create(Application);
    try
      tempInt := FrmPLRMLuse.ShowModal;
      //if tempInt = mrOK then
      //begin
        Result:= tempInt; //Result := FrmPLRMLuse
      //end;
    finally
      FrmPLRMLuse.Free;
    end;
end;

procedure TPLRMLandUse.sgLuseDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var S : String;
begin
  if ((ACol=0) or (ACol=3) or (ARow = 0 ))then begin //or (ARow = 0 ))then begin
    sgLuse.Canvas.Brush.Color := cl3DLight;
    sgLuse.Canvas.FillRect(Rect);
    S := sgLuse.Cells[ACol, ARow];
    sgLuse.Canvas.Font.Color := clBlue;
    sgLuse.Canvas.TextOut(Rect.Left + 2, Rect.Top + 2, S);
  end;
end;

procedure TPLRMLandUse.sgLuseKeyPress(Sender: TObject; var Key: Char);
begin
  gsEditKeyPress(Sender,Key,gemPosNumber) ;
end;

procedure TPLRMLandUse.sgLuseKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
      updateGrid(catchArea,sgLuse);
end;

procedure TPLRMLandUse.sgLuseSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  prevGridVal := sgLuse.Cells[ACol,ARow];
  if (ACol=0) or (ARow = 0 ) or (ACol = 3 )then
    begin
      sgLuse.Options:=sgLuse.Options-[goEditing];
    end
  else
  begin
    sgLuse.Options:=sgLuse.Options+[goEditing];
  end;
end;

procedure TPLRMLandUse.sgLuseSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin

  if sgLuse.Cells[ACol,ARow] = '' then Exit;

  if ACol > 0 then
  begin
    if (StrToFloat(sgLuse.Cells[ACol,ARow]) > 100) then
    begin
       ShowMessage('Cell values must not exceed 100% and the sum of all the values in this column must add up to 100%!');
       sgLuse.Cells[ACol,ARow] := prevGridVal;
       updateGrid(catchArea,sgLuse);
       Exit;
    end;   
  end;
end;

end.

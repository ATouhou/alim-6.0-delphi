{Version 7.01}
{*********************************************************}
{*                     HTMLSBS1.PAS                      *}
{*                Copyright (c) 1995-9 by                *}
{*                   L. David Baldwin                    *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$i htmlcons.inc}

unit Htmlsbs1;

interface
uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, HTMLUn2, HTMLGif, HTMLSubs;

Type

  TPage = class(TSectionBase)
  public
    function Draw(Canvas: TCanvas; const ARect: TRect;
         IMgr: IndentManager; X : integer; Y: LongInt) : LongInt;  override;
    end;

  TParagraphSpace = class(TSectionBase)  {spacing for a <p>}
    procedure UpdateSpacing; override;
    procedure CopyToClipboard; override;
    end;

  THeadingSpace = class(TSectionBase)     {spacing for <Hn>}
    HeadingSize: integer;

    constructor Create(AMasterList: TSectionList; AHeadingSize: integer);
    constructor CreateCopy(AMasterList: TSectionList; T: TSectionBase); override;
    procedure CopyToClipboard; override;
    procedure UpdateSpacing; override;
    end;

  THorzLine = class(TSectionBase)          {a horizontal line, <hr>}
    VSize: integer;
    HWidth: integer;
    AsPercent: boolean;
    Color: TColor;
    Align: JustifyType;
    NoShade: boolean;        
    BkGnd: boolean;
    constructor Create(AMasterList: TSectionList; L: TAttributeList);
    constructor CreateCopy(AMasterList: TSectionList; T: TSectionBase); override;
    procedure CopyToClipboard; override;
    function DrawLogic(Canvas : TCanvas; Y: LongInt; IMgr: IndentManager;
             var MaxWidth: integer; var Curs: LongInt): LongInt; override;
    function Draw(Canvas: TCanvas; const ARect: TRect;
         IMgr: IndentManager; X : integer; Y: LongInt) : LongInt;  override;
    procedure UpdateSpacing; override;
    end;

   TPreFormated = class(TSection)
  {section for preformated, <pre>}
  public
    procedure AddText(S : string); override;
    function DrawLogic(Canvas : TCanvas; Y: LongInt; IMgr: IndentManager;
             var MaxWidth: integer; var Curs: LongInt): LongInt; override;
    procedure MinMaxWidth(Canvas: TCanvas; var Min, Max: integer); override;
    end;

 TUListItem = class(TSection)     {Unordered List}
    Plain: boolean;
    constructor Create(AMasterList: TSectionList; Level: integer; AFont: TMyFont;
                         AnURL: TUrlTarget);
    constructor CreateCopy(AMasterList: TSectionList; T: TSectionBase); override;
    end;

  TDListItem = class(TUListItem)     {Definition List}
    constructor Create(AMasterList: TSectionList; Level: integer; AFont:
                TMyFont; AnURL: TUrlTarget);
    end;

  TOListItem = class(TUListItem)    {Ordered List}
    IndexType: char;  {1,a,A,i,I}
    constructor Create(AMasterList: TSectionList; Level, ItemNumb: integer;
                Index: char; AFont: TMyFont; AnURL: TUrlTarget);
    constructor CreateCopy(AMasterList: TSectionList; T: TSectionBase); override;
    end;

  TListBoxFormControlObj = class(TFormControlObj)
  public
    LBSize, Longest: integer;
    TheOptions: TStringList;
    constructor Create(AMasterList: TSectionList; Position: integer; L: TAttributeList);
    destructor Destroy; override;
    procedure Draw(Canvas: TCanvas; X1, Y1: integer); override;
    procedure AddStr(const S, Value: string; Selected: boolean);
    procedure ResetToValue; override;
    procedure SetHeightWidth(Canvas: TCanvas); override;
    function GetSubmission(Index: integer; var S: string): boolean; override;
  end;

  TComboFormControlObj = class(TListBoxFormControlObj)
  public
    constructor Create(AMasterList: TSectionList; Position: integer; L: TAttributeList);
    procedure Draw(Canvas: TCanvas; X1, Y1: integer); override;
    procedure ResetToValue; override;
    procedure SetHeightWidth(Canvas: TCanvas); override;
    function GetSubmission(Index: integer; var S: string): boolean; override;
  end;

  TTextAreaFormControlObj = class(TFormControlObj)
  public
    Rows, Cols: integer;
    TheText: TStringList;
    constructor Create(AMasterList: TSectionList; Position: integer; L: TAttributeList);
    destructor Destroy; override;
    procedure Draw(Canvas: TCanvas; X1, Y1: integer); override;
    procedure AddStr(const S: string);
    procedure ResetToValue; override;
    procedure SetHeightWidth(Canvas: TCanvas); override;
    function GetSubmission(Index: integer; var S: string): boolean; override;
  end;

  TFormControlList = class(TList)  {a list of TFormControlObj's}  {not TFreeList}
  Public
    function FindControl(Posn: integer): TFormControlObj;
    function GetHeightAt(Posn: integer; var BaseLine: boolean) : Integer;
    function GetWidthAt(Posn: integer) : integer;
    function GetControlCountAt(Posn: integer): integer;
    end;

Implementation

uses
  ReadHTML, HTMLView;

{----------------TPage.Draw}
function TPage.Draw(Canvas: TCanvas; const ARect: TRect;
         IMgr: IndentManager; X : integer; Y: LongInt) : LongInt;
var
  YOffset: LongInt;
begin
Result := inherited Draw(Canvas, ARect, Imgr, X, Y);

with ParentSectionList do
  if Printing then
    begin
    YOffset := YOff;
    if (Y-YOffset > ARect.Top+5) and (Y-YOffset < ARect.Bottom) and
         (Y < PageBottom) then
      PageBottom := Y;
    end;
end;

{----------------TParagraphSpace.UpdateSpacing}
procedure TParagraphSpace.UpdateSpacing;
begin
SectionHeight := MulDiv(14, ParentSectionList.FontSize, 12);   {scale to FontSize}
end;

procedure TParagraphSpace.CopyToClipboard;
begin
ParentSectionList.CB.AddTextCr('', 0);
end;

{----------------THeadingSpace.Create}
constructor THeadingSpace.Create(AMasterList: TSectionList; AHeadingSize: integer);
begin
inherited Create(AMasterList);
HeadingSize := AHeadingSize;
end;

constructor THeadingSpace.CreateCopy(AMasterList: TSectionList; T: TSectionBase);
begin
inherited CreateCopy(AMasterList, T);
HeadingSize := THeadingSpace(T).HeadingSize;
end;

procedure THeadingSpace.CopyToClipboard;
begin
ParentSectionList.CB.AddTextCR('', 0);
end;

procedure THeadingSpace.UpdateSpacing;
var
  SH: integer;
begin
case HeadingSize of    {these are just a guess}
  0: SH := 8;
  1: SH := 16;
  2: SH := 12;
  3: SH := 10;
  4: SH := 8;
  5: SH := 6;
  6: SH := 4;
  else SH := 8;
  end;
SectionHeight := MulDiv(SH, ParentSectionList.FontSize, 12);   {scale to FontSize}
end;

{----------------THorzLine.Create}
constructor THorzLine.Create(AMasterList: TSectionList; L: TAttributeList);
var
  LwName: string[10];
  I: integer;
begin
inherited Create(AMasterList);
VSize := 2;
HWidth := -1;
Align := Centered;
for I := 0 to L.Count-1 do
  with TAttribute(L[I]) do
    case Which of
      SizeSy: if (Value > 0) and (Value <= 20) then
        VSize := Value;
      WidthSy:
        if Value > 0 then
          if Pos('%', Name^) > 0 then
            begin
            if (Value <= 100) then HWidth := Value;
            AsPercent := True;
            end
          else HWidth := Value;
      ColorSy: BkGnd := GetColor(Name^, Color);
      AlignSy:
        begin
        LwName := Lowercase(Name^);
        if LwName = 'left' then Align := Left
        else if LwName = 'right' then Align := Right;
        end;
      NoShadeSy: NoShade := True;
      end;
end;

constructor THorzLine.CreateCopy(AMasterList: TSectionList; T: TSectionBase);
begin
inherited Create(AMasterList);
{$ifdef Windows}
System.Move((T as THorzline).VSize, VSize, Ofs(BkGnd)-Ofs(VSize)+Sizeof(BkGnd));
{$else}
System.Move((T as THorzline).VSize, VSize, DWord(@BkGnd)-DWord(@VSize)+Sizeof(BkGnd));
{$endif}
end;

{----------------THorzLine.UpdateSpacing}
procedure THorzLine.UpdateSpacing;
begin
SectionHeight := MulDiv(20, ParentSectionList.FontSize, 12)
                   -2 + VSize;   {scale to FontSize}
end;

procedure THorzLine.CopyToClipboard;
begin
ParentSectionList.CB.AddTextCR('', 0);
end;

function THorzLine.DrawLogic(Canvas : TCanvas; Y: LongInt; IMgr: IndentManager;
             var MaxWidth: integer; var Curs: LongInt): LongInt;
begin
Result := inherited DrawLogic(Canvas, Y, IMgr, MaxWidth, Curs);
end;

{----------------THorzLine.Draw}
function THorzLine.Draw(Canvas: TCanvas; const ARect: TRect;
     IMgr: IndentManager; X: integer; Y: LongInt) : LongInt;
var
  XR, L, R, W2 : integer;
  YT, YO: LongInt;
  White, BlackBorder: boolean;
begin
Result := inherited Draw(Canvas, ARect, IMgr, X, Y);
YO := Y - ParentSectionList.YOff;
if (YO+SectionHeight >= ARect.Top) and (YO < ARect.Bottom) and
       (not ParentSectionList.Printing or (Y < ParentSectionList.PageBottom)) then
  with Canvas do
    begin
    YT := YO+(SectionHeight - VSize) div 2;
    L := IMgr.LeftIndent(Y);
    R := IMgr.RightSide(Y);
    if HWidth < 0 then
      begin
      X := L+10;
      XR := R - 10;
      end
    else
      begin
      if AsPercent then
        W2 := MulDiv(R-L, HWidth, 100)
      else W2 := HWidth;
      case Align of
        Left: X := L;
        Centered: X := L + (R - L - W2) div 2;
        Right: X := R-W2;
        end;
      XR := X+W2;
      end;
    if BkGnd then
      begin
      Brush.Color := Color or $2000000;
      Brush.Style := bsSolid;
      FillRect(Rect(X, YT, XR, YT+VSize));
      end
    else
      begin
      with ParentSectionList do
        begin
        White := Printing or ((Background and $FFFFFF = clWhite) or
            ((Background = clWindow) and (GetSysColor(Color_Window) = $FFFFFF)));
        BlackBorder := NoShade or (Printing and (GetDeviceCaps(Handle, BITSPIXEL) = 1) and
            (GetDeviceCaps(Handle, PLANES) = 1));
        end;
      if BlackBorder then Pen.Color := clBlack
        else Pen.Color := clBtnShadow;
      MoveTo(X, YT+VSize);
      LineTo(X, YT);
      LineTo(XR, YT);
      if BlackBorder then
        Pen.Color := clBlack
      else if White then
        Pen.Color := clSilver
      else Pen.Color := clBtnHighLight;
      LineTo(XR, YT+VSize);
      LineTo(X, YT+VSize);
      end;
    end;
end;

{----------------TPreFormated.AddText}
procedure TPreFormated.AddText(S : string);
var
  L : integer;
begin
if Length(S) = 0 then Exit;
if Len > 20000 then  Exit;
L := Len+Length(S);
if BuffSize < L+1 then Allocate(L + 100);  {L+1 so there is always extra for font at end}
Move(S[1], (Buff+Len)^, Length(S));
Len := L;
end;

procedure TPreformated.MinMaxWidth(Canvas: TCanvas; var Min, Max: integer);
begin
Max := FindTextWidth(Canvas, Buff, Len, False) + Indent;
Min := IntMin(500, Max);   {arbitrary selection}
end;

function TPreFormated.DrawLogic(Canvas : TCanvas; Y: LongInt; IMgr: IndentManager;
             var MaxWidth: integer; var Curs: LongInt): LongInt;
var
  Dummy: integer;
  Save: integer;
begin
{call with large width to prevent wrapping}
Save := IMgr.Width;
IMgr.Width := 32000;
Result := inherited DrawLogic(Canvas, Y, IMgr, Dummy, Curs);
IMgr.Width := Save;
MinMaxWidth(Canvas, Dummy, MaxWidth);   {return MaxWidth}
end;

{----------------TUListItem.Create}
constructor TUListItem.Create(AMasterList: TSectionList; Level: integer;
            AFont: TMyFont; AnURL: TUrlTarget);
begin
inherited Create(AMasterList, Level, AFont, AnURL, Left);
ListType := Unordered;
end;

constructor TUListItem.CreateCopy(AMasterList: TSectionList; T: TSectionBase);
begin
inherited CreateCopy(AMasterList, T);
Plain := TUListItem(T).Plain;
end;

constructor TDListItem.Create(AMasterList: TSectionList; Level: integer;
                                           AFont: TMyFont; AnURL: TUrlTarget);
begin
inherited Create(AMasterList, Level, AFont, AnURL);  {ancestor is TUListItem}
ListType := Definition;
end;

constructor TOListItem.Create(AMasterList: TSectionList; Level, ItemNumb:integer;
            Index: char; AFont: TMyFont; AnURL: TUrlTarget);
begin
inherited Create(AMasterList, Level, AFont, AnURL);
ListNumb := ItemNumb;
ListType := Ordered;
IndexType := Index;
end;

constructor TOListItem.CreateCopy(AMasterList: TSectionList; T: TSectionBase);
begin
inherited CreateCopy(AMasterList, T);
IndexType := TOListItem(T).IndexType;
end;

type
  TOptionObj = class(TObject)   {used by TListBoxFormControlObj}
    Value: PString;
    Selected: boolean;
  end;

{----------------TListBoxFormControlObj.Create}
constructor TListBoxFormControlObj.Create(AMasterList: TSectionList;
            Position: integer; L: TAttributeList);
var
  T: TAttribute;
  Multiple: boolean;
  PntPanel: TPaintPanel;
begin
inherited Create(AMasterList, Position, L);
TheOptions := TStringList.Create;
Multiple := L.Find(MultipleSy, T);
if L.Find(SizeSy, T) then
  LBSize := T.Value
else LBSize := -1;
Longest := 3;   {the minimum size}
PntPanel := TPaintPanel(AMasterList.PPanel);
FControl := TListBox.Create(PntPanel);
with TListBox(FControl) do
  begin
  Top := -400;   {so will be invisible until placed}
  Font.Name := AMasterList.PreFontName;
  Font.Size := 10;
  MultiSelect := Multiple;
  ExtendedSelect := Multiple;
  OnEnter := EnterEvent;    
  OnExit := ExitEvent;
  end;
PntPanel.InsertControl(FControl);
end;

destructor TListBoxFormControlObj.Destroy;
var
  I: integer;
begin
for I := 0 to TheOptions.Count-1 do
  with TOptionObj(TheOptions.Objects[I]) do
    begin
    DisposeStr(Value);
    Free;
    end;
TheOptions.Free;
inherited Destroy;
end;

procedure TListBoxFormControlObj.Draw(Canvas: TCanvas; X1, Y1: integer);
var
  H2, I: integer;
  LB: TListBox;
begin
LB := FControl as TListBox;  {watch it, TListBox has a canvas too}
FormControlRect(Canvas, X1, Y1, X1+LB.Width, Y1+LB.Height, False);
Canvas.Brush.Style := bsClear;
Canvas.Font := LB.Font;
H2 := Abs(Canvas.Font.Height);
SetTextAlign(Canvas.handle, TA_Left+TA_Top);
for I := LB.TopIndex to IntMin(LB.Items.Count-1, LB.TopIndex+LBSize-1) do
  Canvas.TextRect(Rect(X1+4, Y1+4, X1+LB.Width-8, Y1+LB.Height-8), X1+4,
           Y1+4+(I-LB.TopIndex)*H2, LB.Items[I]);
end;

procedure TListBoxFormControlObj.AddStr(const S, Value: string; Selected: boolean);
var
  Opt: TOptionObj;
begin
Opt := TOptionObj.Create;
Opt.Value := NewStr(Value);
Opt.Selected := Selected;
TheOptions.AddObject(S, Opt);
Longest := IntMax(Longest, Length(S));
end;

procedure TListBoxFormControlObj.ResetToValue;
var
  I: Integer;
  Tmp: boolean;
begin
with (FControl as TListBox) do
  begin
  Clear;
  for I := 0 to TheOptions.Count-1 do
    begin
    Items.Add(TheOptions[I]);
    Tmp := (TheOptions.Objects[I] as TOptionObj).Selected;
    if MultiSelect then
      Selected[I] := Tmp
    else if Tmp then
      ItemIndex := I;
    end;
  if ItemIndex < 0 then
    ItemIndex := 0;
  TopIndex := 0;
  end;
end;

procedure TListBoxFormControlObj.SetHeightWidth(Canvas: TCanvas);
begin
with TListBox(FControl) do
  begin
  Canvas.Font := Font;
  if LBSize = -1 then LBSize := IntMax(1, IntMin(8, TheOptions.Count)); 
  ClientHeight := Canvas.TextHeight('A')*LBSize;
  ClientWidth := Canvas.TextWidth('A')*Longest + 15;
  end;
end;

function TListBoxFormControlObj.GetSubmission(Index: integer;
              var S: string): boolean;
begin
with (FControl as TListBox) do
  if (Index < Items.Count) then
      begin
      Result := True;
      S := '';
      if MultiSelect and Selected[Index] or
                     not MultiSelect and (ItemIndex = Index) then
        begin
        S := Self.Name+'=';
        with TheOptions.Objects[Index] as TOptionObj do
          if Value^ <> '' then S := S + Value^
          else S := S + Items[Index];
        end;
    end
  else Result := False;
end;

{----------------TComboFormControlObj.Create}
constructor TComboFormControlObj.Create(AMasterList: TSectionList;
            Position: integer; L: TAttributeList);
var
  PntPanel: TPaintPanel;
begin
inherited Create(AMasterList, Position, L);
PntPanel := TPaintPanel(AMasterList.PPanel);
PntPanel.RemoveControl(FControl);
FControl.Free;   {don't want the inherited one}
FControl := TComboBox.Create(PntPanel);
with TComboBox(FControl) do
  begin
  Top := -400;   {so will be invisible until placed}
  Font.Name := AMasterList.PreFontName;
  Font.Size := 10;
  Style := csDropDownList;
  OnEnter := EnterEvent;    
  OnExit := ExitEvent;    
  end;
PntPanel.InsertControl(FControl);
end;

procedure TComboFormControlObj.ResetToValue;
var
  I: Integer;
begin
with (FControl as TComboBox) do
  begin
  Clear;
  for I := 0 to TheOptions.Count-1 do
    begin
    Items.Add(TheOptions[I]);
    if (TheOptions.Objects[I] as TOptionObj).Selected then
      ItemIndex := I;
    end;
  if ItemIndex < 0 then
    ItemIndex := 0;
  end;
end;

procedure TComboFormControlObj.Draw(Canvas: TCanvas; X1, Y1: integer);
var
  CB: TComboBox;
begin
CB := FControl as TComboBox;  {watch it, TComboBox has a canvas too}
FormControlRect(Canvas, X1, Y1, X1+CB.Width, Y1+CB.Height, False);
Canvas.Brush.Style := bsClear;
Canvas.Font := CB.Font;
SetTextAlign(Canvas.handle, TA_Left+TA_Top);
Canvas.TextRect(Rect(X1+4, Y1+4, X1+CB.Width-8, Y1+CB.Height-8), X1+4,
           Y1+4, CB.Items[CB.ItemIndex]);
end;

procedure TComboFormControlObj.SetHeightWidth(Canvas: TCanvas);
var
  Wid: integer;
  DC: HDC;
  A: Char;
  ExtS: TSize;
begin
with TComboBox(FControl) do
  begin
  A := 'A';
  DC := GetDC(0);
  {$ifdef Windows}
  Wid := LoWord(GetTextExtent(DC, @A, 1));
  {$else}
  GetTextExtentPoint32(DC, @A, 1, ExtS);
  Wid := ExtS.cx;
  {$endif}
  ReleaseDC(0, DC);
  ClientWidth := Wid * Longest + 30;
  end;
end;

function TComboFormControlObj.GetSubmission(Index: integer;
              var S: string): boolean;
begin
with (FControl as TComboBox) do
  if (Index < Items.Count) then
      begin
      Result := True;
      S := '';
      if ItemIndex = Index then
        begin
        S := Self.Name+'=';
        with TheOptions.Objects[Index] as TOptionObj do
          if Value^ <> '' then S := S + Value^
          else S := S + Items[Index];
        end;
    end
  else Result := False;
end;

{----------------TTextAreaFormControlObj.Create}
constructor TTextAreaFormControlObj.Create(AMasterList: TSectionList;
            Position: integer; L: TAttributeList);
var
  PntPanel: TPaintPanel;
  I: integer;
  Wrap: boolean;
  SB: TScrollStyle;
begin
inherited Create(AMasterList, Position, L);
TheText := TStringList.Create;
Rows := 5;
Cols := 30;
Wrap := False;
SB := ssBoth;

for I := 0 to L.Count-1 do
  with TAttribute(L[I]) do
    case Which of
      RowsSy: Rows := Value;
      ColsSy: Cols := Value;
      WrapSy:
        if (Lowercase(Name^) = 'soft') or (Lowercase(Name^) = 'hard') then
          begin
          SB := ssVertical;
          Wrap := True;
          end;
      end;

PntPanel := TPaintPanel(AMasterList.PPanel);
FControl := TMemo.Create(PntPanel);
with TMemo(FControl) do
  begin
  Top := -400;   {so will be invisible until placed}
  Font.Name := AMasterList.PreFontName;
  Font.Size := 10;
  ScrollBars := SB;
  Wordwrap := Wrap;
  OnKeyDown := MyForm.ControlKeyDown;
  OnEnter := EnterEvent;
  OnExit := ExitEvent;
  end;
PntPanel.InsertControl(FControl);
end;

destructor TTextAreaFormControlObj.Destroy;
begin
TheText.Free;
inherited Destroy;
end;

procedure TTextAreaFormControlObj.Draw(Canvas: TCanvas; X1, Y1: integer);
var
  H2, I: integer;
begin
with TMemo(FControl) do
  begin
  FormControlRect(Canvas, X1, Y1, X1+Width, Y1+Height, False);
  Canvas.Brush.Style := bsClear;
  Canvas.Font := Font;
  H2 := Canvas.TextHeight('A');
  SetTextAlign(Canvas.handle, TA_Left+TA_Top);
  for I := 0 to IntMin(Lines.Count-1, Rows-1) do
    Canvas.TextRect(Rect(X1+4, Y1+4, X1+Width-8, Y1+Height-8), X1+4,
             Y1+4+I*H2, Lines[I]);
  end;
end;

procedure TTextAreaFormControlObj.SetHeightWidth(Canvas: TCanvas);
begin
with TMemo(FControl) do
  begin
  Canvas.Font := Font;
  ClientHeight := Canvas.TextHeight('A')*Rows + 5;
  ClientWidth := Canvas.TextWidth('A')*Cols + 5;
  end;
end;

procedure TTextAreaFormControlObj.AddStr(const S: string);
begin
TheText.Add(S);
end;

procedure TTextAreaFormControlObj.ResetToValue;
begin
with (FControl as TMemo) do
  begin
  Lines := TheText;
  SelStart := 0;
  SelLength := 0;
  end;
end;

function TTextAreaFormControlObj.GetSubmission(Index: integer;
              var S: string): boolean;
var
  I: integer;
begin
if Index = 0 then
  begin
  Result := True;
  S := Name+'=';
  with (FControl as TMemo) do
    for I := 0 to Lines.Count-1 do
      begin
      S := S + Lines[I];
      if (I < Lines.Count-1) and not WordWrap then
        S := S + ^M^J;
      end;
  end
else Result := False;
end;

function TFormControlList.FindControl(Posn: integer): TFormControlObj;
{find the control at a given character position}
var
  I: integer;
begin
for I := 0 to Count-1 do
  if TFormControlObj(Items[I]).Pos = Posn then
    begin
    Result := Items[I];
    Exit;
    end;
Result := Nil;
end;

function TFormControlList.GetHeightAt(Posn: integer;
              var BaseLine: boolean) : Integer;
var
  Ctrl: TFormControlObj;
begin
Ctrl := FindControl(Posn);
if Assigned(Ctrl) then
  begin
  Result := Ctrl.FControl.Height;
  BaseLine := Ctrl.BaseLine;
  end
else Result := -1;
end;

function TFormControlList.GetWidthAt(Posn: integer) : integer;
var
  Ctrl: TFormControlObj;
begin
Ctrl := FindControl(Posn);
if Assigned(Ctrl) then
  Result := Ctrl.FControl.Width
else Result := -1;
end;

function TFormControlList.GetControlCountAt(Posn: integer): integer;
{Return count of chars before the next form control.  0 if at the control,
 9999 if no controls after Posn}
var
  I, Pos: integer;
begin
if Count = 0 then
  begin
  Result := 9999;
  Exit;
  end;
I := 0;
while I < count do
  begin
  Pos := TFormControlObj(Items[I]).Pos;
  if Pos >= Posn then break;
  Inc(I);
  end;
if I = Count then Result := 9999
else
  Result := TFormControlObj(Items[I]).Pos - Posn;
end;

end.

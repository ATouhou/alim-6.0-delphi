{Version 7.01}
{*********************************************************}
{*                     HTMLUN2.PAS                       *}
{*                Copyright (c) 1995-9 by                *}
{*                   L. David Baldwin                    *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$i htmlcons.inc}

unit HTMLUn2;

interface
uses
  {$ifdef Win32}
  Windows,
  {$else}
  WinTypes, WinProcs,
  {$endif}
  SysUtils, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Clipbrd;

const
  VersionNo = '7.01';
  HandCursor = 1;
  ThickIBeamCursor = 2;  

type
  TScriptEvent = procedure(Sender: TObject; const Language: string;
       Script: PChar) of Object;

  TFreeList = class(TList)
  {like a TList but frees it's items.  Use only descendents of TObject}
    destructor Destroy; override;
    {$ifdef Win32}{$Warnings Off}{$endif}     
    procedure Clear;       {do not override}
    end;
    {$ifdef Win32}{$Warnings On}{$endif}

  Transparency = (NotTransp, LLCorner, TGif, TPng);
  JustifyType = (NoJustify, Left, Centered, Right);
  AlignmentType = (Top, Middle, Bottom, ALeft, ARight);

  Symb = (
    HtmlSy, TitleSy, BodySy, HeadSy, PSy, PEndSy, BSy, BEndSy, ISy, IEndSy,
    HtmlEndSy, TitleEndSy, BodyEndSy, HeadEndSy, BRSy, HeadingSy, HeadingEndSy,
    EmSy, EmEndSy, StrongSy, StrongEndSy, USy, UEndSy, HRSy,
    CiteSy, VarSy, CiteEndSy, VarEndSy, BaseSy,
       {Keep order}
    TTSy, CodeSy, KbdSy, SampSy,  TTEndSy, CodeEndSy, KbdEndSy, SampEndSy,
       {end order}
    OLSy, OLEndSy, LISy, ULSy, ULEndSy, DirSy, DirEndSy, MenuSy, MenuEndSy,
    DLSy, DLEndSy, DDSy, DTSy, AddressSy, AddressEndSy, BlockQuoteSy, BlockQuoteEndSy,
    PreSy, PreEndSy, ImageSy, Centersy, CenterEndSy,
    OtherAttribute, ASy, AEndSy, HrefSy, NameSy, SrcSy, AltSy, AlignSy,
    OtherChar, OtherSy, CommandSy, TextSy, EofSy, LinkSy, BGColorSy,
    BackgroundSy, TableSy, TableEndSy, TDSy, TDEndSy, TRSy, TREndSy, THSy, THEndSy,
    ColSpanSy, RowSpanSy, BorderSy, CellPaddingSy, CellSpacingSy, VAlignSy,
    WidthSy, CaptionSy, CaptionEndSy, StartSy, ButtonSy, InputSy, ValueSy,
    TypeSy, CheckBoxSy, RadioSy, FormSy, FormEndSy, MethodSy, ActionSy,
    CheckedSy, SizeSy, MaxLengthSy, TextAreaSy, TextAreaEndSy, ColsSy,
    RowsSy, SelectSy, SelectEndSy, OptionSy, OptionEndSy, SelectedSy,
    MultipleSy, FontSy, FontEndSy, ColorSy, FaceSy, BaseFontSy,
    TranspSy, SubSy, SubEndSy, SupSy, SupEndSy, ClearSy, IsMapSy,
    BigSy, BigEndSy, SmallSy, SmallEndSy, BorderColorSy, MapSy, MapEndSy,
    AreaSy, ShapeSy, CoordsSy, NoHrefSy, UseMapSy, HeightSy, PlainSy,
    FrameSetSy, FrameSetEndSy, FrameSy, TargetSy, NoFramesSy, NoFramesEndSy,
    NoResizeSy, ScrollingSy, PageSy, HSpaceSy, ScriptSy, ScriptEndSy,
    LanguageSy, DivSy, DivEndSy, SSy, SEndSy, StrikeSy, StrikeEndSy,
    FrameBorderSy, MarginWidthSy, MarginHeightSy, BgSoundSy, LoopSy,
    OnClickSy, WrapSy, NoShadeSy, MetaSy, HttpEqSy, ContentSy, EncTypeSy,
    VLinkSy, OLinkSy, ActiveSy, EolSy);   {vl}

  TAttribute = class(TObject)  {holds a tag attribute}
  public
    Which: Symb;     {symbol of attribute such as HrefSy}
    Value: LongInt;  {numeric value if appropriate}
    Percent: boolean;{if value is in percent}
    Name: PString;   {String (mixed case), value after '=' sign}
    constructor Create(ASym: Symb; AValue: LongInt; Const AString: String);
    destructor Destroy; override;
  end;

  TAttributeList = class(TFreeList)  {a list of tag attributes,(TAttributes)}
    public
      function Find(Sy: Symb; var T: TAttribute): boolean;
    end;

  TBitmapItem = class(TObject)
  public
    AccessCount: integer;
    UsageCount: integer;     {how many in use}
    Transp: Transparency;    {identifies what the mask is for}
    MImage: TPersistent;     {main image, bitmap or animated GIF}
    Mask: TBitmap;  {its mask}
    constructor Create(AImage: TPersistent; AMask: TBitmap; Tr: Transparency);
    destructor Destroy; override;
  end;

  TStringBitmapList = class(TStringList)
      {a list of bitmap filenames and TBitmapItems}
  public
    MaxCache: integer;
    constructor Create;
    {$ifdef Win32}
    destructor Destroy; override;
    {$endif}
    procedure Clear; override;
    function AddObject(const S: string; AObject: TObject): Integer; override;
    procedure DecUsage(const S: string);
    procedure IncUsage(const S: string);  
    procedure BumpAndCheck;
    procedure PurgeCache;
    function GetImage(I: integer): TPersistent;
    procedure SetCacheCount(N: integer);
  end;

  SelTextCount = class(TObject)
    Buffer: PChar;
    BufferLeng: LongInt;
    Leng: LongInt;
    procedure AddText(P: PChar; Size: LongInt); virtual;
    procedure AddTextCR(P: PChar; Size: LongInt);
    function Terminate: LongInt; virtual;
    end;

  SelTextBuf = class(SelTextCount)      
    constructor Create(ABuffer: PChar; Size: LongInt);
    procedure AddText(P: PChar; Size: LongInt); override;
    function Terminate: LongInt; override;
    end;

  ClipBuffer = class(SelTextBuf)    
    constructor Create;
    destructor Destroy; override;
    function Terminate: LongInt; override;
    end;

  TUrlTarget = Class(TObject)
    URL,
    Target: PString;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(AnUrl, ATarget: PString);
    procedure Clear;
    end;

  TMapItem = class(TObject)   {holds a client map info}
    MapName: PString;
    Areas: TStringList;       {holds the URL and region handle}
    AreaTargets: TStringList; {holds the target window}
    constructor Create;
    destructor Destroy; override;
    function GetURL(X, Y: integer; var URLTarg: TURLTarget): boolean;
    procedure AddArea(Attrib: TAttributeList);
    end;

  TDib = class(TObject)
    private
      Info  : PBitmapInfoHeader;
      InfoSize: LongInt;
      Image: Pointer;
      ImageSize : Longint;
      FHandle: THandle;
      procedure InitializeBitmapInfoHeader(Bitmap: HBITMAP);
      procedure GetDIBX(DC: HDC; Bitmap: HBITMAP; Palette: HPALETTE);
      procedure Allocate(Size: Longint);
      procedure DeAllocate;
    public
      constructor CreateDIB(DC: HDC; Bitmap: TBitmap);
      destructor Destroy; override;
      function CreateDIBmp: hBitmap;
      procedure DrawDIB(DC: HDC; X: Integer; Y: LongInt; W, H: integer;
             {$ifdef Win32}
                ROP: DWord);
             {$else}
                ROP: LongInt);
             {$endif}
    end;

  IndentRec = Class(TObject)
    X: integer;       {indent for this record}
    YT, YB: LongInt;  {top and bottom Y values for this record}
    Lev: integer;     {list level for this record, 0 for not applicable}
    end;

  IndentManagerBasic = class(TObject)
    Width, ClipWidth: Integer;
    L, R: TFreeList;  {holds info (IndentRec's) on left and right indents}
    CurrentLevel: integer;       {the current list level}
    LfEdge, RtEdge: integer;     {current extreme edges}

    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Reset(Lf, Rt: integer);
    procedure UpdateTable(Y: LongInt; IW: integer; IH: LongInt; Justify: JustifyType);
    function LeftIndent(Y: LongInt): integer;
    function RightSide(Y: LongInt): integer;
    function ImageBottom: LongInt;
    procedure GetClearY(var CL, CR: LongInt);
    procedure SetLevel(Y: LongInt; Level: integer);
    function GetLevelClear: LongInt;
    end;

  AllocRec = Class(TObject)
    Ptr: Pointer;
    ASize: LongInt;
    AHandle: THandle;
    end;

  ImageType = (NoImage, Bmp, Gif, Gif89, Png, Jpg);

var
  ColorBits: Byte;
  ThePalette: HPalette;       {the rainbow palette for 256 colors}
  DefBitMap, ErrorBitMap, ErrorBitmapMask: TBitMap;
  BitmapList: TStringBitmapList; {the image cache}
  WaitStream: TMemoryStream;  

{$ifdef Windows} { for Delphi 1.0 16 bit projects }
procedure SetLength(var S: String; NewLength: Integer);

Function IntMin(A, B : Integer) : Integer;
{returns smallest of two integers}
Inline(
  $5A/                   {Pop dx}
  $58/                   {pop ax}
  $39/$D0/               {cmp ax,dx}
  $7E/$01/               { jle xx}
  $92);                  {xchg ax,dx}
                         {xx:}

Function IntMax(A, B : Integer) : Integer;
{returns largest of two integers}
Inline(
  $5A/                   {Pop dx}
  $58/                   {pop ax}
  $39/$D0/               {cmp ax,dx}
  $7D/$01/               { jge yy}
  $92);                  {xchg ax,dx}
                         {yy:}
{$else}
type
  OpenString = String;

Function IntMin(A, B : Integer) : Integer;
Function IntMax(A, B : Integer) : Integer;
{$endif}

function GetImageFromFile(const Filename: String): TBitmap;
function GetImageAndMaskFromFile(const Filename: String; var Transparent: Transparency;
                            var Mask: TBitmap): TBitmap;
function HTMLToDos(FName: string): string;
  {convert an HTML style filename to one for Dos}
function HTMLServerToDos(FName, Root: string): string;
function Trim(S : String) : String;
{Trims leading and trailing spaces and control chars from string}

procedure WrapText(Canvas: TCanvas; X1, Y1, X2, Y2: integer; S: string);

procedure FinishTransparentBitmap (ahdc: HDC;
            Image, Mask: TBitmap; xStart, yStart, W, H: integer);
function GetImageMask(Image: TBitmap; ColorValid: boolean; AColor: TColor): TBitmap;
function TransparentGIF(const FName: string; var Color: TColor): boolean;
function Allocate(Size: Longint): AllocRec;
procedure DeAllocate(AR: AllocRec);
function CopyPalette(Source: hPalette): hPalette;
procedure SetGlobalPalette(Value: HPalette);
function GetImageAndMaskFromStream(Stream: TMemoryStream;
        var Transparent: Transparency; var Mask: TBitmap): TBitmap;
function KindOfImage(Start: Pointer): ImageType;
procedure FormControlRect(Canvas: TCanvas; X1: integer;
           Y1: LongInt; X2: integer; Y2: LongInt; Raised: boolean);
function GetXExtent(DC: HDC; P: PChar; N: integer): integer;
function IsTransparent(Stream: TStream; var Color: TColor): boolean;
{$ifndef NoDLL}
function GetImageFromStream(Stream: TMemoryStream; Convert: boolean): TBitmap;
{$endif}
procedure RaisedRect(SectionList: TFreeList; Canvas: TCanvas; X1: integer;
           Y1: LongInt; X2: integer; Y2: LongInt; Raised: boolean);

implementation

{$ifdef ver93}
{$Define CppBuilder}
{$endif}
{$ifdef ver110}
{$Define CppBuilder}
{$endif}

uses
{$ifndef NoDll}
  {$ifdef CppBuilder}        {C++Builder}
    {$ifdef ShareWare}
      DLLDemA,
    {$else}
      DLLINTBC,
    {$endif}
  {$else}
    {$ifdef Win32}
      {$ifdef ShareWare}
        DLLDEMA,
      {$else}
        DLLINTa,
      {$endif}
    {$else}
      {$ifdef Windows}
        {$ifdef ShareWare}
          DLLDEMA,   
        {$else}
          DLLINTa,
        {$endif}
      {$endif}
    {$endif}
  {$endif}
{$endif}
{$ifdef windows}
     toconsts,
{$endif}

{$ifdef NoDLL}
  {$ifdef Delphi3_4}
     jpeg,
  {$endif}
{$endIf}
     htmlview, htmlsubs;

{$ifdef NoDLL}
  {$ifdef Delphi3_4}
type                            
  TJpegMod = class(TJpegImage)
  public
    property Bitmap;
  end;
  {$endif}
{$endIf}

var
  DC: HDC;
{$ifndef NoDLL}       
  Dither: byte;
{$endif}

{$IFDEF WINDOWS}
{ for Delphi 1.0 16 bit projects }
procedure SetLength(var S: String; NewLength: Integer);
begin
S[0] := Char(NewLength);
end;
{$ENDIF}

{$ifdef Win32}
Function IntMin(A, B : Integer) : Integer;
begin
  if A < B then Result := A
  else Result := B
end;

Function IntMax(A, B : Integer) : Integer;
begin
  if A > B then Result := A
  else Result := B;
end;
{$endif}

function HTMLServerToDos(FName, Root: string): string;
begin
Result := HTMLToDos(FName);
if (Length(Result) >= 1) and (Result[1] = '\') then
  Result := Root+Result;
end;

function HTMLToDos(FName: string): string;
{convert an HTML style filename to one for Dos}
var
  I: integer;

  procedure Replace(Old, New: char);
  var
    I: integer;
  begin
  I := Pos(Old, FName);
  while I > 0 do
    begin
    FName[I] := New;
    I := Pos(Old, FName);
    end;
  end;

  procedure ReplaceEscapeChars;  
  var
    S: string[3];
    I: integer;
  begin
  I := Pos('%', FName);
  while (I > 1) and (I <= Length(FName)-2) do
    begin
    S := '$'+FName[I+1]+FName[I+2];
    try
      FName[I] := chr(StrToInt(S));
      Delete(FName, I+1, 2);
    except   {ignore exception}
      Exit;
      end;
    I := Pos('%', FName);
    end;
  end;

begin
{$ifdef Windows}
I := Pos('.html', FName);  {change .html to .htm for 16 bits}
if I > 0 then
  System.Delete(FName, I+4, 1);
{$endif}

ReplaceEscapeChars; 
I := pos('/', FName);
if I <> 0 then
  begin
  I := Pos('file:///', Lowercase(FName));
  if I > 0 then
    System.Delete(FName, I, 8)
  else
    begin
    I := Pos('file://', Lowercase(FName));
    if I > 0 then System.Delete(FName, I, 7);
    end;
  Replace('|', ':');
  Replace('/', '\');
  end;
Result := FName;
end;

function Trim(S : String) : String;
{Trims leading and trailing spaces and control chars from string}
var
  I, Len : Integer;
begin
while (Length(S) > 0) and (S[Length(S)] <= ' ') do  SetLength(S, Length(S)-1);
if Length(S) > 0 then
  begin
  I := 1;
  while S[I] <= ' ' do Inc(I);
  if I>1 then
    begin
    Len := Length(S) -I+1;
    Move(S[I], S[1], Len);
    SetLength(S, Len);
    end;
  end;
Trim := S;
end;

procedure WrapText(Canvas: TCanvas; X1, Y1, X2, Y2: integer; S: string);
{Wraps text in a clipping rectangle. Font must be set on entry}
var
  S1, S2: string;
  I, Y, Width, Step: integer;
  ARect: TRect;
begin
with Canvas do
  begin
  ARect := Rect(X1, Y1, X2, Y2);
  Width := X2 - X1;                                
  Y := Y1;
  Step := TextHeight('A');
  SetTextAlign(Canvas.Handle, TA_Top);
  S1 := '';
  while (Length(S) > 0) and (Y+Step <= Y2) do
    begin
    S := Trim(S);   {in case of extra spaces}
    I := Pos(' ', S);
    if I > 0 then
      begin
      S2 := Copy(S, 1, I-1);
      Delete(S, 1, I);
      end
    else
      Begin
      S2 := S;
      S := '';
      end;
    if TextWidth(S1+S2) <= Width then
      begin
      S1 := S1+S2+' ';
      end
    else
      begin
      if S1 <> '' then
        begin
        TextRect(ARect, X1, Y, S1);
        Inc(Y, Step);
        end;
      S1 := S2+' ';
      end;
    end;
  if (S1 <> '') and (Y+Step <= Y2) then
    TextRect(ARect, X1, Y, S1);
  end;
end;

function Allocate(Size: Longint): AllocRec;
begin
Result := AllocRec.Create;
with Result do
  begin
  ASize := Size;
  if Size < $FF00 then
    GetMem(Ptr, Size)
  else
     begin
     AHandle := GlobalAlloc(HeapAllocFlags, Size);
     if AHandle = 0 then
         ABort;
     Ptr := GlobalLock(AHandle);
     end;
  end;
end;

procedure DeAllocate(AR: AllocRec);
begin
with AR do
  if ASize < $FF00 then
    Freemem(Ptr, ASize)
  else
    begin
    GlobalUnlock(AHandle);
    GlobalFree(AHandle);
    end;
AR.Free;
end;

function GetXExtent(DC: HDC; P: PChar; N: integer): integer;
var
  ExtS: TSize;
begin
{$ifdef Windows}
Result := LoWord(GetTextExtent(DC, P, N));
{$else}
GetTextExtentPoint32(DC, P, N, ExtS);
Result := ExtS.cx;
{$endif}
end;

procedure FormControlRect(Canvas: TCanvas; X1: integer;
           Y1: LongInt; X2: integer; Y2: LongInt; Raised: boolean);
{Draws lowered rectangles for form control printing}
var
  OldStyle: TPenStyle;
  OldWid: integer;
  OldBrushStyle: TBrushStyle;
  OldBrushColor: TColor;
  Mono: boolean;
begin
{$ifdef Windows}
if Y1 > 30000 then Y1 := 30000
  else if Y1 < -30000 then Y1 := -30000;
if Y2 > 30000 then Y2 := 30000
  else if Y2 < -30000 then Y2 := -30000;
{$endif}
with Canvas do
  begin
  Mono := (GetDeviceCaps(Handle, BITSPIXEL) = 1) and
          (GetDeviceCaps(Handle, PLANES) = 1);
  Dec(X2);  Dec(Y2);
  OldWid := Pen.Width;
  OldStyle := Pen.Style;
  OldBrushStyle := Brush.Style;   {save style first}
  OldBrushColor := Brush.Color;
  Brush.Color := clWhite;
  Brush.Style := bsSolid;
  FillRect(Rect(X1, Y1, X2, Y2));
  Brush.Color := OldBrushColor;
  Brush.Style := OldBrushStyle;    {style after color as color changes style}

  Pen.Style := psInsideFrame;
  if Mono then
    begin
    Pen.Width := 1;
    Pen.Color := clBlack;
    end
  else
    begin
    Pen.Width := 2;
    if Raised then Pen.Color := clSilver
      else Pen.Color := clBtnShadow;
    end;
  MoveTo(X1, Y2);
  LineTo(X1, Y1);
  LineTo(X2, Y1);
  if not Mono then
    if Raised then Pen.Color := clBtnShadow
      else Pen.Color := clSilver;
  LineTo(X2, Y2);
  LineTo(X1, Y2);
  Pen.Style := OldStyle;
  Pen.Width := OldWid;
  end;
end;

procedure RaisedRect(SectionList: TFreeList; Canvas: TCanvas; X1: integer;
           Y1: LongInt; X2: integer; Y2: LongInt; Raised: boolean);
{Draws raised or lowered rectangles for table borders}
var
  White, BlackBorder: boolean;
begin
{$ifdef Windows}
if Y1 > 30000 then Y1 := 30000
  else if Y1 < -30000 then Y1 := -30000;
if Y2 > 30000 then Y2 := 30000
  else if Y2 < -30000 then Y2 := -30000;
{$endif}
with Canvas do
  begin
  with SectionList as TSectionList do
    begin
    White := Printing or ((Background and $FFFFFF = clWhite) or
        ((Background = clWindow) and (GetSysColor(Color_Window) = $FFFFFF)));  
    BlackBorder := Printing and (GetDeviceCaps(Handle, BITSPIXEL) = 1) and
        (GetDeviceCaps(Handle, PLANES) = 1);    
    end;
  if BlackBorder then
    Pen.Color := clBlack
  else if Raised then
    if White then
      Pen.Color := clSilver
    else Pen.Color := clBtnHighLight
  else Pen.Color := clBtnShadow;

  MoveTo(X1, Y2);
  LineTo(X1, Y1);
  LineTo(X2, Y1);
  if BlackBorder then        
    Pen.Color := clBlack
  else if not Raised then
    if White then
      Pen.Color := clSilver
    else Pen.Color := clBtnHighLight
  else Pen.Color := clBtnShadow;
  LineTo(X2, Y2);
  LineTo(X1, Y2);
  end;
end;

destructor TFreeList.Destroy;
var
  I: integer;
begin
for I := 0 to Count-1 do
  TObject(Items[I]).Free;
inherited Destroy;
end;

procedure TFreeList.Clear;
var
  I: integer;
begin
for I := 0 to Count-1 do
  TObject(Items[I]).Free;
inherited Clear;
end;

constructor TBitmapItem.Create(AImage:TPersistent; AMask: TBitmap; Tr: Transparency);
begin
inherited Create;
MImage := AImage;
Mask := AMask;
AccessCount := 0;
Transp := Tr;
end;

destructor TBitmapItem.Destroy;
begin
MImage.Free;
Mask.Free;
inherited Destroy;
end;

constructor TStringBitmapList.Create;
begin
inherited Create;
MaxCache := 4;
end;

{$ifdef Win32}
destructor TStringBitmapList.Destroy;
var
  I: integer;
begin
for I := 0 to Count-1 do
  (Objects[I] as TBitmapItem).Free;
inherited Destroy;
end;
{$endif}

function TStringBitmapList.AddObject(const S: string; AObject: TObject): Integer;
begin
Result := inherited AddObject(S, AObject);
if AObject is TBitmapItem then
  Inc(TBitmapItem(AObject).UsageCount);
end;

procedure TStringBitmapList.DecUsage(const S: string);
var
  I: integer;
begin
I := IndexOf(S);
if I >= 0 then
  with Objects[I] as TBitmapItem do
    Dec(UsageCount);
end;

procedure TStringBitmapList.IncUsage(const S: string); 
var
  I: integer;
begin
I := IndexOf(S);
if I >= 0 then
  with Objects[I] as TBitmapItem do
    Inc(UsageCount);
end;

procedure TStringBitmapList.SetCacheCount(N: integer);
var
  I: integer;
begin
for I := Count-1 downto 0 do
  with (Objects[I] as TBitmapItem)do
    begin
    if (AccessCount > N) and (UsageCount <= 0) then     
      begin
      Delete(I);
      Free;
      end;
    end;
MaxCache := N;
end;

function TStringBitmapList.GetImage(I: integer): TPersistent;
begin
with Objects[I] as TBitmapItem do
  begin
  Result := MImage;
  AccessCount := 0;
  Inc(UsageCount);
  end;
end;

procedure TStringBitmapList.BumpAndCheck;
var
  I: integer;
  Tmp: TBitmapItem;
begin
  for I := Count-1 downto 0 do
    begin
    Tmp := (Objects[I] as TBitmapItem);
    with Tmp do
      begin
      Inc(AccessCount);
      if (AccessCount > MaxCache) and (UsageCount <= 0) then
        begin
        Delete(I);
        Free;          {the TBitmapItem}
        end;
      end;
    end;
end;

procedure TStringBitmapList.PurgeCache;
var
  I: integer;
  Tmp: TBitmapItem;
begin
for I := Count-1 downto 0 do
  begin
  Tmp := (Objects[I] as TBitmapItem);
  with Tmp do
    begin
    if (UsageCount <= 0) then
      begin
      Delete(I);
      Free;          {the TBitmapItem}
      end;
    end;
  end;
end;

procedure TStringBitmapList.Clear;
var
  I: integer;
begin
for I := 0 to Count-1 do
  (Objects[I] as TBitmapItem).Free;
inherited Clear;
end;

constructor TAttribute.Create(ASym: Symb; AValue: LongInt; Const AString: String);
begin
inherited Create;
Which := ASym;
Value := AValue;
Name := NewStr(AString);
end;

destructor TAttribute.Destroy;
begin
DisposeStr(Name);
inherited Destroy;
end;

{----------------TAttributeList.Find}
function TAttributeList.Find(Sy: Symb; var T: TAttribute): boolean;
var
  I: integer;
begin
for I := 0 to Count-1 do
  if TAttribute(Items[I]).which = Sy then
    begin
    Result := True;
    T := Items[I];
    Exit;
    end;
Result := False;
end;

{----------------TUrlTarget.Create}
constructor TUrlTarget.Create;
begin
inherited Create;
Url := NullStr;
Target := NullStr;
end;

destructor TUrlTarget.Destroy;
begin
DisposeStr(Url);
DisposeStr(Target);
inherited Destroy;
end;

procedure TUrlTarget.Assign(AnUrl, ATarget: PString);
begin
if Assigned(AnUrl) then
  AssignStr(Url, AnUrl^);
if Assigned(ATarget) then
  AssignStr(Target, ATarget^);
end;

procedure TUrlTarget.Clear;
begin
DisposeStr(Url);
Url := NullStr;
DisposeStr(Target);
Target := NullStr;
end;

{----------------SelTextCount}
procedure SelTextCount.AddText(P: PChar; Size: LongInt);    
var
  I: integer;
begin
for I := 0 to Size-1 do
  if not (P[I] in [#2, #4]) then {#4 and #2 used to mark images, form controls}
    Inc(Leng);
end;

procedure SelTextCount.AddTextCR(P: PChar; Size: LongInt);
begin
AddText(P, Size);
AddText(^M^J, 2);
end;

function SelTextCount.Terminate: LongInt;
begin
Result := Leng;  
end;

{----------------SelTextBuf.Create}
constructor SelTextBuf.Create(ABuffer: PChar; Size: LongInt); 
begin
inherited Create;
Buffer := ABuffer;
BufferLeng := Size;
end;

procedure SelTextBuf.AddText(P: PChar; Size: LongInt);    
var
  SizeM1 : LongInt;
  I: integer;
begin
SizeM1 := BufferLeng-1;
for I := 0 to Size-1 do
  if not (P[I] in [#2, #4]) then {#4 and #2 used to mark images, form controls}
    if Leng < SizeM1 then
      begin
      Buffer[Leng] := P[I];
      Inc(Leng);
      end;
end;

function SelTextBuf.Terminate: LongInt;
begin
Buffer[Leng] := #0;
Result := Leng+1;
end;

{----------------ClipBuffer.Create}
constructor ClipBuffer.Create;
begin
inherited Create(Nil, 0);     
BufferLeng := 32500;
Getmem(Buffer, BufferLeng);
end;

destructor ClipBuffer.Destroy;
begin
if Assigned(Buffer) then FreeMem(Buffer, BufferLeng);
inherited Destroy;
end;

function ClipBuffer.Terminate: LongInt;
begin
Buffer[Leng] := #0;
Result := Leng+1;
Clipboard.SetTextBuf(Buffer);
end;

{----------------TMapItem.Create}
constructor TMapItem.Create;
begin
inherited Create;
MapName := NullStr;
Areas := TStringList.Create;
AreaTargets := TStringList.Create;
end;

destructor TMapItem.Destroy;
var
  I: integer;
begin
for I := 0 to Areas.Count-1 do
  DeleteObject(THandle(Areas.Objects[I]));
Areas.Free;
AreaTargets.Free;
DisposeStr(MapName);
inherited Destroy;
end;

function TMapItem.GetURL(X, Y: integer; var URLTarg: TUrlTarget): boolean;
var
  I: integer;
begin
Result := False;
with Areas do
  for I := 0 to Count-1 do
    if PtInRegion(THandle(Objects[I]), X, Y) then
      begin
      if Strings[I] <> '' then  {could be NoHRef}    
        begin
        URLTarg := TUrlTarget.Create;
        AssignStr(URLTarg.URL, Strings[I]);
        AssignStr(URLTarg.Target, AreaTargets[I]);
        Result := True;
        end;
      Exit;
      end;
end;

procedure TMapItem.AddArea(Attrib: TAttributeList);
Const
  MAXCNT = 300;  
var
  I, Cnt, Rad: integer;
  HRef, S, Target: string;
  S1, Nm: string[20];
  Coords: array[0..MAXCNT] of integer;
  Rect: TRect absolute Coords;
  Handle: THandle;
  Shape: (Rec, Circle, Poly);

  procedure GetSubStr;    
  var
    J,K: integer;
  begin
  J := Pos(',', S);
  K := Pos(' ', S);   {for non comma situations (bad syntax)}
  if (J > 0) and ((K = 0) or (K > J)) then
    begin
    S1 := copy(S, 1, J-1);
    Delete(S, 1, J);
    end
  else if K > 0 then
    begin
    S1 := copy(S, 1, K-1);
    Delete(S, 1, K);
    end
  else
    begin
    S1 := Trim(S);
    S := '';
    end;
  while (Length(S) > 0) and ((S[1]=',') or (S[1]=' ')) do
    Delete(S, 1, 1);
  end;

begin
HRef := '';
Target := '';
Shape := Rec;
Cnt := 0;
Handle := 0;
for I := 0 to Attrib.Count-1 do
  with TAttribute(Attrib[I]) do
    case Which of
      HRefSy:  HRef := Name^;
      TargetSy:  Target := Name^;
      NoHrefSy: HRef := '';
      CoordsSy:
        begin
        S := Trim(Name^);
        Cnt := 0;
        GetSubStr;
        while (S1 <> '') and (Cnt <= MAXCNT) do
          begin
          Coords[Cnt] := StrToIntDef(S1, 0);
          GetSubStr;
          Inc(Cnt);
          end;
        end;
      ShapeSy:
        begin
        Nm := copy(Lowercase(Name^),1, 4);
        if Nm = 'circ' then Shape := Circle
        else if (Nm = 'poly') then Shape := Poly;
        end;
      end;
case Shape of
  Rec:
    begin
    if Cnt < 4 then Exit;
    Inc(Coords[2]);
    Inc(Coords[3]);
    Handle := CreateRectRgnIndirect(Rect);
    end;
  Circle:
    begin
    if Cnt < 3 then Exit;
    Rad := Coords[2];
    Dec(Coords[0],Rad);
    Dec(Coords[1],Rad);
    Coords[2] := Coords[0] + 2*Rad +1;
    Coords[3] := Coords[1] + 2*Rad +1;
    Handle := CreateEllipticRgnIndirect(Rect);
    end;
  Poly:
    begin
    if Cnt < 6 then Exit;
    Handle := CreatePolygonRgn(Coords, Cnt div 2, Winding);
    end;
  end;
if Handle <> 0 then
  begin
  Areas.AddObject(HRef, TObject(Handle));
  AreaTargets.Add(Target);
  end;
end;

Function ImageLibCallBack(i : integer) : integer; cdecl; export;
{Callback function from the dll, CDECL and EXPORT ARE REQUIRED}
begin
 if Application.Terminated then begin
   {User wants to terminate the program. Pass a 0 to the dll}
   Result:=0;
  end else begin
  {Be nice to others <g>}
   Application.ProcessMessages;
   {tell the dll that everything is OK}
   Result:=1;
   end;
end;

function KindOfImage(Start: Pointer): ImageType;
type
  ByteArray = array[0..10] of byte;
var
  PB: ^ByteArray absolute Start;
  PW: ^Word absolute Start;
  PL: ^LongInt absolute Start;
begin
if PL^ = $38464947 then
  begin
  if PB^[4] = Ord('9') then Result := Gif89
  else Result := Gif;
  end
else if PW^ = $4D42 then Result := Bmp
else if PL^ = $474E5089 then Result := Png
else if PW^ = $D8FF then Result := Jpg
else Result := NoImage;
end;

function KindOfImageFile(const FName: string): ImageType;
var
  Stream: TFileStream;
  Ar: Array[0..10] of byte;
begin
{Result := NoImage;}                      
Stream := TFileStream.Create(FName, fmShareDenyWrite or FmOpenRead);
try
  Stream.Read(Ar, Sizeof(Ar));
  Result := KindOfImage(@Ar);
finally
  Stream.Free;
  end;
end;

{$ifdef Win32}
{$A-} {record field alignment off for this routine}
{$endif}

function IsTransparent(Stream: TStream; var Color: TColor): boolean;
{Makes some simplifying assumptions that seem to be generally true for single
 images.}
Type
  RGB = record
    Red, Green, Blue: byte;
    end;

  GifHeader = record
    GIF: array[0..2] of char;
    Version: array[0..2] of char;
    ScreenWidth, ScreenHeight: Word;
    Field: Byte;
    BackGroundColorIndex: byte;
    AspectRatio: byte;
    end;
  ColorArray = array[0..255] of RGB;

var
  Header: ^GifHeader;
  X: integer;
  Colors: ^ColorArray;
  Buff: array[0..Sizeof(GifHeader)+Sizeof(ColorArray)+8] of byte;
  P: PChar;
  OldPosition: LongInt;

begin
Result := False;
Fillchar(Buff, Sizeof(Buff), 0);  {in case read comes short}
OldPosition := Stream.Position;
Stream.Position := 0;
Stream.Read(Buff, Sizeof(Buff));
Stream.Position := OldPosition;

Header := @Buff;
if KindOfImage(Header) <> Gif89 then Exit; 
Colors := @Buff[Sizeof(GifHeader)];
with Header^ do
  begin
  X := 1 shl ((Field and 7) +1) - 1;  {X is last item in color table}
  if X = 0 then Exit;   {no main color table}
  end;
P := PChar(Colors)+(X+1)*Sizeof(RGB);
if (P^ <> #$21) or ((P+1)^ <> #$F9) then Exit;  {extension block not found}
if (ord(P[3]) and 1 <> 1) then Exit;     {no transparent color specified}

with Colors^[Ord(P[6])] do
  Color := LongInt(Blue) shl 16 or LongInt(Green) shl 8 or LongInt(Red);
Result := True;
end;

{$ifdef Win32}
{$A+}
{$endif}

{$ifdef Win32}
{$A-} {record field alignment off for this routine}
{$endif}

function IsTransparentPng(Stream: TStream; var Color: TColor): boolean;
Type
  RGB = record
    Red, Green, Blue: byte;
    end;

  PngHeader = record
    width       : LongInt;
    height      : LongInt;
    bitDepth    : byte;
    colorType   : byte;
    compression : byte;
    filter      : byte;
    interlace   : byte;
    end;
var
  Header: PngHeader;
  CRC: LongInt;
  OldPosition: LongInt;
  pngPalette: array[0..255] of RGB;
  dataSize : LongInt;
  chunkType: array[0..4] of Char;
  chunkTypeStr: string;
  done : Boolean;
  Ar: Array[0..10] of byte;

  function IntSwap(data: LongInt): LongInt;
  var
     byte0 : LongInt;
     byte1 : LongInt;
     byte2 : LongInt;
     byte3 : LongInt;
  begin
     byte0 := data and $FF;
     byte1 := (data shr 8) and $FF;
     byte2 := (data shr 16) and $FF;
     byte3 := (data shr 24) and $FF;

     result := (byte0 shl 24) or (byte1 shl 16) or (byte2 shl 8) or byte3;
  end;

begin
result := false;
OldPosition := Stream.Position;

try
   Stream.Position := 0;
   Stream.Read(Ar, 8);

   if KindOfImage(@Ar) <> Png then
     begin
     Stream.Position := OldPosition;
     Exit;
     end;

   Stream.Position := 8; {past the PNG Signature}
   done := False;

{Read Chunks}
   repeat
      Stream.Read(dataSize, 4);
      dataSize := IntSwap(dataSize);
      Stream.Read(chunkType, 4);
      chunkType[4] := #0; {make sure string is NULL terminated}
      chunkTypeStr := StrPas(chunkType);
      if chunkTypeStr = 'IHDR' then
      begin
         Stream.Read(Header, DataSize);
         Header.width := IntSwap(Header.width);
         Header.height := IntSwap(Header.height);
         Stream.Read(CRC, 4); {read it in case we need to read more}
         if (Header.colorType < 2) or (Header.colorType > 3) then
            done := True; {only type 2 and 3 use tRNS}
      end
      else if chunkTypeStr = 'PLTE' then
      begin
         Stream.Read(pngPalette, DataSize);
         Stream.Read(CRC, 4); {read it in case we need to read more}
      end
      else if chunkTypeStr =  'tRNS' then
      begin
         if Header.colorType = 3 then
         begin
            with pngPalette[dataSize - 1] do
               Color := LongInt(Blue) shl 16 or LongInt(Green) shl 8 or LongInt(Red);
         end
         else  {has to have been 2}
         begin
            {for now I am ignoring this since I can't make one}
         end;
         result := true;
         done := true; {got everything we need at this point}
      end
      else if chunkTypeStr = 'IDAT' then
         done := True {if this chunk is hit there is no tRNS}
      else
         Stream.Position := Stream.Position + dataSize + 4; {additional 4 for the CRC}
   until done = True;
except
   end;

Stream.Position := OldPosition;
end;

{$ifdef Win32}
{$A+}
{$endif}

function TransparentGIF(const FName: string; var Color: TColor): boolean;
{Looks at a GIF image file to see if it's a transparent GIF.}
var
  Stream: TFileStream;
begin
Result := False;
try
  Stream := TFileStream.Create(FName, fmShareDenyWrite or FmOpenRead);
  try
    Result := IsTransparent(Stream, Color);
  finally
    Stream.Free;
  end;
except
  end;
end;

function TransparentPNG(const FName: string; var Color: TColor): boolean;
{Looks at a PNG image file to see if it's transparent.}
var
  Stream: TFileStream;
begin
Result := False;
try
  Stream := TFileStream.Create(FName, fmShareDenyWrite or FmOpenRead);
  try
    Result := IsTransparentPng(Stream, Color);
  finally
    Stream.Free;
  end;
except
  end;
end;

function ConvertImage(Bitmap: TBitmap): TBitmap;
{convert bitmap into a form for BitBlt later}
var
  DC: HDC;
  DIB: TDib;
  OldBmp: HBitmap;
  OldPal: HPalette;
  Hnd: HBitmap;
begin
if ColorBits > 8 then  
  begin
  Result := Bitmap;
  Exit;
  end;
if not Assigned(Bitmap) then
  begin
  Result := Nil;
  Exit;
  end;
DC := CreateCompatibleDC(0);
OldBmp := SelectObject(DC, Bitmap.Handle);
OldPal := SelectPalette(DC, ThePalette, False);
RealizePalette(DC);
DIB := TDib.CreateDIB(DC, Bitmap);
Hnd := DIB.CreateDIBmp;
DIB.Free;
SelectPalette(DC, OldPal, False);
SelectObject(DC, OldBmp);
DeleteDC(DC);
Bitmap.Free;
Result := TBitmap.Create;
Result.Handle := Hnd;
if Result.Palette = 0 then 
  Result.Palette := CopyPalette(ThePalette);      
end;

{$ifndef NoDLL}
function GetImageFromStream(Stream: TMemoryStream; Convert: boolean): TBitmap;
var
  IT: ImageType;
  BmpLoaded: boolean;
begin
try
  Result := TBitmap.Create;
  try
    IT := KindOfImage(Stream.Memory);

    if  (IT = Bmp) then
      begin
      try
        BmpLoaded := BmpStream(Stream, ColorBits, Dither, Result, ImageLibCallBack);
      except
        BmpLoaded := True;
        Result.LoadFromStream(Stream);
        end;
      if not BmpLoaded then Result.LoadFromStream(Stream);
      end     
    else if  (IT = Png) and PngStream(Stream, ColorBits, Dither, Result,
             ImageLibCallBack) then
    else if  (IT = Jpg) and JpgStream(Stream, ColorBits, Dither, Result,
             ImageLibCallBack) then
    else
        begin
        Result.Free;
        Result := Nil;
        Exit;
        end;
    if Convert then
      Result := ConvertImage(Result);
  except
    Result.Free;
    Result := Nil;
  end;
except
  Result := Nil;
  end;
end;
{$endif}

function GetImageFromFileInternal(const Filename: String; Convert: boolean): TBitmap;
var
  IT: ImageType;
{$ifndef NoDLL}
  BmpLoaded: boolean;
{$else}
  {$ifdef Delphi3_4}
  jpImage: TJpegMod;      
  {$endif}
{$endif}

begin
try
  Result := TBitmap.Create;
  try
    IT := KindOfImageFile(Filename);

    {$ifndef NoDLL}
      if  (IT = Bmp) then
         begin
         try
           BmpLoaded := BmpFile(Filename, ColorBits, Dither, Result,
                        ImageLibCallBack);
         except
           BmpLoaded := True;
           Result.LoadFromFile(Filename);
           end;
         if not BmpLoaded then Result.LoadFromFile(Filename);
         end
      else if  ((IT = Png) and PngFile(Filename, ColorBits, Dither, Result,
               ImageLibCallBack)) then
      else if  ((IT = Jpg) and JpgFile(Filename, ColorBits, Dither, Result,
               ImageLibCallBack)) then
      else
          begin
          Result.Free;
          Result := Nil;
          Exit;
          end;
    {$else}          {NoDLL}
      if IT = Bmp then
        Result.LoadFromFile(Filename)
      {$ifdef Delphi3_4}
      else if IT = Jpg then
         begin
         jpImage := TJpegMod.Create;
         try
           try
             jpImage.LoadFromFile(Filename);
             if ColorBits <= 8 then
               begin
               jpImage.PixelFormat := jf8bit;
               if not jpImage.GrayScale then
                 jpImage.Palette := CopyPalette(ThePalette);
               end
             else jpImage.PixelFormat := jf24bit;
             Result.Assign(jpImage.Bitmap);
           finally
             jpImage.Free;
             end;
         except
           Result.Free;
           Result := Nil;
           end;
         end
      {$endif}
      else begin Result.Free; Result := Nil; Exit; end;
    {$endif}
    if Convert then
      Result := ConvertImage(Result);
  except
    Result.Free;
    Result := Nil;
  end;
except
  Result := Nil;
  end;
end;

function GetImageFromFile(const Filename: String): TBitmap;
begin
Result := GetImageFromFileInternal(Filename, True);
end;

function GetImageAndMaskFromFile(const Filename: String; var Transparent: Transparency;
                            var Mask: TBitmap): TBitmap;
var
  Color: TColor;
  TmpBmp: TBitmap;
  {$ifndef NoDLL}
  SavePalette: HPalette;
  {$endif}
  Ext: string[10];
begin
Result := Nil;
if not FileExists(Filename) then Exit;
Ext := LowerCase(ExtractFileExt(Filename));
{$ifndef NoGIF}
if (Ext = '.gif') and TransparentGIF(Filename, Color) then
  Transparent := TGif;
{$endif}
if (Ext = '.png') and TransparentPng(Filename, Color) then
  Transparent := TPng;
Mask := Nil;
if Transparent = NotTransp then
  Result := GetImageFromFile(Filename)
else
  begin
  {$ifdef NoDLL}
  TmpBmp := GetImageFromFileInternal(Filename, False);
  {$else}
  SavePalette := GlobalPalette;
  GlobalPalette := 0;   {for mask, want to get undithered image}
  TmpBmp := GetImageFromFileInternal(Filename, False);
  GlobalPalette := SavePalette;
  {$endif}

  if Assigned(TmpBmp) then
    try
      case Transparent of
        {$ifndef NoGIF}
        TGif, Tpng: Mask := GetImageMask(TmpBmp, True, Color);   
        {$else}
        Tpng: Mask := GetImageMask(TmpBmp, True, Color);
        {$endif}
        LLCorner: Mask := GetImageMask(TmpBmp, False, 0);
        end;
      if Assigned(Mask) then
        Result := GetImageFromFile(Filename);  {the dithered image}
    finally
      TmpBmp.Free;
      end;
  end;
end;

{$ifdef NoDll}
function GetImageAndMaskFromStream(Stream: TMemoryStream;
        var Transparent: Transparency; var Mask: TBitmap): TBitmap;
var
  IT: ImageType;
{$ifdef Delphi3_4}
  jpImage: TJpegMod;      
{$endif}
begin
Result := Nil;
Mask := Nil;
if not Assigned(Stream) or (Stream.Memory = Nil) or (Stream.Size < 20) then
  Exit;
Stream.Position := 0;
IT := KindOfImage(Stream.Memory);
if not (IT in [Bmp, Jpg]) then
  Exit;
Result := TBitmap.Create;
try
  {$ifdef Delphi3_4}        
  if IT = Jpg then
    begin
    Transparent := NotTransp;
    jpImage := TJpegMod.Create;
    try
      jpImage.LoadFromStream(Stream);
      if ColorBits <= 8 then
        begin
        jpImage.PixelFormat := jf8bit;
        if not jpImage.GrayScale then
          jpImage.Palette := CopyPalette(ThePalette);
        end
      else jpImage.PixelFormat := jf24bit;
      Result.Assign(jpImage.Bitmap);
    finally
      jpImage.Free;
      end;
    end
  else
    Result.LoadFromStream(Stream);
  {$else}
  Result.LoadFromStream(Stream);
  {$endif}
  if Transparent = LLCorner then
    Mask := GetImageMask(Result, False, 0);
  Result := ConvertImage(Result);
except
  Result.Free;
  Result := Nil;
  end;
end;

{$else}    {not NoDll}

function GetImageAndMaskFromStream(Stream: TMemoryStream;
        var Transparent: Transparency; var Mask: TBitmap): TBitmap;
var
  Color: TColor;
  TmpBmp: TBitmap;
  SavePalette: HPalette;
begin
Result := Nil;
if not Assigned(Stream) or (Stream.Memory = Nil) or (Stream.Size < 20) then
  Exit;
Stream.Position := 0;
if IsTransparent(Stream, Color) then  {check for transparent GIF}
  Transparent := TGif
else if IsTransparentPNG(Stream, Color) then  {check for transparent PNG}
  Transparent := TPng;
Mask := Nil;
if Transparent = NotTransp then
  Result := GetImageFromStream(Stream, True)
else
  begin
  SavePalette := GlobalPalette;
  GlobalPalette := 0;   {for mask, want to get undithered image}
  TmpBmp := GetImageFromStream(Stream, False);
  GlobalPalette := SavePalette;

  if Assigned(TmpBmp) then
    try
      case Transparent of
        TGif, TPng: Mask := GetImageMask(TmpBmp, True, Color);
        LLCorner: Mask := GetImageMask(TmpBmp, False, 0);
        end;
      if Assigned(Mask) then
        Result := GetImageFromStream(Stream, True);  {the dithered image}
    finally
      TmpBmp.Free;
      end;
  end;
end;
{$endif}

function GetImageMask(Image: TBitmap; ColorValid: boolean; AColor: TColor): TBitmap;
var
  TransparentColor: TColor;
  cColor          : TColorRef;
  bmAndObject,
  bmObjectOld     : HBitmap;
  hdcObject,
  hdcTemp,
  DC              : HDC;
  ptSize          : TPoint;
  Pal: HPalette;
begin
DC := GetDC(0);

if ColorValid then
  TransparentColor := AColor  {color has already been selected}
else
  {set the transparent color to be the lower left pixel of the bitmap}
  TransparentColor := Image.Canvas.Pixels[0, Image.Height - 1];

TransparentColor := TransparentColor or $02000000;

hdcTemp := CreateCompatibleDC(DC);
SelectObject (hdcTemp, Image.Handle); { select the bitmap }

{ convert bitmap dimensions from device to logical points}
ptSize.x := Image.Width;
ptSize.y := Image.Height;
DPtoLP (hdcTemp, ptSize, 1);  { convert from device logical points }

{ create some DCs to hold temporary data}
hdcObject := CreateCompatibleDC(DC);

{ create a bitmap for each DC}
{ monochrome DC}
bmAndObject := CreateBitmap (ptSize.x, ptSize.y, 1, 1, nil);

{ each DC must select a bitmap object to store pixel data}
bmObjectOld := SelectObject (hdcObject, bmAndObject);

{ set proper mapping mode}
SetMapMode (hdcTemp, GetMapMode(DC));

{ set the background color of the source DC to the color.
  contained in the parts of the bitmap that should be transparent}
Pal := Image.Palette;
SelectPalette(hdcTemp, Pal, False);
RealizePalette(hdcTemp);
cColor := SetBkColor (hdcTemp, TransparentColor);

{ create the object mask for the bitmap by performing a BitBlt()
  from the source bitmap to a monochrome bitmap}
BitBlt (hdcObject, 0, 0, ptSize.x, ptSize.y, hdcTemp, 0, 0, SRCCOPY);

{ set the background color of the source DC back to the original color}
SetBkColor (hdcTemp, cColor);

{Save the Object bitmap}
try
  Result := TBitmap.Create;
  try
    Result.Handle := bmAndObject;
  except
    Result.Free;
    Raise;
  end;
except
  Result := Nil;
end;

{ delete the memory bitmaps}
SelectObject (hdcObject, bmObjectOld);

{ delete the memory DCs}
DeleteDC (hdcObject);
DeleteDC (hdcTemp);
ReleaseDC(0, DC);
end;

{----------------FinishTransparentBitmap }
procedure FinishTransparentBitmap (ahdc: HDC;
              Image, Mask: TBitmap; xStart, yStart, W, H: integer);
var
  bmAndBack,
  bmSave,
  bmBackOld,
  bmObjectOld,
  bmSaveOld       : HBitmap;
  hdcInvMask,
  hdcMask,
  hdcImage,
  hdcSave         : HDC;
  DestSize, SrcSize : TPoint;
  OldBack, OldFore: TColor;
  {$ifdef Windows}
  BM: WinTypes.TBitmap;
  {$else}
  BM: Windows.TBitmap;
  {$endif}

begin
hdcImage := CreateCompatibleDC (ahdc);
SelectObject (hdcImage, Image.Handle); { select the bitmap }

{ convert bitmap dimensions from device to logical points}
SrcSize.x := Image.Width;
SrcSize.y := Image.Height;
DPtoLP(hdcImage, SrcSize, 1);

DestSize.x := W;
DestSize.y := H;
DPtoLP (hdcImage, DestSize, 1);

{ create a bitmap for each DC}
{ monochrome DC}
bmAndBack   := CreateBitmap (SrcSize.x, SrcSize.y, 1, 1, nil);

bmSave      := CreateCompatibleBitmap (ahdc, DestSize.x, DestSize.y);
GetObject(bmSave, SizeOf(BM), @BM);
if (BM.bmBitsPixel > 1) or (BM.bmPlanes > 1) then
  begin
  { create some DCs to hold temporary data}
  hdcInvMask   := CreateCompatibleDC(ahdc);
  hdcMask := CreateCompatibleDC(ahdc);
  hdcSave   := CreateCompatibleDC(ahdc);

  { each DC must select a bitmap object to store pixel data}
  bmBackOld   := SelectObject (hdcInvMask, bmAndBack);
  bmSaveOld   := SelectObject (hdcSave, bmSave);

  { set proper mapping mode}
  SetMapMode (hdcImage, GetMapMode (ahdc));

  { save the bitmap sent here, because it will be overwritten}
  BitBlt (hdcSave, 0, 0, DestSize.x, DestSize.y, hdcImage, 0, 0, SRCCOPY);

  bmObjectOld := SelectObject(hdcMask, Mask.Handle);

  { create the inverse of the object mask}
  BitBlt (hdcInvMask, 0, 0, SrcSize.x, SrcSize.y, hdcMask, 0, 0, NOTSRCCOPY);

  {set the background color of the source DC to the color contained in the
   parts of the bitmap that should be transparent, the foreground to the parts that
   will show}
  OldBack := SetBkColor(ahDC, clWhite);
  OldFore := SetTextColor(ahDC, clBlack);

  { Punch out a black hole in the background where the image will go}
  SetStretchBltMode(ahDC, WhiteOnBlack);
  StretchBlt (ahDC, XStart, YStart, DestSize.x, DestSize.y, hdcMask, 0, 0, SrcSize.x, SrcSize.y, SRCAND);

  { mask out the transparent colored pixels on the bitmap}
  BitBlt (hdcImage, 0, 0, SrcSize.x, SrcSize.y, hdcInvMask, 0, 0, SRCAND);

  { XOR the bitmap with the background on the destination DC}
  SetStretchBltMode(ahDC, ColorOnColor);
  StretchBlt(ahDC, XStart, YStart, W, H, hdcImage, 0, 0, Image.Width, Image.Height, SRCPAINT);

  { place the original bitmap back into the bitmap sent here}
  BitBlt (hdcImage, 0, 0, DestSize.x, DestSize.y, hdcSave, 0, 0, SRCCOPY);

  SetBkColor(ahDC, OldBack);
  SetTextColor(ahDC, OldFore);

  { delete the memory bitmaps}
  DeleteObject (SelectObject (hdcInvMask, bmBackOld));
  SelectObject (hdcMask, bmObjectOld);
  DeleteObject (SelectObject (hdcSave, bmSaveOld));

  { delete the memory DCs}
  DeleteDC (hdcInvMask);
  DeleteDC (hdcMask);
  DeleteDC (hdcSave);
  end
else
  begin
  DeleteObject(bmAndBack);
  DeleteObject(bmSave);
  end;
DeleteDC (hdcImage);
end;

{----------------TDib.CreateDIB}
constructor TDib.CreateDIB(DC: HDC; Bitmap: TBitmap);
{given a TBitmap, construct a device independent bitmap}
var
  {$ifdef Win32}
  ImgSize: DWord;
  {$else}
  ImgSize: LongInt;
  {$endif}
begin
InitializeBitmapInfoHeader(Bitmap.Handle);
ImgSize := Info^.biSizeImage;
Allocate(ImgSize);
try
  GetDIBX(DC, Bitmap.Handle, Bitmap.Palette);
except
  DeAllocate;
  Raise;
  end;
end;

destructor TDib.Destroy;
begin
DeAllocate;
inherited Destroy;
end;

procedure TDib.Allocate(Size: Longint);
begin
ImageSize := Size;
if Size < $FF00 then
  GetMem(Image, Size)
else
   begin
   FHandle := GlobalAlloc(HeapAllocFlags, Size);
   if FHandle = 0 then
       ABort;
   Image := GlobalLock(FHandle);
   end;
end;

procedure TDib.DeAllocate;
begin
if ImageSize > 0 then
  begin
  if ImageSize < $FF00 then
    Freemem(Image, ImageSize)
  else
    begin
    GlobalUnlock(FHandle);
    GlobalFree(FHandle);
    end;
  ImageSize := 0;
  end;
if InfoSize > 0 then
  begin
  FreeMem(Info, InfoSize);
  InfoSize := 0;
  end;
end;

procedure TDib.InitializeBitmapInfoHeader(Bitmap: HBITMAP);
var
  {$ifdef Win32}
  BM: Windows.TBitmap;
  {$else}
  BM: WinTypes.TBitmap;
  {$endif}
  BitCount: integer;

   function WidthBytes(I: Longint): Longint;
   begin
     Result := ((I + 31) div 32) * 4;
   end;

begin
GetObject(Bitmap, SizeOf(BM), @BM);
BitCount := BM.bmBitsPixel * BM.bmPlanes;
if BitCount > 8 then
  InfoSize := SizeOf(TBitmapInfoHeader)
else
  InfoSize := SizeOf(TBitmapInfoHeader) + SizeOf(TRGBQuad) * (1 shl BitCount);  
GetMem(Info, InfoSize);

with Info^ do
  begin
  biSize := SizeOf(TBitmapInfoHeader);
  biWidth := BM.bmWidth;
  biHeight := BM.bmHeight;
  biBitCount := BM.bmBitsPixel * BM.bmPlanes;
  biPlanes := 1;
  biXPelsPerMeter := 0;
  biYPelsPerMeter := 0;
  biClrUsed := 0;
  biClrImportant := 0;
  biCompression := BI_RGB;
  if biBitCount in [16, 32] then
    biBitCount := 24;
  biSizeImage := WidthBytes(biWidth * biBitCount) * biHeight;
  end;
end;

procedure TDib.GetDIBX(DC: HDC; Bitmap: HBITMAP; Palette: HPALETTE);
var
  OldPal: HPALETTE;
  Rslt: integer;
  bmInfo: PBitmapInfo;
begin
  OldPal := 0;
  if Palette <> 0 then
    begin
    OldPal := SelectPalette(DC, Palette, False);
    RealizePalette(DC);
    end;
  bmInfo := PBitmapInfo(Info);
  Rslt := GetDIBits(DC, Bitmap, 0, Info^.biHeight, Image, bmInfo^, DIB_RGB_COLORS);
  if OldPal <> 0 then
    SelectPalette(DC, OldPal, False);
  if Rslt = 0 then
    begin
    if DC = 0 then
      BitmapList.PurgeCache;
    OutofMemoryError;
    end;
end;

procedure TDib.DrawDIB(DC: HDC; X: Integer; Y: LongInt; W, H: integer;
       {$ifdef Win32}
          ROP: DWord);
       {$else}
          ROP: LongInt);
       {$endif}
var
  bmInfo: PBitmapInfo;
begin
bmInfo := PBitmapInfo(Info);
with Info^ do
  StretchDIBits(DC, X, Y, W, H, 0, 0, biWidth, biHeight, Image,
      bmInfo^, DIB_RGB_COLORS, ROP);
end;

function TDib.CreateDIBmp: hBitmap;
var
  bmInfo: PBitmapInfo;
  DC: HDC;
  OldPal: HPalette;
begin
bmInfo := PBitmapInfo(Info);
DC := GetDC(0);
OldPal := SelectPalette(DC, ThePalette, False);
RealizePalette(DC);
try
  Result := CreateDIBitmap(DC, bmInfo^.bmiHeader, CBM_INIT, Image,
            bmInfo^, DIB_RGB_COLORS);
finally
  SelectPalette(DC, OldPal, False);
  ReleaseDC(0, DC);
  end;
end;

{----------------IndentManagerBasic.Create}
constructor IndentManagerBasic.Create;
begin
inherited Create;
R := TFreeList.Create;
L := TFreeList.Create;
end;

destructor IndentManagerBasic.Destroy;
begin
R.Free;
L.Free;
inherited Destroy;
end;

procedure IndentManagerBasic.Clear;
begin
R.Clear;
L.Clear;
end;

{----------------IndentManagerBasic.Reset}
procedure IndentManagerBasic.Reset(Lf, Rt: integer);
begin
LfEdge := Lf;
RtEdge := Rt;
CurrentLevel := 0;
end;

procedure IndentManagerBasic.UpdateTable(Y: LongInt; IW: integer; IH: LongInt;
                           Justify: JustifyType);
{Given a floating table, update the edge information. }
var
  IR: IndentRec;
begin
  IR := IndentRec.Create;
  if (Justify = Left) then
    begin
    with IR do
      begin
      X := LeftIndent(Y)-LfEdge + IW;
      YT := Y;
      YB := Y + IH;
      Lev := 0;
      L.Add(IR);
      end;
    end
  else if (Justify = Right) then
    begin
    with IR do
      begin
      X := RightSide(Y) - RtEdge - IW;
      YT := Y;
      YB := Y + IH;
      Lev := 0;
      R.Add(IR);
      end;
    end;
end;

function IndentManagerBasic.LeftIndent(Y: LongInt): integer;
var
  I: integer;
begin
Result := 0;
for I := 0 to L.Count-1 do
  with IndentRec(L.Items[I]) do
    begin
    if (Y >= YT) and (Y < YB) and (Result < X) then   
      Result := X;
    end;
Inc(Result, LfEdge);
end;

function IndentManagerBasic.RightSide(Y: LongInt): integer;
{returns the current right side dimension as measured from the left, a positive
 number}
var
  I: integer;
begin
Result := 0;
for I := 0 to R.Count-1 do
  with IndentRec(R.Items[I]) do
    if (Y >= YT) and (Y < YB) and (Result > X) then   
      Result := X;
Inc(Result, RtEdge);
end;

function IndentManagerBasic.ImageBottom: LongInt;
{finds the bottom of the last floating image}
var
  I: integer;
begin
Result := 0;
for I := 0 to L.Count-1 do
  with IndentRec(L.Items[I]) do
    if (lev = 0) and (YB > Result) then
      Result := YB;
for I := 0 to R.Count-1 do
  with IndentRec(R.Items[I]) do
    if (lev = 0) and (YB > Result) then
      Result := YB;
end;

procedure IndentManagerBasic.GetClearY(var CL, CR: LongInt);
{returns the left and right Y values which will clear image margins}
var
  I: integer;
begin
CL := -1;
for I := 0 to L.Count-1 do
  with IndentRec(L.Items[I]) do
    if (Lev = 0) and (YB > CL) then
      CL := YB;
CR := -1;
for I := 0 to R.Count-1 do
  with IndentRec(R.Items[I]) do
    if (Lev = 0) and (YB > CR) then
      CR := YB;
Inc(CL);
Inc(CR);
end;

function IndentManagerBasic.GetLevelClear: LongInt;
{returns the left value which will clear image at this level}
var
  I, CurrentLevelIndent: integer;
begin
CurrentLevelIndent := 0;
for I := 0 to L.Count-1 do
  with IndentRec(L.Items[I]) do
    if Lev = CurrentLevel then
      CurrentLevelIndent := X;
Result := 0;
for I := 0 to L.Count-1 do
  with IndentRec(L.Items[I]) do
    if (X > CurrentLevelIndent) and (YB > Result) then
      Result := YB;
Inc(Result);
end;

procedure IndentManagerBasic.SetLevel(Y: LongInt; Level: integer);
var
  I: integer;
  IR: IndentRec;
begin
if Level > CurrentLevel then
  begin
  for I := CurrentLevel+1 to Level do   {in case we skip a level}
    begin
    IR := IndentRec.Create;
    with IR do
      begin
      Lev := I;
      YT := Y;
      YB := 9999999;  {replace with actual value when we know it}
      X := LeftIndent(Y)-LfEdge + ListIndent;
      end;
    L.Add(IR);
    end;
  CurrentLevel := Level;
  end
else if (Level < CurrentLevel) and (CurrentLevel > 0) then
  begin
  for I := 0 to L.Count-1 do
    with IndentRec(L.Items[I]) do
      if Lev > Level then
        begin
        Lev := 0;
        YB := Y-1;   {replace the 9999999 with actual end}
        end;
  CurrentLevel := Level;
  end;
end;

procedure SetGlobalPalette(Value: HPalette);
begin
{$ifndef NoDLL}
GlobalPalette := Value;
{$endif}
end;

function CopyPalette(Source: hPalette): hPalette;
var
  LP: ^TLogPalette;
  NumEntries: integer;
begin
Result := 0;
GetMem(LP, Sizeof(TLogPalette) + 256*Sizeof(TPaletteEntry));
try
  with LP^ do
    begin
    palVersion := $300;
    palNumEntries := 256;
    NumEntries := GetPaletteEntries(Source, 0, 256, palPalEntry);
    if NumEntries > 0 then
      begin
      palNumEntries := NumEntries;
      Result := CreatePalette(LP^);
      end;
    end;
finally
  FreeMem(LP, Sizeof(TLogPalette) + 256*Sizeof(TPaletteEntry));
  end;
end;

procedure CalcPalette(DC: HDC);
{calculate a rainbow palette, one with equally spaced colors}
const
  Values: array[0..5] of integer = (55, 115, 165, 205, 235, 255);
var
  LP: ^TLogPalette;
  I, J, K, Sub: integer;
begin
GetMem(LP, Sizeof(TLogPalette) + 256*Sizeof(TPaletteEntry));
try
  with LP^ do
    begin
    palVersion := $300;
    palNumEntries := 256;
    GetSystemPaletteEntries(DC, 0, 256, palPalEntry);
    Sub := 10;  {start at entry 10}
    for I := 0 to 5 do
      for J := 0 to 5 do
        for K := 0 to 5 do
          if not ((I=5) and (J=5) and (K=5)) then  {skip the white}
            with palPalEntry[Sub] do
              begin
              peBlue := Values[I];
              peGreen := Values[J];
              peRed := Values[K];
              peFlags := 0;
              Inc(Sub);
              end;
    for I := 1 to 24 do
          with palPalEntry[Sub] do
            begin
            peBlue := 130 + 5*I;
            peGreen := 130 + 5*I;
            peRed := 130 + 5*I;
            peFlags := 0;
            Inc(Sub);
            end;
    ThePalette := CreatePalette(LP^);
    {$ifndef NoDLL}
    GlobalPalette := ThePalette;
    {$endif}
    end;
finally
  FreeMem(LP, Sizeof(TLogPalette) + 256*Sizeof(TPaletteEntry));
  end;
end;

const
  DefaultBitmap = 1002;
  ErrBitmap = 1001;
  ErrBitmapMask = 1005;
  Hand_Cursor = 1003;
  ThickIBeam_Cursor = 1006;  

procedure ThisExit; far;
begin
if ThePalette <> 0 then
  DeleteObject(ThePalette);
DefBitMap.Free;
ErrorBitMap.Free;
ErrorBitMapMask.Free;   
BitmapList.Free;
WaitStream.Free;   
end;

initialization
DC := GetDC(0);
try
{$ifdef NoDLL}
  ColorBits := GetDeviceCaps(DC, BitsPixel)*GetDeviceCaps(DC, Planes);

  if ColorBits <= 4 then
    ColorBits := 4
  else if ColorBits <= 8 then
    ColorBits := 8
  else  ColorBits := 24;
{$else}
  ColorBits := GetDeviceRes(DC);
{$endif}

{$ifndef NoDLL}
  Dither := 1;
{$endif}

  ThePalette := 0;
  if ColorBits = 8 then
    CalcPalette(DC);
finally
  ReleaseDC(0, DC);
  end;

{$ifndef NoDLL}
ShowErrorInDLL := 0;     {set to 1 to show image error messages}  
{$endif}

DefBitMap := TBitmap.Create;
DefBitMap.Handle := LoadBitmap(HInstance, MakeIntResource(DefaultBitmap));
ErrorBitMap := TBitmap.Create;
ErrorBitMap.Handle := LoadBitmap(HInstance, MakeIntResource(ErrBitmap));
ErrorBitMapMask := TBitmap.Create;
ErrorBitMapMask.Handle := LoadBitmap(HInstance, MakeIntResource(ErrBitmapMask));
Screen.Cursors[HandCursor] := LoadCursor(HInstance, MakeIntResource(Hand_Cursor));
Screen.Cursors[ThickIBeamCursor] := LoadCursor(HInstance, MakeIntResource(ThickIBeam_Cursor));
BitmapList := TStringBitmapList.Create;
BitmapList.Sorted := True;

WaitStream := TMemoryStream.Create;

{$ifdef Windows}
AddExitProc(ThisExit);
{$else}
Finalization
ThisExit;
{$endif}
end.



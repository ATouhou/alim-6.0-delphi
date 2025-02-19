{Version 7.01}
{*********************************************************}
{*                     FRAMBRWZ.PAS                      *}
{*                Copyright (c) 1997-9 by                *}
{*                   L. David Baldwin                    *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$i htmlcons.inc}

unit FramBrwz;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Menus, htmlsubs, htmlview, htmlun2,
  readHTML, dsgnintf, FramView;

type
  TGetPostRequestEvent = procedure(Sender: TObject; IsGet: boolean; const URL, Query: string;
                       Reload: boolean; var NewURL: string; var DocType: TFileType; var Stream: TMemoryStream) of Object;

  TbrFrameSet = class;
  TbrSubFrameSet = class;

  TbrFrameBase = class(TCustomPanel)   {base class for other classes}
    MasterSet: TbrFrameSet;   {Points to top (master) TbrFrameSet}
  private
    URLBase: string;
    UnLoaded: boolean;
    procedure UpdateFrameList; virtual; abstract;
  protected
    {$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
    LocalCharSet: TFontCharset;       
    {$endif}
    procedure FVMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); virtual; abstract;
    procedure FVMouseMove(Sender: TObject; Shift: TShiftState; X,
           Y: Integer); virtual; abstract;
    procedure FVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); virtual; abstract;
    function CheckNoResize(var Lower, Upper: boolean): boolean; virtual; abstract;
    procedure LoadBrzFiles; virtual; abstract;
    procedure ReLoadFiles(APosition: LongInt); virtual; abstract;
    procedure UnloadFiles; virtual; abstract;

  public
    LOwner: TbrSubFrameSet;
    procedure InitializeDimensions(X, Y, Wid, Ht: integer); virtual; abstract;
  end;

  TbrFrame = class(TbrFrameBase) {TbrFrame holds a ThtmlViewer or TbrSubFrameSet}
  protected
    NoScroll: boolean;
    MarginHeight, MarginWidth: integer;
    frHistory: TStringList;
    frPositionHistory: TFreeList;
    frHistoryIndex: integer;
    RefreshTimer: TTimer;     
    NextFile: string;      

    procedure CreateViewer;
    procedure frBumpHistory(const NewName: string; NewPos, OldPos: LongInt);
    procedure frBumpHistory1(const NewName: string; Pos: LongInt);
    procedure frSetHistoryIndex(Value: integer);
    procedure UpdateFrameList; override;
    procedure RefreshEvent(Sender: TObject; Delay: integer; const URL: string);
    procedure RefreshTimerTimer(Sender: TObject);

  protected
    procedure FVMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure FVMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer); override;
    procedure FVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function CheckNoResize(var Lower, Upper: boolean): boolean; override;
    procedure ReLoadFiles(APosition: LongInt); override;
    procedure UnloadFiles; override;
    procedure LoadBrzFiles; override;
    procedure frLoadFromBrzFile(const URL, Dest, Query: string; Bump, IsGet, Reload: boolean);
    procedure ReloadFile(const FName: string; APosition: LongInt);
    procedure URLExpandName(Sender: TObject; const SRC: string; var Rslt: string); 
  public
    Viewer: ThtmlViewer;    {the ThtmlViewer it holds if any}
    ViewerPosition: LongInt;
    FrameSet: TbrSubFrameSet; {or the TbrSubFrameSet it holds}
    Source,         {Dos filename or URL for this frame}
    Destination: PString;    {Destination offset for this frame}
    TheStream: TMemoryStream;   
    TheStreamType: TFileType;   
    WinName: PString;     {window name, if any, for this frame}
    NoReSize: boolean;

    constructor CreateIt(AOwner: TComponent; L: TAttributeList;
              Master: TbrFrameSet; const Path: string);
    destructor Destroy; override;
    procedure InitializeDimensions(X, Y, Wid, Ht: integer); override;
    procedure RePaint; override;
  end;

  TbrSubFrameSet = class(TbrFrameBase)  {can contain one or more TbrFrames and/or TSubFrameSets}
  protected
    FBase: PString;
    FBaseTarget: PString;
    OuterBorder: integer;
    BorderSize: integer;
    FRefreshURL: string;
    FRefreshDelay: integer;
    RefreshTimer: TTimer;
    NextFile: string;

    procedure ClearFrameNames;
    procedure AddFrameNames;
    procedure UpdateFrameList; override;
    procedure HandleMeta(Sender: TObject; const HttpEq, Name, Content: string);
    procedure SetRefreshTimer;
    procedure RefreshTimerTimer(Sender: Tobject); virtual;
  protected
    OldRect: TRect;
    function GetRect: TRect;
    procedure FVMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure FVMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer); override;
    procedure FVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure FindLineAndCursor(Sender: TObject; X, Y: integer);
    function NearBoundary(X, Y: integer): boolean;
    function CheckNoResize(var Lower, Upper: boolean): boolean; override;
    procedure Clear; virtual;

  public
    First: boolean;     {First time thru}
    Rows: boolean;          {set if row frameset, else column frameset}
    List: TFreeList;   {list of TbrFrames and TSubFrameSets in this TbrSubFrameSet}
    Dim,    {col width or row height as read.  Blanks may have been added}
    DimF,   {col width or row height in pixels as calculated and displayed}
    Lines   {pixel pos of lines, Lines[1]=0, Lines[DimCount]=width|height}
         : array[0..20] of SmallInt;
    Fixed   {true if line not allowed to be dragged}
         : array[0..20] of boolean;
    DimCount: integer;
    DimFTot: integer;
    LineIndex: integer;

    constructor CreateIt(AOwner: TComponent; Master: TbrFrameSet);
    destructor Destroy; override;
    function AddFrame(Attr: TAttributeList; const FName: string): TbrFrame;
    procedure EndFrameSet; virtual;
    procedure DoAttributes(L: TAttributeList);
    procedure LoadBrzFiles; override;
    procedure ReLoadFiles(APosition: LongInt); override;
    procedure UnloadFiles; override;
    procedure InitializeDimensions(X, Y, Wid, Ht: integer); override;
    procedure CalcSizes(Sender: TObject);
  end;

  TFrameBrowser = class;

  TbrFrameSet = class(TbrSubFrameSet)  {only one of these showing, others may be held as History}
  protected
    FTitle: PString;
    FCurrentFile: PString;
    FrameNames: TStringList; {list of Window names and their TFrames}
    Viewers: TList;   {list of all ThtmlViewer pointers}
    Frames: TList;    {list of all the Frames contained herein}
    HotSet: TbrFrameBase;     {owner of line we're moving}
    OldWidth, OldHeight: integer;
    NestLevel: integer;
    FActive: ThtmlViewer;   {the most recently active viewer}

    procedure ClearForwards;
    procedure UpdateFrameList; override;
    procedure RefreshTimerTimer(Sender: Tobject); override; 

  protected
    procedure FVMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer); override;
    procedure CheckActive(Sender: TObject);
    function GetActive: ThtmlViewer;
  public
    FrameViewer: TFrameBrowser;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EndFrameSet; override;
    procedure LoadFromBrzFile(Stream: TMemoryStream; StreamType: TFileType;
                const URL, Dest: string);
    procedure Clear; override;
    procedure CalcSizes(Sender: TObject);
    procedure RePaint; override;
  end;

  TFrameBrowser = class(TFVBase)
  protected
    FPosition: TList;
    FHistoryIndex: integer;
    FOnGetPostRequest: TGetPostRequestEvent;
    FOnImageRequest: TGetImageEvent;
    FOptions: TFrameViewerOptions;
    FOnViewerClear: TNotifyEvent;

    FBaseEx: PString;

    function GetBase: string;
    procedure SetBase(Value: string);
    function GetBaseTarget: string;
    function GetTitle: string;
    function GetCurrentFile: string;
    procedure HotSpotCovered(Sender: TObject; const SRC: string);
    procedure SetHistoryIndex(Value: integer);

    procedure ChkFree(Obj: TObject);
    function GetActiveTarget: string;
    function GetFwdButtonEnabled: boolean;
    function GetBackButtonEnabled: boolean;
    procedure SetOnImageRequest(const Value: TGetImageEvent);
    procedure SetOptions(Value: TFrameViewerOptions);

  protected
    CurbrFrameSet: TbrFrameSet;  {the TbrFrameSet being displayed}

    function GetCurViewerCount: integer; override;
    function GetCurViewer(I: integer): ThtmlViewer; override;
    function GetActiveViewer: ThtmlViewer;  override;


    procedure BumpHistory(OldFrameSet: TbrFrameSet; OldPos: LongInt);
    procedure BumpHistory1(const FileName, Title: string;
                 OldPos: LongInt; ft: TFileType);
    procedure BumpHistory2(OldPos: LongInt);
    function HotSpotClickHandled(const FullUrl: string): boolean;

    procedure AddFrame(FrameSet: TObject; Attr: TAttributeList; const FName: string); override;
    function CreateSubFrameSet(FrameSet: TObject): TObject; override;
    procedure DoAttributes(FrameSet: TObject; Attr: TAttributeList); override;
    procedure EndFrameSet(FrameSet: TObject); override;
    procedure AddVisitedLink(const S: string);
    procedure CheckVisitedLinks;
    procedure LoadURLInternal(const URL, Query: string; IsGet, Reload: boolean);
    procedure DoFormSubmitEvent(Sender: TObject; const Action, Target, EncType, Method: string;
                    Results: TStringList);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Reload;
    procedure Clear;
    procedure HotSpotClick(Sender: TObject; const AnURL: string;
              var Handled: boolean);
    procedure ClearHistory; override;
    function ViewerFromTarget(const Target: string): ThtmlViewer;
    procedure GoBack;
    procedure GoFwd;
    procedure RePaint; override;
    procedure LoadURL(const URL: string);
    function GetViewerUrlBase(Viewer: ThtmlViewer): string;

    property Base: string read GetBase write SetBase;
    property BaseTarget: string read GetBaseTarget;
    property DocumentTitle: string read GetTitle;
    property CurrentFile: string read GetCurrentFile;
    property HistoryIndex: integer read FHistoryIndex write SetHistoryIndex;

  published
    property FwdButtonEnabled: boolean read GetFwdButtonEnabled;
    property BackButtonEnabled: boolean read GetBackButtonEnabled;
    property OnGetPostRequest: TGetPostRequestEvent read FOnGetPostRequest write FOnGetPostRequest;
    property OnImageRequest: TGetImageEvent read FOnImageRequest
                      write SetOnImageRequest;
    property fvOptions: TFrameViewerOptions read FOptions write SetOptions;
    property OnViewerClear: TNotifyEvent read FOnViewerClear write FOnViewerClear;

  end;

  TFMBEditor = class(TComponentEditor)
    function GetVerbCount: Integer; Override;
    function GetVerb(index: Integer): String; Override;
    procedure ExecuteVerb(index: Integer); Override;
    end;

procedure Register;

implementation

uses
  UrlSubs;


const
  Sequence: integer = 10;

type
  PositionObj = class(TObject)
    Pos: LongInt;
    Seq: integer;
    end;

{----------------SplitURL}
procedure SplitURL(const Src: string; var FName, Dest: string);
{Split an URL into filename and Destination}
var
  I: integer;
begin
I := Pos('#', Src);
if I >= 1 then
  begin
  Dest := System.Copy(Src, I, 255);  {local destination}
  FName := System.Copy(Src, 1, I-1);     {the file name}
  end
else
  begin
  FName := Src;
  Dest := '';    {no local destination}
  end;
end;

{----------------TbrFrame.CreateIt}
constructor TbrFrame.CreateIt(AOwner: TComponent; L: TAttributeList;
                   Master: TbrFrameSet; const Path: string);
var
  I: integer;
  S, Dest: string;
begin
inherited Create(AOwner);
{$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
if AOwner is TbrSubFrameSet then
  LocalCharSet := TbrSubFrameset(AOwner).LocalCharSet;       
{$endif}
Source := Nullstr;
Destination := NullStr;
LOwner := AOwner as TbrSubFrameSet;
MasterSet := Master;
BevelInner := bvNone;
MarginWidth := 10;
MarginHeight := 5;
if LOwner.BorderSize = 0 then
  BevelOuter := bvNone
else
  begin
  BevelOuter := bvLowered;
  BevelWidth := LOwner.BorderSize;
  end;
ParentColor := True;
if Assigned(L) then
  for I := 0 to L.Count-1 do
    with TAttribute(L[I]) do
      case Which of
        SrcSy:
          begin
          SplitUrl(Trim(Name^), S, Dest);
          AssignStr(Destination, Dest);
          if Pos(':/', S) <> 0 then
            URLBase := URLSubs.GetBase(S)   {get new base}
          else if ReadHTML.Base <> '' then
            begin
            S := Combine(ReadHTML.Base, S);
            URLBase := ReadHTML.Base;
            end
          else
            begin
            URLBase := LOwner.URLBase;
            S := Combine(URLBase, S);
            end;
          AssignStr(Source, S);
          end;
        NameSy: WinName := NewStr(Name^);
        NoResizeSy:  NoResize := True;
        ScrollingSy:
          if CompareText(Name^, 'NO') = 0 then  {auto and yes work the same}
            NoScroll := True;
        MarginWidthSy:  MarginWidth := Value;
        MarginHeightSy: MarginHeight := Value;
        end;
if Assigned(WinName) then   {add it to the Window name list}
  (AOwner as TbrSubFrameSet).MasterSet.FrameNames.AddObject(Uppercase(WinName^), Self);
OnMouseDown := FVMouseDown;
OnMouseMove := FVMouseMove;
OnMouseUp := FVMouseUp;
frHistory := TStringList.Create;
frPositionHistory := TFreeList.Create;
end;

{----------------TbrFrame.Destroy}
destructor TbrFrame.Destroy;
var
  I: integer;
begin
if Assigned(MasterSet) then
  begin
  if Assigned(WinName)
      and Assigned(MasterSet.FrameNames) and MasterSet.FrameNames.Find(WinName^, I)
      and (MasterSet.FrameNames.Objects[I] = Self) then      
    MasterSet.FrameNames.Delete(I);
  if Assigned(Viewer) then
    begin
    if Assigned(MasterSet.Viewers) then
      MasterSet.Viewers.Remove(Viewer);
    if Assigned(MasterSet.Frames) then
      MasterSet.Frames.Remove(Self);
    if Viewer = MasterSet.FActive then MasterSet.FActive := Nil;
    end;
  end;
DisposeStr(Source);
DisposeStr(Destination);
DisposeStr(WinName);
if Assigned(Viewer) then
  begin
  Viewer.Free;
  Viewer := Nil;
  end
else if Assigned(FrameSet) then
  begin
  FrameSet.Free;
  FrameSet := Nil;
  end;
frHistory.Free;  frHistory := Nil;
frPositionHistory.Free;  frPositionHistory := Nil;
RefreshTimer.Free;   
inherited Destroy;
end;

procedure TbrFrame.RefreshEvent(Sender: TObject; Delay: integer; const URL: string);
var
  Ext: string;
begin
if not (fvMetaRefresh in MasterSet.FrameViewer.FOptions) then
  Exit;
Ext := Lowercase(GetURLExtension(URL));  
if (Ext = 'exe') or (Ext = 'zip') then Exit;
If not IsFullURL(URL) then
   NextFile := URLBase + URL
else
   NextFile := URL;
if not Assigned(RefreshTimer) then
  RefreshTimer := TTimer.Create(Self);
RefreshTimer.OnTimer := RefreshTimerTimer;
RefreshTimer.Interval := Delay*1000;
RefreshTimer.Enabled := True;
end;

procedure TbrFrame.RefreshTimerTimer(Sender: TObject);  
var
  S, D: string;
begin
RefreshTimer.Enabled := False;
if Unloaded then Exit;
if not IsFullUrl(NextFile) then
  NextFile := Combine(UrlBase, NextFile);
if (MasterSet.Viewers.Count = 1) then    {load a new FrameSet}
  MasterSet.FrameViewer.LoadURLInternal(NextFile, '', True, True)
else
  begin
  SplitURL(NextFile, S, D);
  frLoadFromBrzFile(S, D, '', True, True, True);
  end;
end;

procedure TbrFrame.RePaint;
begin
if Assigned(Viewer) then Viewer.RePaint
else if Assigned(FrameSet) then FrameSet.RePaint;
inherited RePaint;
end;

{----------------TbrFrame.FVMouseDown}
procedure TbrFrame.FVMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
(Parent as TbrSubFrameSet).FVMouseDown(Sender, Button, Shift, X+Left, Y+Top);
end;

{----------------TbrFrame.FVMouseMove}
procedure TbrFrame.FVMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
if not NoResize then
  (Parent as TbrSubFrameSet).FVMouseMove(Sender, Shift, X+Left, Y+Top);
end;

{----------------TbrFrame.FVMouseUp}
procedure TbrFrame.FVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
(Parent as TbrSubFrameSet).FVMouseUp(Sender, Button, Shift, X+Left, Y+Top);
end;

{----------------TbrFrame.CheckNoResize}
function TbrFrame.CheckNoResize(var Lower, Upper: boolean): boolean;
begin
Result := NoResize;
Lower := NoResize;
Upper := NoResize;
end;

{----------------TbrFrame.InitializeDimensions}
procedure TbrFrame.InitializeDimensions(X, Y, Wid, Ht: integer);
begin
if Assigned(FrameSet) then
  FrameSet.InitializeDimensions(X, Y, Wid, Ht);
end;

{----------------TbrFrame.CreateViewer}
procedure TbrFrame.CreateViewer;
begin
Viewer := ThtmlViewer.Create(Self);  {the Viewer for the frame}
Viewer.FrameOwner := Self;
Viewer.Width := ClientWidth;
Viewer.Height := ClientHeight;
Viewer.Align := alClient;
if MasterSet.BorderSize = 0 then
  Viewer.BorderStyle := htNone;
Viewer.OnHotspotClick := LOwner.MasterSet.FrameViewer.HotSpotClick;
Viewer.OnHotspotCovered := LOwner.MasterSet.FrameViewer.HotSpotCovered;
if NoScroll then
  Viewer.Scrollbars := ssNone;
Viewer.DefBackground := MasterSet.FrameViewer.FBackground;
Viewer.Visible := False;
InsertControl(Viewer);
Viewer.SendToBack;
Viewer.Visible := True;
Viewer.Tabstop := True;
{$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
Viewer.CharSet := LocalCharset;    
{$endif}
MasterSet.Viewers.Add(Viewer);
with MasterSet.FrameViewer do
  begin
  Viewer.ViewImages := FViewImages;
  Viewer.ImageCacheCount := FImageCacheCount;
  Viewer.NoSelect := FNoSelect;
  Viewer.DefFontColor := FFontColor;
  Viewer.DefHotSpotColor := FHotSpotColor;
  Viewer.DefVisitedLinkColor := FVisitedColor;  
  Viewer.DefOverLinkColor := FOverColor;        
  Viewer.DefFontSize := FFontSize;
  Viewer.DefFontName := FFontName^;
  Viewer.DefPreFontName := FPreFontName^;
  Viewer.OnBitmapRequest := FOnBitmapRequest;
  if fvOverLinksActive in FOptions then
    Viewer.htOptions := Viewer.htOptions + [htOverLinksActive];  
  if fvNoLinkUnderline in FOptions then
    Viewer.htOptions := Viewer.htOptions + [htNoLinkUnderline];  
  if fvPrintTableBackground in FOptions then
    Viewer.htOptions := Viewer.htOptions + [htPrintTableBackground];  
  if Assigned(FOnImageRequest) then
    Viewer.OnImageRequest := FOnImageRequest;
  Viewer.OnFormSubmit := DoFormSubmitEvent;
  Viewer.OnMeta := FOnMeta;
  Viewer.OnMetaRefresh := RefreshEvent;
  Viewer.OnRightClick := FOnRightClick;
  Viewer.OnProcessing := CheckProcessing;
  Viewer.OnMouseDown := OnMouseDown;
  Viewer.OnMouseMove := OnMouseMove;
  Viewer.OnMouseUp := OnMouseUp;
  Viewer.OnKeyDown := OnKeyDown;
  Viewer.OnKeyUp := OnKeyUp;
  Viewer.OnKeyPress := OnKeyPress;
  Viewer.Cursor := Cursor;
  Viewer.HistoryMaxCount := FHistoryMaxCount;
  Viewer.OnScript := FOnScript;
  Viewer.PrintMarginLeft := FPrintMarginLeft;
  Viewer.PrintMarginRight := FPrintMarginRight;
  Viewer.PrintMarginTop := FPrintMarginTop;
  Viewer.PrintMarginBottom := FPrintMarginBottom;
  Viewer.OnPrintHeader := FOnPrintHeader;
  Viewer.OnPrintFooter := FOnPrintFooter;
  Viewer.OnInclude := FOnInclude;
  Viewer.OnSoundRequest := FOnSoundRequest;
  Viewer.OnImageOver := FOnImageOver;
  Viewer.OnImageClick := FOnImageClick;
  Viewer.OnObjectClick := FOnObjectClick;
  Viewer.MarginWidth := MarginWidth;
  Viewer.MarginHeight := MarginHeight;
  Viewer.ServerRoot := ServerRoot;
  Viewer.OnMouseDouble := FOnMouseDouble;   
  end;
Viewer.OnEnter := MasterSet.CheckActive;
Viewer.OnExpandName := UrlExpandName;    
end;

{----------------TbrFrame.LoadBrzFiles}
procedure TbrFrame.LoadBrzFiles;
var
  Item: TbrFrameBase;
  I: integer;
  Upper, Lower: boolean;
  Msg: string[255];
  LStyle: LoadStyleType;
  NewURL: string;
begin
if Assigned(Source) and (MasterSet.NestLevel < 4) then
  begin
  LStyle := lsStream;
  if not Assigned(TheStream) then
    begin
    NewURL := '';
    MasterSet.FrameViewer.FOnGetPostRequest(Self, True, Source^, '', False, NewURL, TheStreamType, TheStream);
    if NewURL <> '' then AssignStr(Source, NewURL);
    end;
  URLBase := GetBase(Source^);
  Inc(MasterSet.NestLevel);
  try
    if (TheStreamType = HTMLType) and IsFrameFile(LStyle, '', Nil, TheStream, Nil, 0,
          MasterSet.FrameViewer) then
      begin
      FrameSet := TbrSubFrameSet.CreateIt(Self, MasterSet);
      FrameSet.Align := alClient;
      FrameSet.Visible := False;
      InsertControl(FrameSet);
      FrameSet.SendToBack;
      FrameSet.Visible := True;
      FrameParseFile(MasterSet.FrameViewer, FrameSet, LStyle, '', Nil, TheStream, Nil, 0, FrameSet.HandleMeta);
      Self.BevelOuter := bvNone;
      frBumpHistory1(Source^, 0);
      with FrameSet do
        begin
        for I := 0 to List.Count-1 do
          Begin
          Item := TbrFrameBase(List.Items[I]);
          Item.LoadBrzFiles;
          end;
        CheckNoresize(Lower, Upper);
        if FRefreshDelay > 0 then
          SetRefreshTimer;
        end;
      end
    else
      begin
      CreateViewer;     
      Viewer.Base := MasterSet.FBase^;  {only effective if no Base file to load}
      Viewer.LoadStream(Source^, TheStream, TheStreamType);
      Viewer.PositionTo(Destination^);
      frBumpHistory1(Source^, Viewer.Position);
      end;
  except
    if not Assigned(Viewer) then
      CreateViewer;
    if Assigned(FrameSet) then
      begin
      FrameSet.Free;
      FrameSet := Nil;
      end;
    Msg := '<p><img src="qw%&.bmp" alt="Error"> Can''t load '+Source^;
    Viewer.LoadFromBuffer(@Msg[1], Length(Msg));  {load an error message}
    end;
  Dec(MasterSet.NestLevel);
  end
else
  begin  {so blank area will perform like the TFrameBrowser}
  OnMouseDown := MasterSet.FrameViewer.OnMouseDown;
  OnMouseMove := MasterSet.FrameViewer.OnMouseMove;
  OnMouseUp := MasterSet.FrameViewer.OnMouseUp;
  end;
end;

{----------------TbrFrame.ReloadFiles}
procedure TbrFrame.ReloadFiles(APosition: LongInt);
var
  Item: TbrFrameBase;
  I: integer;
  Upper, Lower: boolean;
  Dummy: string;

  procedure DoError;
  var
    Msg: string;
  begin
  Msg := '<p><img src="qw%&.bmp" alt="Error"> Can''t load '+Source^;
  Viewer.LoadFromBuffer(@Msg[1], Length(Msg));  {load an error message}
  end;

begin
if Assigned(Source) then
  if Assigned(FrameSet) then
    begin
    with FrameSet do
      begin
      for I := 0 to List.Count-1 do
        Begin
        Item := TbrFrameBase(List.Items[I]);
        Item.ReloadFiles(APosition);
        end;
      CheckNoresize(Lower, Upper);
      end;
    end
  else if Assigned(Viewer) then
    begin
    Viewer.Base := MasterSet.FBase^;  {only effective if no Base to be read}
    try     
      MasterSet.FrameViewer.FOnGetPostRequest(Self, True, Source^, '', False,
                                     Dummy, TheStreamType, TheStream);
      Viewer.LoadStream(Source^, TheStream, TheStreamType);
      if APosition < 0 then
        Viewer.Position := ViewerPosition
      else Viewer.Position := APosition;    {its History Position}
    except
      DoError;
      end;
    end;
Unloaded := False;
end;

{----------------TbrFrame.UnloadFiles}
procedure TbrFrame.UnloadFiles;
var
  Item: TbrFrameBase;
  I: integer;
begin
if Assigned(RefreshTimer) then
  RefreshTimer.Enabled := False;
if Assigned(FrameSet) then
  begin
  with FrameSet do
    begin
    for I := 0 to List.Count-1 do
      Begin
      Item := TbrFrameBase(List.Items[I]);
      Item.UnloadFiles;
      end;
    end;
  end
else if Assigned(Viewer) then
  begin
  ViewerPosition := Viewer.Position;
  if Assigned(MasterSet.FrameViewer.FOnViewerClear) then   
    MasterSet.FrameViewer.FOnViewerClear(Viewer);
  Viewer.Clear;
  Viewer.OnSoundRequest := Nil;
  end;
Unloaded := True;
end;

{----------------TbrFrame.frLoadFromBrzFile}
procedure TbrFrame.frLoadFromBrzFile(const URL, Dest, Query: string; Bump, IsGet, Reload: boolean);
{URL is full URL here, has been seperated from Destination}
var
  OldPos: LongInt;
  HS, S, S1, OldTitle, OldName, OldBase: string;
  SameName: boolean;
  OldViewer: ThtmlViewer;
  OldFrameSet: TbrSubFrameSet;
  LStyle: LoadStyleType;
  Upper, Lower, FrameFile: boolean;
  Item: TbrFrameBase;
  I: integer;

begin
if Assigned(RefreshTimer) then RefreshTimer.Enabled := False;    
OldName := Source^;
OldBase := URLBase;
S := URL;
if S = '' then S := OldName
else  URLBase := URLSubs.GetBase(S);   {get new base}
HS := S;
SameName := CompareText(S, OldName)= 0;
{if SameName, will not have to reload anything unless Reload set}
LStyle := lsStream;

if not SameName or Reload then
  begin
  if Assigned(Viewer) and Assigned(MasterSet.FrameViewer.FOnViewerClear) then
    MasterSet.FrameViewer.FOnViewerClear(Viewer);  
  S1 := '';
  MasterSet.FrameViewer.FOnGetPostRequest(Self, IsGet, S, Query, SameName, S1, TheStreamType, TheStream);
  if S1 <> '' then
    begin
    S := S1;
    URLBase := GetBase(S);
    end;
  end;
AssignStr(Source, S);

try
  if not SameName then
    try
      FrameFile := (TheStreamType = HTMLType) and
              IsFrameFile(LStyle, '', Nil, TheStream, Nil, 0, MasterSet.FrameViewer);
    except
      Raise(EInOutError.Create('Can''t load: '+URL));
      end
  else FrameFile := not Assigned(Viewer);
  if SameName and not Reload then
    if Assigned(Viewer) then
      begin
      OldPos := Viewer.Position;
      Viewer.PositionTo(Dest);
      MasterSet.FrameViewer.AddVisitedLink(URL+Dest);   
      if Bump and (Viewer.Position <> OldPos) then
        {Viewer to Viewer}
        frBumpHistory(HS, Viewer.Position, OldPos);
      end
    else Exit  {framefile with same name, nothing to do}
  else if Assigned(Viewer) and not FrameFile then  {not samename or samename and reload}
    begin  {Viewer already assigned and it's not a Frame file}
    OldPos := Viewer.Position;
    OldTitle := Viewer.DocumentTitle;
    Viewer.LoadStream(Source^, TheStream, TheStreamType);
    if (Dest <> '') then
      Viewer.PositionTo(Dest);
    MasterSet.FrameViewer.AddVisitedLink(URL+Dest);   
    if not samename then
      begin   {don't bump history on a forced reload}
      if MasterSet.Viewers.Count > 1 then
        if Bump then
           {Viewer to Viewer}
          frBumpHistory(HS, Viewer.Position, OldPos);
      Viewer.Base := MasterSet.FBase^;  {only effective if no Base already}
      if (MasterSet.Viewers.Count = 1) and Bump then
        {a single viewer situation, bump the history here}
        with MasterSet do
          begin
          AssignStr(FCurrentFile, Source^);
          AssignStr(FTitle, Viewer.DocumentTitle);
          AssignStr(FBase, Viewer.Base);
          AssignStr(FBaseTarget, Viewer.BaseTarget);
          FrameViewer.BumpHistory1(OldName, OldTitle, OldPos, HTMLType);
          end;
      end;
    end
  else
    begin {Viewer is not assigned or it is a Frame File}
    {keep the old viewer or frameset around (free later) to minimize blink}
    OldViewer := Viewer;  Viewer := Nil;
    OldFrameSet := FrameSet;  FrameSet := Nil;
    if OldFrameSet <> Nil then OldFrameSet.ClearFrameNames;
    if FrameFile then
      begin   {it's a frame file}
      FrameSet := TbrSubFrameSet.CreateIt(Self, MasterSet);
      FrameSet.URLBase := URLBase;
      FrameSet.Align := alClient;
      FrameSet.Visible := False;
      InsertControl(FrameSet);
      FrameSet.SendToBack;    {to prevent blink}
      FrameSet.Visible := True;
      FrameParseFile(MasterSet.FrameViewer, FrameSet, LStyle, '', Nil, TheStream, Nil, 0, FrameSet.HandleMeta);
      MasterSet.FrameViewer.AddVisitedLink(URL);   
      Self.BevelOuter := bvNone;
      with FrameSet do
        begin
        for I := 0 to List.Count-1 do
          Begin
          Item := TbrFrameBase(List.Items[I]);
          Item.LoadBrzFiles;
          end;
        CheckNoresize(Lower, Upper);
        if FRefreshDelay > 0 then
          SetRefreshTimer;
        end;
      if Assigned(OldViewer) then
        frBumpHistory(HS, 0, OldViewer.Position)
      else frBumpHistory(S, 0, 0);
      end
    else
      begin   {not a frame file but needs a viewer}
      CreateViewer;
      Viewer.LoadStream(Source^, TheStream, TheStreamType);
      Viewer.PositionTo(Dest);
      MasterSet.FrameViewer.AddVisitedLink(URL+Dest);   
      {FrameSet to Viewer}
      frBumpHistory(HS, Viewer.Position, 0);
      Viewer.Base := MasterSet.FBase^;  {only effective if no Base already}
      end;
    if Assigned(FrameSet) then
      with FrameSet do
        begin
        with ClientRect do
          InitializeDimensions(Left, Top, Right-Left, Bottom-Top);
        CalcSizes(Nil);
        end;
    if Assigned(Viewer) then
      begin
      if MasterSet.BorderSize = 0 then
        BevelOuter := bvNone
      else
        begin
        BevelOuter := bvLowered;
        BevelWidth := MasterSet.BorderSize;
        end;
      if (Dest <> '') then
        Viewer.PositionTo(Dest);
      end;
    if Assigned(OldViewer) then
      begin
      MasterSet.Viewers.Remove(OldViewer);
      if MasterSet.FActive = OldViewer then
        MasterSet.FActive := Nil;
      OldViewer.Free;
      end
    else if Assigned(OldFrameSet) then
      begin
      OldFrameSet.UnloadFiles;
      OldFrameSet.Visible := False;
      end;
    RePaint;
    end;
  except
    AssignStr(Source, OldName);
    URLBase := OldBase;
    Raise;
    end;
end;

{----------------TbrFrame.ReloadFile}
procedure TbrFrame.ReloadFile(const FName: string; APosition: LongInt);
{It's known that there is only a single viewer, the file is not being changed,
 only the position}
begin
Viewer.Position := APosition;
end;

{----------------TbrFrame.URLExpandName}    
procedure TbrFrame.URLExpandName(Sender: TObject; const SRC: string; var Rslt: string);
var
  S: string;
begin
S := SRC;
if Pos('\', S) > 0 then
  begin
  S := DosToHTML(S);
  if Pos('|', S) > 0 then
    S := 'file:///'+S;
  end;
if Pos(':/', S) = 0 then
  Rslt := Combine(UrlBase, S)
else Rslt := S;
end;

{----------------TbrFrame.frBumpHistory}
procedure TbrFrame.frBumpHistory(const NewName: string;
              NewPos, OldPos: LongInt);
{applies to TFrames which hold a ThtmlViewer}{Viewer to Viewer}
var
  PO: PositionObj;
begin
with frHistory do
  begin
  if (Count > 0) then
    PositionObj(frPositionHistory[frHistoryIndex]).Pos := OldPos;
  MasterSet.ClearForwards;   {clear the history list forwards}
  frHistoryIndex := 0;
  InsertObject(0, NewName, FrameSet);  {FrameSet may be Nil here}
  PO := PositionObj.Create;
  PO.Pos := NewPos;
  PO.Seq := Sequence;
  Inc(Sequence);
  frPositionHistory.Insert(0, PO);
  MasterSet.UpdateFrameList;
  with MasterSet.FrameViewer do
    if Assigned(FOnHistoryChange) then
      FOnHistoryChange(MasterSet.FrameViewer);
  end;
end;

{----------------TbrFrame.frBumpHistory1}
procedure TbrFrame.frBumpHistory1(const NewName: string; Pos: LongInt);
{called from a fresh TbrFrame.  History list is empty}
var
  PO: PositionObj;
begin
with frHistory do
  begin
  frHistoryIndex := 0;
  InsertObject(0, NewName, FrameSet);  {FrameSet may be Nil here}
  PO := PositionObj.Create;
  PO.Pos := Pos;
  PO.Seq := Sequence;
  Inc(Sequence);
  frPositionHistory.Insert(0, PO);
  MasterSet.UpdateFrameList;     
  with MasterSet.FrameViewer do        
    if Assigned(FOnHistoryChange) then
      FOnHistoryChange(MasterSet.FrameViewer);
  end;
end;

{----------------TbrFrame.frSetHistoryIndex}
procedure TbrFrame.frSetHistoryIndex(Value: integer);
begin
with frHistory do
  if (Value <> frHistoryIndex) and (Value >= 0) and (Value < Count) then
    begin
    if Assigned(RefreshTimer) then
      RefreshTimer.Enabled := False;    {cut off any timing underway}
    if Assigned(Viewer) then   {current is Viewer}
      with PositionObj(frPositionHistory[frHistoryIndex]) do
        begin
        Pos := Viewer.Position;   {save the old position}
        end
    else
      begin    {Current is FrameSet}
      FrameSet.UnloadFiles;
      FrameSet.DestroyHandle;    
      FrameSet.ClearFrameNames;
      FrameSet.Visible := False;
      FrameSet := Nil;   {it's not destroyed,though}
      end;

    if Objects[Value] is TbrSubFrameSet then
      begin
      FrameSet := TbrSubFrameSet(Objects[Value]);
      FrameSet.Visible := True;
      FrameSet.ReloadFiles(-1);
      FrameSet.AddFrameNames;
      if Assigned(Viewer) then
        begin
        if Assigned(MasterSet.Viewers) then
          MasterSet.Viewers.Remove(Viewer);
        if MasterSet.FActive = Viewer then
          MasterSet.FActive := Nil;
        Viewer.Free;
        Viewer := Nil;
        end;
      end
    else
      begin
      if not Assigned(Viewer) then
        CreateViewer;
      with PositionObj(frPositionHistory[Value]) do
        begin
        if (Source^ <> Strings[Value]) then
        frLoadFromBrzFile(Strings[Value], '', '', False, True, False);
        Viewer.Position := Pos;
        end;
      end;
    AssignStr(Source, Strings[Value]);
    frHistoryIndex := Value;
    MasterSet.UpdateFrameList;
    with MasterSet.FrameViewer do
      if Assigned(FOnHistoryChange) then
        FOnHistoryChange(MasterSet.FrameViewer);
    MasterSet.FrameViewer.CheckVisitedLinks;
    end;
end;

{----------------TbrFrame.UpdateFrameList}
procedure TbrFrame.UpdateFrameList;  
begin
MasterSet.Frames.Add(Self);
if Assigned(FrameSet) then
  FrameSet.UpdateFrameList;
end;

{----------------TbrSubFrameSet.CreateIt}
constructor TbrSubFrameSet.CreateIt(AOwner: TComponent; Master: TbrFrameSet);
begin
inherited Create(AOwner);
MasterSet := Master;
{$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
if AOwner is TbrFrameBase then
  LocalCharSet := TbrSubFrameset(AOwner).LocalCharSet;       
{$endif}
OuterBorder := 0;   {no border for subframesets}  
if Self <> Master then
  BorderSize := Master.BorderSize;   
First := True;
List := TFreeList.Create;
FBase := NullStr;
FBaseTarget := NullStr;
OnResize := CalcSizes;
OnMouseDown := FVMouseDown;
OnMouseMove := FVMouseMove;
OnMouseUp := FVMouseUp;
ParentColor := True;
if (AOwner is TbrFrameBase) then
  URLBase := TbrFrameBase(AOwner).URLBase;   
end;

{----------------TbrSubFrameSet.ClearFrameNames}
procedure TbrSubFrameSet.ClearFrameNames;
var
  I, J: integer;
begin
for J := 0 to List.Count-1 do
  if (TbrFrameBase(List[J]) is TbrFrame) then
    with TbrFrame(List[J]) do
      if Assigned(MasterSet) and Assigned(WinName)
            and Assigned(MasterSet.FrameNames)
              and MasterSet.FrameNames.Find(WinName^, I) then
                MasterSet.FrameNames.Delete(I);
end;

{----------------TbrSubFrameSet.AddFrameNames}
procedure TbrSubFrameSet.AddFrameNames;         
var
  J: integer;
  Frame: TbrFrame;
begin
for J := 0 to List.Count-1 do
  if (TbrFrameBase(List[J]) is TbrFrame) then
    begin
    Frame := TbrFrame(List[J]);
    with Frame do
      if Assigned(MasterSet) and Assigned(WinName)
            and Assigned(MasterSet.FrameNames) then
              begin
              MasterSet.FrameNames.AddObject(Uppercase(WinName^), Frame);
              end;
    end;
end;

{----------------TbrSubFrameSet.Destroy}
destructor TbrSubFrameSet.Destroy;
begin
List.Free;
List := Nil;
DisposeStr(FBase);
DisposeStr(FBaseTarget);
RefreshTimer.Free;   
inherited Destroy;
end;

{----------------TbrSubFrameSet.AddFrame}
function TbrSubFrameSet.AddFrame(Attr: TAttributeList; const FName: string): TbrFrame;
{called by the parser when <Frame> is encountered within the <Frameset>
 definition}
begin
Result := TbrFrame.CreateIt(Self, Attr, MasterSet, ExtractFilePath(FName));
List.Add(Result);
Result.SetBounds(OuterBorder, OuterBorder, Width-2*OuterBorder, Height-2*OuterBorder);  
InsertControl(Result);
end;

{----------------TbrSubFrameSet.DoAttributes}
procedure TbrSubFrameSet.DoAttributes(L: TAttributeList);
{called by the parser to process the <Frameset> attributes}
var
  T: TAttribute;
  S: string;
  Numb: string[20];

  procedure GetDims;
  const
    EOL = ^M;
  var
    Ch: char;
    I, N: integer;

    procedure GetCh;
    begin
    if I > Length(S) then Ch := EOL
    else
      begin
      Ch := S[I];
      Inc(I);
      end;
    end;

  begin
  if Assigned(T.Name) then S := T.Name^
  else Exit;
  I := 1;   DimCount := 0;
  repeat
    Inc(DimCount);
    Numb := '';
    GetCh;
    while not (Ch in ['0'..'9', '*', EOL, ',']) do GetCh;
    if Ch in ['0'..'9'] then
      begin
      while Ch in ['0'..'9'] do
        begin
        Numb := Numb+Ch;
        GetCh;
        end;
      N := IntMax(1, StrToInt(Numb));   {no zeros}
      while not (Ch in ['*', '%', ',', EOL]) do GetCh;
      if ch = '*' then
        begin
        Dim[DimCount] := -IntMin(99, N);{store '*' relatives as negative, -1..-99}
        GetCh;
        end
      else if Ch = '%' then
        begin  {%'s stored as -(100 + %),  i.e. -110 is 10% }
        Dim[DimCount] := -IntMin(1000, N+100);  {limit to 900%}
        GetCh;
        end
      else Dim[DimCount] := IntMin(N, 5000);  {limit absolute to 5000}
      end
    else if Ch in ['*', ',', EOL] then
      begin
      Dim[DimCount] := -1;
      if Ch = '*' then GetCh;
      end;
    while not (Ch in [',', EOL]) do GetCh;
  until (Ch = EOL) or (DimCount = 20);
  end;

begin
{read the row or column widths into the Dim array}
If L.Find(RowsSy, T) then
  begin
  Rows := True;
  GetDims;
  end;
if L.Find(ColsSy, T) and (DimCount <=1) then
  begin
  Rows := False;
  DimCount := 0;
  GetDims;
  end;
if (Self = MasterSet) and not (fvNoBorder in MasterSet.FrameViewer.FOptions) then
                               {BorderSize already defined as 0}  
  if L.Find(BorderSy, T) or L.Find(FrameBorderSy, T)then
    begin
    BorderSize := T.Value;
    OuterBorder := IntMax(2-BorderSize, 0);
    if OuterBorder >= 1 then
      begin
      BevelWidth := OuterBorder;
      BevelOuter := bvLowered;
      end;
    end
  else BorderSize := 2;  
end;

{----------------TbrSubFrameSet.LoadBrzFiles}
procedure TbrSubFrameSet.LoadBrzFiles;
var
  I: integer;
  Item: TbrFrameBase;
begin
for I := 0 to List.Count-1 do
  begin
  Item := TbrFrameBase(List.Items[I]);
  Item.LoadBrzFiles;
  end;
end;

{----------------TbrSubFrameSet.ReloadFiles}
procedure TbrSubFrameSet.ReloadFiles(APosition: LongInt);
var
  I: integer;
  Item: TbrFrameBase;
begin
for I := 0 to List.Count-1 do
  begin
  Item := TbrFrameBase(List.Items[I]);
  Item.ReloadFiles(APosition);
  end;
if (FRefreshDelay > 0) and Assigned(RefreshTimer) then
  SetRefreshTimer;
Unloaded := False;
end;

{----------------TbrSubFrameSet.UnloadFiles}
procedure TbrSubFrameSet.UnloadFiles;
var
  I: integer;
  Item: TbrFrameBase;
begin
if Assigned(RefreshTimer) then
  RefreshTimer.Enabled := False;
for I := 0 to List.Count-1 do
  begin
  Item := TbrFrameBase(List.Items[I]);
  Item.UnloadFiles;
  end;
if Assigned(MasterSet.FrameViewer.FOnSoundRequest) then
  MasterSet.FrameViewer.FOnSoundRequest(MasterSet, '', 0, True);
Unloaded := True;
end;

{----------------TbrSubFrameSet.EndFrameSet}
procedure TbrSubFrameSet.EndFrameSet;
{called by the parser when </FrameSet> is encountered}
var
  I: integer;
begin
if List.Count > DimCount then  {a value left out}
  begin  {fill in any blanks in Dim array}
  for I := DimCount+1 to List.Count do
    begin
    Dim[I] := -1;      {1 relative unit}
    Inc(DimCount);
    end;
  end
else while DimCount > List.Count do  {or add Frames if more Dims than Count}
  AddFrame(Nil, '');
if ReadHTML.Base <> '' then      
  AssignStr(FBase, ReadHTML.Base)
else AssignStr(FBase, MasterSet.FrameViewer.FBaseEx^);
AssignStr(FBaseTarget, ReadHTML.BaseTarget);
end;

{----------------TbrSubFrameSet.InitializeDimensions}
procedure TbrSubFrameSet.InitializeDimensions(X, Y, Wid, Ht: integer);
var
  I, Total, PixTot, PctTot, RelTot, Rel, Sum,
  Remainder, PixDesired, PixActual: integer;

begin
if Rows then
  Total := Ht
else Total := Wid;
PixTot := 0;  RelTot := 0;  PctTot := 0; DimFTot := 0;
for I := 1 to DimCount do   {count up the total pixels, %'s and relatives}
  if Dim[I] >= 0 then
    PixTot := PixTot + Dim[I]
  else if Dim[I] <= -100 then
    PctTot :=  PctTot + (-Dim[I]-100)
  else RelTot := RelTot - Dim[I];
Remainder := Total - PixTot;
if Remainder <= 0 then
  begin    {% and Relative are 0, must scale absolutes}
  for I := 1 to DimCount do
    begin
    if Dim[I] >= 0 then
      DimF[I] := MulDiv(Dim[I], Total, PixTot)  {reduce to fit}
    else DimF[I] := 0;
    Inc(DimFTot, DimF[I]);
    end;
  end
else    {some remainder left for % and relative}
  begin
  PixDesired := MulDiv(Total, PctTot, 100);
  if PixDesired > Remainder then
    PixActual := Remainder
  else PixActual := PixDesired;
  Dec(Remainder, PixActual);   {Remainder will be >= 0}
  if RelTot > 0 then
    Rel := Remainder div RelTot  {calc each relative unit}
  else Rel := 0;
  for I := 1 to DimCount do  {calc the actual pixel widths (heights) in DimF}
    begin
    if Dim[I] >= 0 then
      DimF[I] := Dim[I]
    else if Dim[I] <= -100 then
      DimF[I] := MulDiv(-Dim[I]-100, PixActual, PctTot)
    else DimF[I] := -Dim[I] * Rel;
    Inc(DimFTot, DimF[I]);
    end;
  end;

Sum := 0;
for I := 0 to List.Count-1 do  {intialize the dimensions of contained items}
  begin
  if Rows then
    TbrFrameBase(List.Items[I]).InitializeDimensions(X, Y+Sum, Wid, DimF[I+1])
  else
    TbrFrameBase(List.Items[I]).InitializeDimensions(X+Sum, Y, DimF[I+1], Ht);
  Sum := Sum+DimF[I+1];
  end;
end;

{----------------TbrSubFrameSet.CalcSizes}
{OnResize event comes here}
procedure TbrSubFrameSet.CalcSizes(Sender: TObject);
var
  I, Step, Sum, ThisTotal: integer;
  ARect: TRect;
begin
{Note: this method gets called during Destroy as it's in the OnResize event.
 Hence List may be Nil.}
if Assigned(List) and (List.Count > 0) then
  begin
  ARect := ClientRect;
  InflateRect(ARect, -OuterBorder, -OuterBorder);      
  Sum := 0;
  if Rows then ThisTotal := ARect.Bottom - ARect.Top
  else ThisTotal := ARect.Right-ARect.Left;
  for I := 0 to List.Count-1 do
    begin
    Step := MulDiv(DimF[I+1], ThisTotal, DimFTot);
    if Rows then
      TbrFrameBase(List.Items[I]).SetBounds(ARect.Left, ARect.Top+Sum, ARect.Right-ARect.Left, Step)
    else
      TbrFrameBase(List.Items[I]).SetBounds(ARect.Left+Sum, ARect.Top, Step, ARect.Bottom-Arect.Top);
    Sum := Sum+Step;
    Lines[I+1] := Sum;
    end;
  end;
end;

{----------------TbrSubFrameSet.NearBoundary}
function TbrSubFrameSet.NearBoundary(X, Y: integer): boolean;
begin
Result := (Abs(X) < 4) or (Abs(X - Width) < 4) or
             (Abs(Y) < 4) or (Abs(Y-Height) < 4);
end;

{----------------TbrSubFrameSet.GetRect}
function TbrSubFrameSet.GetRect: TRect;
{finds the FocusRect to draw when draging boundaries}
var
  Pt, Pt1, Pt2: TPoint;
begin
Pt1 := Point(0, 0);
Pt1 := ClientToScreen(Pt1);
Pt2 := Point(ClientWidth, ClientHeight);
Pt2 := ClientToScreen(Pt2);
GetCursorPos(Pt);
if Rows then
  Result := Rect(Pt1.X, Pt.Y-1, Pt2.X, Pt.Y+1)
else
  Result := Rect(Pt.X-1, Pt1.Y, Pt.X+1, Pt2.Y);
OldRect := Result;
end;

{----------------DrawRect}
procedure DrawRect(ARect: TRect);
{Draws a Focus Rect}
var
  DC: HDC;
begin
DC := GetDC(0);
DrawFocusRect(DC, ARect);
ReleaseDC(0, DC);
end;

{----------------TbrSubFrameSet.FVMouseDown}
procedure TbrSubFrameSet.FVMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
var
  ACursor: TCursor;
  RP: record
      case boolean of
        True: (P1, P2: TPoint);
        False:(R: TRect);
        end;
begin
if Button <> mbLeft then Exit;
if NearBoundary(X, Y) then
  begin
  if Parent is TbrFrameBase then
    (Parent as TbrFrameBase).FVMouseDown(Sender, Button, Shift, X+Left, Y+Top)
  else
    Exit;
  end
else
  begin
  ACursor := (Sender as TbrFrameBase).Cursor;
  if (ACursor = crVSplit) or(ACursor = crHSplit) then
    begin
    MasterSet.HotSet := Self;
    with RP do
      begin   {restrict cursor to lines on both sides}
      if Rows then
        R := Rect(0, Lines[LineIndex-1]+1, ClientWidth, Lines[LineIndex+1]-1)
      else
        R := Rect(Lines[LineIndex-1]+1, 0, Lines[LineIndex+1]-1, ClientHeight);
      P1 := ClientToScreen(P1);
      P2 := ClientToScreen(P2);
      ClipCursor(@R);
      end;
    DrawRect(GetRect);
    end;
  end;
end;

{----------------TbrSubFrameSet.FindLineAndCursor}
procedure TbrSubFrameSet.FindLineAndCursor(Sender: TObject; X, Y: integer);
var
  ACursor: TCursor;
  Gap, ThisGap, Line, I: integer;
begin
if  not Assigned(MasterSet.HotSet) then
  begin  {here we change the cursor as mouse moves over lines,button up or down}
  if Rows then Line := Y else Line := X;
  Gap := 9999;
  for I := 1 to DimCount-1 do
    begin
    ThisGap := Line-Lines[I];
    if Abs(ThisGap) < Abs(Gap) then
      begin
      Gap := Line - Lines[I];
      LineIndex := I;
      end
    else if Abs(ThisGap) = Abs(Gap) then  {happens if 2 lines in same spot}
      if ThisGap >= 0 then  {if Pos, pick the one on right (bottom)}
        LineIndex := I;
    end;

  if (Abs(Gap) <= 4) and not Fixed[LineIndex] then
    begin
    if Rows then
      ACursor := crVSplit
    else ACursor := crHSplit;
    (Sender as TbrFrameBase).Cursor := ACursor;
    end
  else (Sender as TbrFrameBase).Cursor := MasterSet.FrameViewer.Cursor;
  end
else
  with TbrSubFrameSet(MasterSet.HotSet) do
    begin
    DrawRect(OldRect);
    DrawRect(GetRect);
    end;
end;

{----------------TbrSubFrameSet.FVMouseMove}
procedure TbrSubFrameSet.FVMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
if NearBoundary(X, Y) then
  (Parent as TbrFrameBase).FVMouseMove(Sender, Shift, X+Left, Y+Top)
else
  FindLineAndCursor(Sender, X, Y);
end;

{----------------TbrSubFrameSet.FVMouseUp}
procedure TbrSubFrameSet.FVMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
var
  I: integer;
begin
if Button <> mbLeft then Exit;
if MasterSet.HotSet = Self then
    begin
    MasterSet.HotSet := Nil;
    DrawRect(OldRect);
    ClipCursor(Nil);
    if Rows then
      Lines[LineIndex] := Y else Lines[LineIndex] := X;
    for I := 1 to DimCount do
      if I = 1 then DimF[1] := MulDiv(Lines[1], DimFTot, Lines[DimCount])
      else DimF[I] := MulDiv((Lines[I] - Lines[I-1]), DimFTot, Lines[DimCount]);
    CalcSizes(Self);
    Invalidate;           
    end
else if (Parent is TbrFrameBase) then  
  (Parent as TbrFrameBase).FVMouseUp(Sender, Button, Shift, X+Left, Y+Top);
end;

{----------------TbrSubFrameSet.CheckNoResize}
function TbrSubFrameSet.CheckNoResize(var Lower, Upper: boolean): boolean;
var
  Lw, Up: boolean;
  I: integer;
begin
Result := False; Lower := False;  Upper := False;
for I := 0 to List.Count-1 do
  with TbrFrameBase(List[I]) do
    if CheckNoResize(Lw, Up) then
      begin
      Result := True;  {sides are fixed}
      Fixed[I] := True;  {these edges are fixed}
      Fixed[I+1] := True;
      If Lw and (I = 0) then Lower := True;
      If Up and (I = List.Count-1) then Upper := True;
      end;
end;

{----------------TbrSubFrameSet.Clear}
procedure TbrSubFrameSet.Clear;
var
  I: integer;
  X: TbrFrameBase;
begin
for I := List.Count-1 downto 0 do
  begin
  X := List.Items[I];
  List.Delete(I);
  RemoveControl(X);
  X.Free;
  end;
DimCount := 0;
First := True;
Rows := False;
FillChar(Fixed, Sizeof(Fixed), 0);
FillChar(Lines, Sizeof(Lines), 0);
DisposeStr(FBase); FBase := NullStr;
DisposeStr(FBaseTarget); FBaseTarget := NullStr;
end;

{----------------TbrSubFrameSet.UpdateFrameList}
procedure TbrSubFrameSet.UpdateFrameList;
var
  I: integer;
begin
for I := 0 to List.Count-1 do
  TbrFrameBase(List[I]).UpdateFrameList;
end;

{----------------TbrSubFrameSet.HandleMeta}
procedure TbrSubFrameSet.HandleMeta(Sender: TObject; const HttpEq, Name, Content: string);  
var
  DelTime, I: integer;
begin
with MasterSet.FrameViewer do
  begin
  if Assigned(FOnMeta) then FOnMeta(Sender, HttpEq, Name, Content);
  if not (fvMetaRefresh in FOptions) then Exit;
  end;

  {$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
if CompareText(HttpEq, 'content-type') = 0 then
  LocalCharSet := TranslateCharset(LocalCharset, Content);
{$endif}

if CompareText(Lowercase(HttpEq), 'refresh') = 0 then
  begin
  I := Pos(';', Content);
  DelTime := StrToIntDef(copy(Content, 1, I-1), -1);
  if DelTime < 0 then Exit
  else if DelTime = 0 then DelTime := 1;   
  I := Pos('url=', Lowercase(Content));
  if I > 0 then
    begin
    FRefreshURL := Copy(Content, I+4, Length(Content)-I-3);
    FRefreshDelay := DelTime;
    end;
  end;
end;

{----------------TbrSubFrameSet.SetRefreshTimer}
procedure TbrSubFrameSet.SetRefreshTimer;
begin
NextFile := FRefreshURL;
if not Assigned(RefreshTimer) then
  RefreshTimer := TTimer.Create(Self);
RefreshTimer.OnTimer := RefreshTimerTimer;
RefreshTimer.Interval := FRefreshDelay*1000;
RefreshTimer.Enabled := True;
end;

{----------------TbrSubFrameSet.RefreshTimerTimer}
procedure TbrSubFrameSet.RefreshTimerTimer(Sender: Tobject);  
var
  S, D: string;
begin
RefreshTimer.Enabled := False;
if Unloaded then Exit;
if Owner is TbrFrame then
  begin
  SplitURL(NextFile, S, D);
  TbrFrame(Owner).frLoadFromBrzFile(S, D, '', True, True, True)
  end;
end;

{----------------TbrFrameSet.Create}
constructor TbrFrameSet.Create(AOwner: TComponent);
begin
inherited CreateIt(AOwner, Self);
FrameViewer := AOwner as TFrameBrowser;
{$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
LocalCharSet := FrameViewer.FCharset;       
{$endif}
if fvNoBorder in FrameViewer.FOptions then
  BorderSize := 0    
else
  BorderSize := 2;
BevelOuter := bvNone;
FTitle := NullStr;
FCurrentFile:= NullStr;
FrameNames := TStringList.Create;
FrameNames.Sorted := True;
Viewers := TList.Create;
Frames := TList.Create;
OnResize := CalcSizes;
end;

{----------------TbrFrameSet.Destroy}
destructor TbrFrameSet.Destroy;
begin
DisposeStr(FTitle);
DisposeStr(FCurrentFile);
FrameNames.Free;
FrameNames := Nil;   {is tested later}
Viewers.Free;
Viewers := Nil;
Frames.Free;    
Frames := Nil;
inherited Destroy;
end;

{----------------TbrFrameSet.Clear}
procedure TbrFrameSet.Clear;
begin
inherited Clear;
FrameNames.Clear;
Viewers.Clear;
Frames.Clear;   
HotSet := Nil;
DisposeStr(FTitle); FTitle := NullStr;
DisposeStr(FCurrentFile); FCurrentFile:= NullStr;
OldHeight := 0;
OldWidth := 0;
FActive := Nil;
end;

procedure TbrFrameSet.RePaint;     
var
  I: integer;
begin
if Assigned(Frames) then
  for I := 0 to Frames.Count-1 do
    TWinControl(Frames[I]).RePaint;
end;

{----------------TbrFrameSet.EndFrameSet}
procedure TbrFrameSet.EndFrameSet;
begin
AssignStr(FTitle, ReadHTML.Title);
inherited EndFrameSet;
with ClientRect do
  InitializeDimensions(Left, Top, Right-Left, Bottom-Top);
end;

{----------------TbrFrameSet.CalcSizes}
{OnResize event comes here}
procedure TbrFrameSet.CalcSizes(Sender: TObject);
var
  ARect: TRect;
begin
ARect := ClientRect;
InflateRect(ARect, -OuterBorder, -OuterBorder);
with ARect do
  begin
  if (OldWidth <> Right-Left) or (OldHeight <> Bottom-Top) then
    begin
    InitializeDimensions(Left, Top, Right-Left, Bottom-Top);
    inherited CalcSizes(Sender);
    end;
  OldWidth := Right-Left;
  OldHeight := Bottom-Top;
  end;
end;

{----------------TbrFrameSet.CheckActive}
procedure TbrFrameSet.CheckActive(Sender: TObject);
begin
if Sender is ThtmlViewer then
  FActive := ThtmlViewer(Sender);
end;

{----------------TbrFrameSet.GetActive}
function TbrFrameSet.GetActive: ThtmlViewer;
begin
if Viewers.Count = 1 then
  Result := ThtmlViewer(Viewers[0])
else
  try
    if FActive is ThtmlViewer then Result := FActive
      else Result := Nil;
  except
    Result := Nil;
  end;
end;

{----------------TbrFrameSet.FVMouseMove}
procedure TbrFrameSet.FVMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
FindLineAndCursor(Sender, X, Y);
if (LineIndex = 0) or (LineIndex = DimCount) then
  begin    {picked up the outer boundary}
  (Sender as TbrFrameBase).Cursor := MasterSet.FrameViewer.Cursor;
  Cursor := MasterSet.FrameViewer.Cursor;
  end;
end;

procedure TbrFrameSet.RefreshTimerTimer(Sender: Tobject);
begin
RefreshTimer.Enabled := False;
if (Self = MasterSet.FrameViewer.CurbrFrameSet) then
FrameViewer.LoadURLInternal(NextFile, '', True, True)
end;

{----------------TbrFrameSet.LoadFromBrzFile}
procedure TbrFrameSet.LoadFromBrzFile(Stream: TMemoryStream; StreamType: TFileType;
               const URL, Dest: string);
var
  I: integer;
  Item: TbrFrameBase;
  Frame: TbrFrame;
  Lower, Upper: boolean;
  LStyle: LoadStyleType;
begin
Clear;
NestLevel := 0;
AssignStr(FCurrentFile, URL);
LStyle := lsStream;
if (StreamType = HTMLType) and
      IsFrameFile(LStyle, '', Nil, Stream, Nil, 0, MasterSet.FrameViewer) then
  begin    {it's a Frameset html file}
  FrameParseFile(FrameViewer, Self, LStyle, '', Nil, Stream, Nil, 0, HandleMeta);
  for I := 0 to List.Count-1 do
    Begin
    Item := TbrFrameBase(List.Items[I]);
    TbrFrameBase(Item).LoadBrzFiles;
    end;
  CalcSizes(Self);
  CheckNoresize(Lower, Upper);
  if FRefreshDelay > 0 then
    SetRefreshTimer;
  end
else
  begin   {it's a non frame file}
  Frame := AddFrame(Nil, '');
  Frame.Source := NewStr(URL);
  Frame.TheStream := Stream;
  Frame.TheStreamType := StreamType;
  Frame.Destination := NewStr(Dest);
  EndFrameSet;
  CalcSizes(Self);
  Frame.LoadBrzFiles;
  AssignStr(FTitle, ReadHTML.Title);
  AssignStr(FBaseTarget, ReadHTML.BaseTarget);
  end;
end;

{----------------TbrFrameSet.ClearForwards}
procedure TbrFrameSet.ClearForwards;
{clear all the forward items in the history lists}
var
  I, J: integer;
  Frame: TbrFrame;
  AList: TList;
  Obj: TObject;
begin
AList := TList.Create;
for J := 0 to Frames.Count-1 do
  begin
  Frame := TbrFrame(Frames[J]);
  with Frame do
    begin
    for I := 0 to frHistoryIndex-1 do
      begin
      Obj := frHistory.Objects[0];
      if Assigned(Obj) and (AList.IndexOf(Obj) < 0) then
        AList.Add(Obj);
      frHistory.Delete(0);
      PositionObj(frPositionHistory[0]).Free;
      frPositionHistory.Delete(0);
      end;
    frHistoryIndex := 0;
    end;
  end;
for J := 0 to Frames.Count-1 do {now see which Objects are no longer used}
  begin
  Frame := TbrFrame(Frames[J]);
  with Frame do
    begin
    for I := 0 to frHistory.Count-1 do
      begin
      Obj := frHistory.Objects[I];
      if Assigned(Obj) and (AList.IndexOf(Obj) > -1) then
        AList.Remove(Obj);  {remove it if it's there}     
      end;
    end;
  end;
for I := 0 to AList.Count-1 do   {destroy what's left}
  TObject(AList[I]).Free;   
AList.Free;
end;

{----------------TbrFrameSet.UpdateFrameList}
procedure TbrFrameSet.UpdateFrameList;  
{Fill Frames with a list of all current TFrames}
begin
Frames.Clear;
inherited UpdateFrameList;
end;

{----------------TFrameBrowser.Create}
constructor TFrameBrowser.Create(AOwner: TComponent);
begin
inherited Create(AOwner);
Height := 150;
Width := 150;
FURL := NullStr;
FTarget := NullStr;
FBaseEx := NullStr;
ProcessList := TList.Create;
FViewImages := True;
FImageCacheCount := 5;
FHistory := TStringList.Create;
FPosition := TList.Create;
FTitleHistory := TStringList.Create;
FBackground := clBtnFace;
FFontColor := clBtnText;
FHotSpotColor := clBlue;
FVisitedColor := clPurple;   
FOverColor := clBlue;
FVisitedMaxCount := 50;    
FFontSize := 12;
FFontName := NewStr('Times New Roman');
FPreFontName := NewStr('Courier New');
FCursor := ThickIBeamCursor;  
FDither := True;
TabStop := False;
FPrintMarginLeft := 2.0;
FPrintMarginRight := 2.0;
FPrintMarginTop := 2.0;
FPrintMarginBottom := 2.0;
{$ifdef Delphi3_4_CppBuilder3_4}  {Delphi 3, C++Builder 3, 4}
FCharset := DEFAULT_CHARSET;
{$endif}
Visited := TStringList.Create;

CurbrFrameSet := TbrFrameSet.Create(Self);
if fvNoBorder in FOptions then
  begin                  
  CurbrFrameSet.OuterBorder := 0;
  CurbrFrameSet.BevelOuter := bvNone;
  end
else
  begin
  CurbrFrameSet.OuterBorder := 2;
  CurbrFrameSet.BevelWidth := 2;
  CurbrFrameSet.BevelOuter := bvLowered;
  end;
CurbrFrameSet.Align := alClient;
InsertControl(CurbrFrameSet);
end;

{----------------TFrameBrowser.Destroy}
destructor TFrameBrowser.Destroy;
begin
DisposeStr(FURL);
DisposeStr(FTarget);
DisposeStr(FBaseEx);
DisposeStr(FFontName);
DisposeStr(FPreFontName);
ProcessList.Free;
FHistory.Free;
FPosition.Free;
FTitleHistory.Free;
Visited.Free;
inherited Destroy;
end;

{----------------TFrameBrowser.Clear}
procedure TFrameBrowser.Clear;
var
  I: integer;
  Obj: TObject;
begin
if not Processing then
  begin
  for I := 0 to FHistory.Count-1 do
    with FHistory do
      begin
      Obj := Objects[0];
      Delete(0);
      if Obj <> CurbrFrameSet then
        ChkFree(Obj);
      end;
  with CurbrFrameSet do
    begin
    Clear;
    BevelOuter := bvLowered;
    BevelWidth := 2;
    end;
  DisposeStr(FURL);  FURL := NullStr;
  DisposeStr(FTarget);  FTarget := NullStr;
  AssignStr(FBaseEx, '');
  FHistoryIndex := 0;
  FPosition.Clear;
  FTitleHistory.Clear;
  if Assigned(FOnHistoryChange) then
    FOnHistoryChange(Self);
  Visited.Clear;
  end;
end;


{----------------TFrameBrowser.LoadURL}
procedure TFrameBrowser.LoadURL(const URL: string);
begin
if not Processing then
  begin
  LoadURLInternal(Normalize(URL), '', True, False);
  end;
end;

{----------------TFrameBrowser.LoadURLInternal}
procedure TFrameBrowser.LoadURLInternal(const URL, Query: string; IsGet, Reload: boolean);
var
  OldFrameSet: TbrFrameSet;
  OldFile, S, Dest, S1: string;
  OldPos: LongInt;
  Tmp: TObject;
  SameName: boolean;
  {$ifdef Windows}
  Dummy: integer;
  {$endif}
  Stream: TMemoryStream;
  StreamType: TFileType;
  I: integer;
begin
if not Assigned(FOnGetPostRequest) then
  Raise(Exception.Create('No OnGetPostRequest event defined'));
FProcessing := True;
if Assigned(FOnProcessing) then
  FOnProcessing(Self, True);
{$ifdef windows}
Dummy :=
{$endif}
IOResult;     {remove any pending file errors}
SplitURL(URL, S, Dest);
try
  OldFile := CurbrFrameSet.FCurrentFile^;
  ProcessList.Clear;
  if Assigned(FOnSoundRequest) then
    FOnSoundRequest(Self, '', 0, True);
  SameName := CompareText(OldFile, S) = 0;
  if not SameName then
    begin
    if Assigned(FOnViewerClear) then
      for I := 0 to CurbrFrameSet.Viewers.Count-1 do
        FOnViewerClear(CurbrFrameSet.Viewers[I]);
    OldFrameSet := CurbrFrameSet;
    CurbrFrameSet := TbrFrameSet.Create(Self);
          CurbrFrameSet.Align := alClient;
    CurbrFrameSet.visible := False;
    InsertControl(CurbrFrameSet);
    CurbrFrameSet.SendToBack;
    CurbrFrameSet.Visible := True;

    try
      S1 := '';
      FOnGetPostRequest(Self, IsGet, S, Query, Reload, S1, StreamType, Stream);
      if not Assigned(Stream) then
        Raise(EInOutError.Create('Can''t load: '+S));
      if S1 <> '' then
        S := S1;

      if Pos(':', S) <> 0 then
        CurbrFrameSet.URLBase := URLSubs.GetBase(S)
      else
        begin
        CurbrFrameSet.URLBase := OldFrameSet.URLBase;
        S := Combine(CurbrFrameSet.URLBase, S);
        end;

      (CurbrFrameSet as TbrFrameSet).LoadFromBrzFile(Stream, StreamType, S, Dest);
    except
      RemoveControl(CurbrFrameSet);
      CurbrFrameSet.Free;
      CurbrFrameSet := OldFrameSet;
      Raise;
      end;

    OldPos := 0;
    if (OldFrameSet.Viewers.Count = 1) then
      begin
      Tmp := OldFrameSet.Viewers[0];
      if Tmp is ThtmlViewer then
        OldPos := ThtmlViewer(Tmp).Position;
      end;
    OldFrameSet.UnloadFiles;
    CurbrFrameSet.Visible := True;
    CurbrFrameSet.RePaint;
    RemoveControl(OldFrameSet);
    BumpHistory(OldFrameSet, OldPos);
    end
  else
    begin    {Same name}
    OldPos := 0;
    if (CurbrFrameSet.Viewers.Count = 1) then
      begin
      Tmp := CurbrFrameSet.Viewers[0];
      if Tmp is ThtmlViewer then
        OldPos := ThtmlViewer(Tmp).Position;
      end;
    FOnGetPostRequest(Self, IsGet, S, Query, Reload, S1, StreamType, Stream);  {S1 not expected to change here}
    if not Assigned(Stream) then
      Raise(EInOutError.Create('Can''t locate cache file: '+S));
    (CurbrFrameSet as TbrFrameSet).LoadFromBrzFile(Stream, StreamType, S, Dest);
    BumpHistory2(OldPos);   {not executed if exception occurs}
    end;
  AddVisitedLink(URL);
finally
  FProcessing := False;
  if Assigned(FOnProcessing) then
    FOnProcessing(Self, False);
  end;
end;

{----------------TFrameBrowser.Reload}
procedure TFrameBrowser.Reload;
begin
FProcessing := True;
if Assigned(FOnProcessing) then
  FOnProcessing(Self, True);
try
  ProcessList.Clear;
  SendMessage(Self.handle, wm_SetRedraw, 0, 0);
  try
    CurbrFrameSet.UnloadFiles;
    CurbrFrameSet.ReloadFiles(-1);
  finally
    SendMessage(Self.handle, wm_SetRedraw, 1, 0);
    end;
  CheckVisitedLinks;    
finally
  FProcessing := False;
  if Assigned(FOnProcessing) then
    FOnProcessing(Self, False);
  end;
end;

{----------------TFrameBrowser.GetFwdButtonEnabled}
function TFrameBrowser.GetFwdButtonEnabled: boolean;
var
  I: integer;
  Frame: TbrFrame;
begin
Result := fHistoryIndex >= 1;
if not Result then
  for I := 0 to CurbrFrameSet.Frames.Count-1 do
    begin
    Frame := TbrFrame(CurbrFrameSet.Frames[I]);
    with Frame do
      if frHistoryIndex >= 1 then
        begin
        Result := True;
        Exit;
        end;
    end;
end;

{----------------TFrameBrowser.GetBackButtonEnabled}
function TFrameBrowser.GetBackButtonEnabled: boolean;
var
  I: integer;
  Frame: TbrFrame;
begin
Result := fHistoryIndex <= fHistory.Count-2;
if not Result then
  for I := 0 to CurbrFrameSet.Frames.Count-1 do
    begin
    Frame := TbrFrame(CurbrFrameSet.Frames[I]);
    with Frame do
      if frHistoryIndex <= frHistory.Count-2 then
        begin
        Result := True;
        Exit;
        end;
    end;
end;

procedure TFrameBrowser.GoFwd;
var
  I, Smallest, Index: integer;
  Frame, TheFrame: TbrFrame;
begin
Smallest := 9999;
Index := 0; TheFrame := Nil;   {to quiet the warnings}
for I := 0 to CurbrFrameSet.Frames.Count-1 do
  begin
  Frame := TbrFrame(CurbrFrameSet.Frames[I]);
  with Frame do
    if frHistoryIndex >= 1 then
      with PositionObj(frPositionHistory[frHistoryIndex-1]) do
        if Seq < Smallest then
          begin
          Smallest := Seq;
          TheFrame := Frame;
          Index := frHistoryIndex;
          end;
  end;
if Smallest < 9999 then
  TheFrame.frSetHistoryIndex(Index - 1)
else SetHistoryIndex(fHistoryIndex - 1);
if Assigned(FOnSoundRequest) then
  FOnSoundRequest(Self, '', 0, True);
end;

procedure TFrameBrowser.GoBack;
var
  I, Largest, Index: integer;
  Frame, TheFrame: TbrFrame;
begin
Largest := -1;
Index := 0; TheFrame := Nil;   {to quiet the warnings}
for I := 0 to CurbrFrameSet.Frames.Count-1 do
  begin
  Frame := TbrFrame(CurbrFrameSet.Frames[I]);
  with Frame do
    if frHistoryIndex <= frHistory.Count-2 then
      with PositionObj(frPositionHistory[frHistoryIndex]) do
        if Seq > Largest then
          begin
          Largest := Seq;
          TheFrame := Frame;
          Index := frHistoryIndex;
          end;
  end;
if Largest >= 0 then
  TheFrame.frSetHistoryIndex(Index + 1)
else
  SetHistoryIndex(fHistoryIndex+1);
if Assigned(FOnSoundRequest) then
  FOnSoundRequest(Self, '', 0, True);
end;

{----------------TFrameBrowser.HotSpotClickHandled:}
function TFrameBrowser.HotSpotClickHandled(const FullUrl: string): boolean;
var
  Handled: boolean;
begin
Handled := False;
if Assigned(FOnHotSpotTargetClick) then
  FOnHotSpotTargetClick(Self, FTarget^, FullUrl, Handled);
Result := Handled;
end;

{----------------TFrameBrowser.HotSpotClick}
procedure TFrameBrowser.HotSpotClick(Sender: TObject; const AnURL: string;
          var Handled: boolean);
var
  I: integer;
  Viewer: ThtmlViewer;
  FrameTarget: TbrFrameBase;
  S, Dest, FullUrl: string;

begin
if Processing then
  begin
  Handled := True;
  Exit;
  end;
Viewer := (Sender as ThtmlViewer);
AssignStr(FURL, AnURL);
AssignStr(FTarget, GetActiveTarget);
SplitUrl(AnUrl, S, Dest);
if Pos('\', S) > 0 then    {convert DOS names}
  begin
  S := DosToHTML(S);
  if Pos('|', S) > 0 then
    S := 'file:///'+S;
  end;
if S = '' then
  FullUrl := (Viewer.FrameOwner as TbrFrame).Source^
else if IsFullURL(S) then
  FullUrl := S
else
  FullUrl := Combine((Viewer.FrameOwner as TbrFrame).URLBase, S);

Handled := HotSpotClickHandled(FullUrl + Dest);

if not Handled then
  begin
  Handled := True;
  if (FTarget^ = '') or (CompareText(FTarget^, '_self') = 0) then  {no target or _self target}
    begin
    FrameTarget := Viewer.FrameOwner as TbrFrame;
    if not Assigned(FrameTarget) then Exit;
    end
  else if CurbrFrameSet.FrameNames.Find(FTarget^, I) then
    FrameTarget := (CurbrFrameSet.FrameNames.Objects[I] as TbrFrame)
  else if CompareText(FTarget^, '_top') = 0 then
    FrameTarget := CurbrFrameSet
  else if CompareText(FTarget^, '_parent') = 0 then
    begin
    FrameTarget := (Viewer.FrameOwner as TbrFrame).Owner as TbrFrameBase;
    while Assigned(FrameTarget) and not (FrameTarget is TbrFrame)
              and not (FrameTarget is TbrFrameSet) do
       FrameTarget := FrameTarget.Owner as TbrFrameBase;
    end
  else
    begin
    if Assigned(FOnBlankWindowRequest) then
      begin
      AddVisitedLink(FullUrl + Dest);
      CheckVisitedLinks;
      FOnBlankWindowRequest(Self, FTarget^, FullUrl + Dest);
      Handled := True;
      end
    else Handled := FTarget^ <> '';   {true if can't find target window}
    Exit;
    end;

  FProcessing := True;
  if Assigned(FOnProcessing) then
    FOnProcessing(Self, True);
  if (FrameTarget is TbrFrame) and (CurbrFrameSet.Viewers.Count = 1) and (S <> '')
        and (CompareText(S, CurbrFrameSet.FCurrentFile^) <> 0) then
    FrameTarget := CurbrFrameSet;  {force a new FrameSet on name change}
  try
    if FrameTarget is TbrFrame then
      TbrFrame(FrameTarget).frLoadFromBrzFile(FullUrl, Dest, '', True, True, False)
    else if FrameTarget is TbrFrameSet then
      Self.LoadURLInternal(FullUrl + Dest, '', True, False);
    CheckVisitedLinks;    
  finally
    FProcessing := False;     {changed position}
    if Assigned(FOnProcessing) then
      FOnProcessing(Self, False);
    end;
  end;
end;

function TFrameBrowser.GetCurViewerCount: integer;
begin
   Result := CurbrFrameSet.Viewers.Count;
end;

function TFrameBrowser.GetCurViewer(I: integer): ThtmlViewer;
begin
   Result := CurbrFrameSet.Viewers[I];
end;

{----------------TFrameBrowser.HotSpotCovered}
procedure TFrameBrowser.HotSpotCovered(Sender: TObject; const SRC: string);
begin
if Assigned(FOnHotSpotTargetCovered) then
  FOnHotSpotTargetCovered(Sender, (Sender as ThtmlViewer).Target, Src);
end;

{----------------TFrameBrowser.GetActiveTarget}
function TFrameBrowser.GetActiveTarget: string;
var
   Vw: ThtmlViewer;
   Done: boolean;
   FSet: TbrSubFrameSet;
begin          
Result := '';
Vw := GetActiveViewer;
if Assigned(Vw) then
  begin
  Result := Vw.Target;
  if Result = '' then Result := Vw.BaseTarget;
  Done := False;
  FSet := TbrFrame(Vw.FrameOwner).LOwner;
  while (Result = '') and Assigned(FSet) and not Done do
    begin
    Result := FSet.FBaseTarget^;
    Done := FSet = CurbrFrameSet;
    if not Done then FSet := FSet.LOwner;
    end;
  end;
end;

function TFrameBrowser.GetBase: string;
begin
Result := CurbrFrameSet.FBase^;
end;

procedure TFrameBrowser.SetBase(Value: string);
begin
AssignStr(CurbrFrameSet.FBase, Value);
AssignStr(FBaseEx, Value);
end;

function TFrameBrowser.GetBaseTarget: string;
begin
Result := CurbrFrameSet.FBaseTarget^;
end;

function TFrameBrowser.GetTitle: string;
begin
Result := CurbrFrameSet.FTitle^;
end;

function TFrameBrowser.GetCurrentFile: string;
begin
Result := CurbrFrameSet.FCurrentFile^;
end;

{----------------TFrameBrowser.GetActiveViewer}
function TFrameBrowser.GetActiveViewer: ThtmlViewer;
begin
Result := CurbrFrameSet.GetActive;
end;

{----------------TFrameBrowser.BumpHistory}
procedure TFrameBrowser.BumpHistory(OldFrameSet: TbrFrameSet; OldPos: LongInt);
{OldFrameSet never equals CurbrFrameSet when this method called}
var
  I: integer;
  Obj: TObject;
begin
if (FHistoryMaxCount > 0) and (CurbrFrameSet.FCurrentFile^ <> '') then
  with FHistory do
    begin
    if (Count > 0) then
      begin
      Strings[FHistoryIndex] := OldFrameSet.FCurrentFile^;
      Objects[FHistoryIndex] := OldFrameSet;
      FTitleHistory[FHistoryIndex] := OldFrameSet.FTitle^;
      FPosition[FHistoryIndex] := TObject(OldPos);
      OldFrameSet.ClearForwards;
      end
    else OldFrameSet.Free;
    for I := 0 to FHistoryIndex-1 do
      begin
      Obj := Objects[0];
      Delete(0);
      ChkFree(Obj);
      FTitleHistory.Delete(0);
      FPosition.Delete(0);
      end;
    FHistoryIndex := 0;
    Insert(0, CurbrFrameSet.FCurrentFile^);
    Objects[0] := CurbrFrameSet;
    FTitleHistory.Insert(0, CurbrFrameSet.FTitle^);
    FPosition.Insert(0, Nil);
    if Count > FHistoryMaxCount then
      begin
      Obj := Objects[FHistoryMaxCount];
      Delete(FHistoryMaxCount);
      ChkFree(Obj);
      FTitleHistory.Delete(FHistoryMaxCount);
      FPosition.Delete(FHistoryMaxCount);
      end;
    if Assigned(FOnHistoryChange) then FOnHistoryChange(Self);
    end
else OldFrameSet.Free;
end;

{----------------TFrameBrowser.BumpHistory1}
procedure TFrameBrowser.BumpHistory1(const FileName, Title: string;
                 OldPos: LongInt; ft: TFileType);
{This variation called when CurbrFrameSet contains only a single viewer before
 and after the change}
var
  I: integer;
  Obj: TObject;
begin
if (FHistoryMaxCount > 0) and (Filename <> '') then
  with FHistory do
    begin
    if (Count > 0) then
      begin
      Strings[FHistoryIndex] := Filename;
      Objects[FHistoryIndex] := CurbrFrameSet;
      FTitleHistory[FHistoryIndex] := Title;
      FPosition[FHistoryIndex] := TObject(OldPos);
      end;
    for I := 0 to FHistoryIndex-1 do
      begin
      Obj := Objects[0];
      Delete(0);
      ChkFree(Obj);
      FTitleHistory.Delete(0);
      FPosition.Delete(0);
      end;
    FHistoryIndex := 0;
    Insert(0, CurbrFrameSet.FCurrentFile^);
    Objects[0] := CurbrFrameSet;
    FTitleHistory.Insert(0, CurbrFrameSet.FTitle^);
    FPosition.Insert(0, Nil);
    if Count > FHistoryMaxCount then
      begin
      Obj := Objects[FHistoryMaxCount];
      Delete(FHistoryMaxCount);
      ChkFree(Obj);
      FTitleHistory.Delete(FHistoryMaxCount);
      FPosition.Delete(FHistoryMaxCount);
      end;
    if Assigned(FOnHistoryChange) then FOnHistoryChange(Self);
    end;
end;

{----------------TFrameBrowser.BumpHistory2}
procedure TFrameBrowser.BumpHistory2(OldPos: LongInt);
{CurbrFrameSet has not changed when this method called}
var
  I: integer;
  Obj: TObject;
begin
if (FHistoryMaxCount > 0) and (CurbrFrameSet.FCurrentFile^ <> '') then
  with FHistory do
    begin
    if (Count > 0) then
      begin
      Strings[FHistoryIndex] := CurbrFrameSet.FCurrentFile^;
      Objects[FHistoryIndex] := CurbrFrameSet;
      FTitleHistory[FHistoryIndex] := CurbrFrameSet.FTitle^;
      FPosition[FHistoryIndex] := TObject(OldPos);
      end;
    for I := 0 to FHistoryIndex-1 do
      begin
      Obj := Objects[0];
      Delete(0);
      ChkFree(Obj);
      FTitleHistory.Delete(0);
      FPosition.Delete(0);
      end;
    FHistoryIndex := 0;
    Insert(0, CurbrFrameSet.FCurrentFile^);
    Objects[0] := CurbrFrameSet;
    FTitleHistory.Insert(0, CurbrFrameSet.FTitle^);
    FPosition.Insert(0, Nil);
    if Count > FHistoryMaxCount then
      begin
      Obj := Objects[FHistoryMaxCount];
      Delete(FHistoryMaxCount);
      ChkFree(Obj);
      FTitleHistory.Delete(FHistoryMaxCount);
      FPosition.Delete(FHistoryMaxCount);
      end;
    if Assigned(FOnHistoryChange) then FOnHistoryChange(Self);
    end;
end;

{----------------TFrameBrowser.SetHistoryIndex}
procedure TFrameBrowser.SetHistoryIndex(Value: integer);
var
  FrameSet, FrameSet1: TbrFrameSet;  
  Tmp: TObject;
begin
with CurbrFrameSet, FHistory do
  if (Value <> FHistoryIndex) and (Value >= 0) and (Value < Count)
            and not Processing then
    begin
    if CurbrFrameSet.Viewers.Count > 0 then
      Tmp := CurbrFrameSet.Viewers[0]
    else Tmp := Nil;
    if FCurrentFile^ <> '' then
      begin
      {Objects[FHistoryIndex] should have CurbrFrameSet here}
      FTitleHistory[FHistoryIndex] := CurbrFrameSet.FTitle^;
      if (Tmp is ThtmlViewer) then
        FPosition[FHistoryIndex] := TObject((Tmp as ThtmlViewer).Position)
      else  FPosition[FHistoryIndex] := Nil;
      end;
    FrameSet := Objects[Value] as TbrFrameSet;
    if FrameSet <> CurbrFrameSet then
      begin
      FrameSet1 := CurbrFrameSet;   {swap framesets} 
      CurbrFrameSet := FrameSet;
      CurbrFrameSet.OldWidth := 0;    {encourage recalc of internal layout}
      CurbrFrameSet.Visible := False;
      Self.InsertControl(CurbrFrameSet);
      if CurbrFrameSet.Viewers.Count = 1 then
        CurbrFrameSet.ReloadFiles(LongInt(FPosition[Value]))
      else
        CurbrFrameSet.ReloadFiles(-1);
      SendMessage(Self.handle, wm_SetRedraw, 0, 0);
      CurbrFrameSet.Visible := True;
      SendMessage(Self.handle, wm_SetRedraw, 1, 0);
      CurbrFrameSet.Repaint;
      FrameSet1.Unloadfiles;
      Self.RemoveControl(FrameSet1);
      end
    else
      begin
      if  (Tmp is ThtmlViewer) then
        TbrFrame(ThtmlViewer(Tmp).FrameOwner).ReloadFile(FHistory[Value],
                          LongInt(FPosition[Value]));
      end;

    FHistoryIndex := Value;
    if Assigned(FOnHistoryChange) then FOnHistoryChange(Self);
    CheckVisitedLinks;
    end;
end;

{----------------TFrameBrowser.ChkFree}
procedure TFrameBrowser.ChkFree(Obj: TObject);
{Frees a TbrFrameSet only if it no longer exists in FHistory}
var
  I: integer;
begin
for I := 0 to FHistory.Count-1 do
  if Obj = FHistory.Objects[I] then Exit;
(Obj as TbrFrameSet).Free;
end;

{----------------TFrameBrowser.ClearHistory}
procedure TFrameBrowser.ClearHistory;
var
  I: integer;
  Obj: TObject;
  DidSomething: boolean;
begin
DidSomething := FHistory.Count > 0;
for I := FHistory.Count-1 downto 0 do
  begin
  Obj := FHistory.Objects[I];
  FHistory.Delete(I);
  if Obj <> CurbrFrameSet then
    ChkFree(Obj);
  end;
if Assigned(CurbrFrameSet) then
  for I := 0 to CurbrFrameSet.Frames.Count-1 do
    with TbrFrame(CurbrFrameSet.Frames[I]) do
      begin
      DidSomething := DidSomething or (frHistory.Count > 0);
      frHistoryIndex := 0;
      frHistory.Clear;
      frPositionHistory.Clear;
      end;
FHistory.Clear;
FTitleHistory.Clear;
FPosition.Clear;
FHistoryIndex := 0;
if DidSomething and Assigned(FOnHistoryChange) then
  FOnHistoryChange(Self);
end;

function TFrameBrowser.ViewerFromTarget(const Target: string): ThtmlViewer;
var
  I: integer;
begin
if Assigned(CurbrFrameSet) and Assigned(CurbrFrameSet.FrameNames)
     and CurbrFrameSet.FrameNames.Find(Target, I)
     and (CurbrFrameSet.FrameNames.Objects[I] <> Nil)
     and Assigned((CurbrFrameSet.FrameNames.Objects[I] as TbrFrame).Viewer) then
  Result := TbrFrame(CurbrFrameSet.FrameNames.Objects[I]).Viewer as ThtmlViewer
else Result := Nil;
end;

procedure TFrameBrowser.RePaint;
begin
if Assigned(CurbrFrameSet) then
  CurbrFrameSet.RePaint;
end;

procedure TFrameBrowser.SetOptions(Value: TFrameViewerOptions);
var
  I: integer;
begin
if (fvNoBorder in FOptions) <> (fvNoBorder in Value) then
  if fvNoBorder in Value then
    begin                  
    CurbrFrameSet.OuterBorder := 0;
    CurbrFrameSet.BevelOuter := bvNone;
    end
  else
    begin
    CurbrFrameSet.OuterBorder := 2;
    CurbrFrameSet.BevelWidth := 2;
    CurbrFrameSet.BevelOuter := bvLowered;
    end;
for I := 0 to CurbrFrameSet.Viewers.Count-1 do
  with ThtmlViewer(CurbrFrameSet.Viewers[I]) do
    begin
    if (fvOverLinksActive in Value) then
      htOptions := htOptions + [htOverLinksActive]
    else htOptions := htOptions - [htOverLinksActive];

    if (fvNoLinkUnderline in Value) then
      htOptions := htOptions + [htNoLinkUnderline]
    else htOptions := htOptions - [htNoLinkUnderline];

    if (fvPrintTableBackground in Value) then
      htOptions := htOptions + [htPrintTableBackground]
    else htOptions := htOptions - [htPrintTableBackground];
    end;
FOptions := Value;
end;

procedure TFrameBrowser.AddFrame(FrameSet: TObject; Attr: TAttributeList; const FName: string);
begin
(FrameSet as TbrSubFrameSet).AddFrame(Attr, FName);
end;

function TFrameBrowser.CreateSubFrameSet(FrameSet: TObject): TObject;
var
  NewFrameSet, FS: TbrSubFrameSet;
begin
FS := (FrameSet as TbrSubFrameSet);
NewFrameSet := TbrSubFrameSet.CreateIt(FS, CurbrFrameSet);
FS.List.Add(NewFrameSet);
FS.InsertControl(NewFrameSet);
Result := NewFrameSet;
end;

procedure TFrameBrowser.DoAttributes(FrameSet: TObject; Attr: TAttributeList);
begin
(FrameSet as TbrSubFrameSet).DoAttributes(Attr); 
end;

procedure TFrameBrowser.EndFrameSet(FrameSet: TObject);
begin
(FrameSet as TbrSubFrameSet).EndFrameSet;
end;

{----------------TFrameBrowser.SetOnImageRequest}
procedure TFrameBrowser.SetOnImageRequest(const Value: TGetImageEvent);
var
  I: integer;
begin
FOnImageRequest := Value;
with CurbrFrameSet do
  for I := 0 to Viewers.Count-1 do
    with ThtmlViewer(Viewers[I]) do
      OnImageRequest := Value;
end;

{----------------TFrameBrowser.DoFormSubmitEvent}
procedure TFrameBrowser.DoFormSubmitEvent(Sender: TObject; const Action, Target, EncType,
  Method: string; Results: TStringList);
var
  S, Dest, Query: string;
  FrameTarget: TbrFrameBase;
  I: integer;
  Viewer: ThtmlViewer;

  function AssembleQuery: string;
  var
    S1: string;
    I, J: integer;

    function Encode(const S: string): string;
    var
      Ch: char;
      I: integer;
    begin   {convert odd chars into %xx -- does not handle the '=' sign yet}
    Result := '';
    for I := 1 to Length(S) do
      begin
      Ch := S[I];
      if Ch = ' ' then Result := Result+'+'
      else if not (Ch in ['a'..'z', 'A'..'Z', '0'..'9', '=', '_','-','.','*','@']) then
         Result := Result+'%'+IntToHex(ord(Ch),2)
      else Result := Result+Ch;
      end;
    end;

  begin
  Result := '';   
  for I := 0 to Results.Count-1 do
    begin   {form a string from the TStringList using '+' for spaces and '&' for separaters}
    S1 := Encode(Trim(Results[I]));
    J := Pos(' ', S1);
    while J > 0 do
      begin
      S1[J] := '+';
      J := Pos(' ', S1);
      end;
    if I <> 0 then Result := Result + '&';
    Result := Result + S1;
    end;
  Results.Free;
  end;

begin
Query := AssembleQuery;
Viewer := (Sender as ThtmlViewer);

if (Target = '') or (CompareText(Target, '_self') = 0) then  {no target or _self target}
  FrameTarget := Viewer.FrameOwner as TbrFrame
else if CurbrFrameSet.FrameNames.Find(Target, I) then
  FrameTarget := (CurbrFrameSet.FrameNames.Objects[I] as TbrFrame)
else if CompareText(Target, '_top') = 0 then
  FrameTarget := CurbrFrameSet
else if CompareText(Target, '_parent') = 0 then
  begin
  FrameTarget := (Viewer.FrameOwner as TbrFrame).Owner as TbrFrameBase;
  while Assigned(FrameTarget) and not (FrameTarget is TbrFrame)
            and not (FrameTarget is TbrFrameSet) do
     FrameTarget := FrameTarget.Owner as TbrFrameBase;
  end
else
  begin
  if Assigned(FOnBlankWindowRequest) then
    FOnBlankWindowRequest(Self, Target, Action+'?'+Query);
  Exit;
  end;

S := Action;
I := Pos('#', S);
if I >= 1 then
  begin
  Dest := System.Copy(S, I, 255);  {local destination}
  S := System.Copy(S, 1, I-1);     {the file name}
  end
else
  Dest := '';    {no local destination}

FProcessing := True;
if Assigned(FOnProcessing) then
  FOnProcessing(Self, True);
if (FrameTarget is TbrFrame) and (CurbrFrameSet.Viewers.Count = 1) and (S <> '')
      and (CompareText(S, CurbrFrameSet.FCurrentFile^) <> 0) then
  FrameTarget := CurbrFrameSet;  {force a new FrameSet on name change}
try
  if S = '' then
    S := (Viewer.FrameOwner as TbrFrame).Source^
  else if not IsFullURL(S) then
    S := Combine((Viewer.FrameOwner as TbrFrame).URLBase, S);
  if FrameTarget is TbrFrame then
    TbrFrame(FrameTarget).frLoadFromBrzFile(S, Dest, Query, True, CompareText(Method, 'get') = 0, True)
  else if FrameTarget is TbrFrameSet then
    Self.LoadURLInternal(S + Dest, Query, CompareText(Method, 'get') = 0, True);
finally
  FProcessing := False;
  if Assigned(FOnProcessing) then
    FOnProcessing(Self, False);
  end;
end;

{----------------TFrameBrowser.GetViewerUrlBase}
function TFrameBrowser.GetViewerUrlBase(Viewer: ThtmlViewer): string;
var
  Frame: TbrFrame;
begin
try
  Frame := (Viewer as ThtmlViewer).FrameOwner as TbrFrame;
  Result := Frame.UrlBase;
except
  Result := '';
  end;
end;

{----------------TFrameBrowser.AddVisitedLink}
procedure TFrameBrowser.AddVisitedLink(const S: string);
var
  I: integer;
begin
if (FVisitedMaxCount = 0) then
  Exit;
I := Visited.IndexOf(S);
if I = 0 then
  Exit
else if I > 0 then
  Visited.Delete(I);   {thus moving it to the top}
Visited.Insert(0, S);
for I :=  Visited.Count-1 downto FVisitedMaxCount do
  Visited.Delete(I);
end;

{----------------TFrameBrowser.CheckVisitedLinks}
procedure TFrameBrowser.CheckVisitedLinks;
var
  I, J, K: integer;
  S, S1: string;
  Viewer: ThtmlViewer;
begin
if FVisitedMaxCount = 0 then
  Exit;
for K := 0 to CurbrFrameSet.Viewers.Count-1 do
  begin
  Viewer := ThtmlViewer(CurbrFrameSet.Viewers[K]);
  for I := 0 to Visited.Count-1 do
    begin
    S := Visited[I];
    for J := 0 to Viewer.LinkList.Count-1 do
      with TFontObj(Viewer.LinkList[J]) do
        begin
        if Url <> '' then
          begin
          if IsFullURL(Url) then
            S1 := Url
          else if Url[1] = '#' then
            S1 :=  TbrFrame(Viewer.FrameOwner).Source^+Url
          else S1 := Combine(TbrFrame(Viewer.FrameOwner).UrlBase, Url);
          if CompareText(S, S1) = 0 then
            Visited := True;
          end;
        end;
    end;
  Viewer.Invalidate;
  end;
end;

{----------------TFMBEditor.GetVerbCount:}
function TFMBEditor.GetVerbCount: integer;
begin
  Result := 1;
end;

function TFMBEditor.GetVerb(index: Integer): string;
begin
  Result := 'About..';
end;

procedure TFMBEditor.ExecuteVerb(index:integer);
begin
  MessageDlg('TFrameBrowser'+#13#13+
             'Version     : '+VersionNo+#13#13+
             'Copyright  : 1995-9 by L. David Baldwin, All Rights Reserved'+#13#13+
             'Support    : dbaldwin@pbear.com'+#13#13+
             'Web Site : http://www.pbear.com/ '
             ,mtInformation,[mbOk],0)
end;

{----------------Register}
procedure Register;
begin
RegisterComponents('Samples', [TFrameBrowser]);
RegisterComponentEditor(TFrameBrowser, TFMBEditor);
end;

end.

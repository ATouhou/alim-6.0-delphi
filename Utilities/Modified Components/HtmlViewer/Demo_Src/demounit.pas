unit demounit;
{A program to demonstrate the ThtmlViewer component}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, Menus, Htmlview, StdCtrls,
  Clipbrd, HTMLsubs, ShellAPI, MMSystem, MPlayer;
                                        
const
  MaxHistories = 6;  {size of History list}
type
  TForm1 = class(TForm)
    OpenDialog: TOpenDialog;
    MainMenu: TMainMenu;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    File1: TMenuItem;
    Open: TMenuItem;
    options1: TMenuItem;
    ShowImages: TMenuItem;
    Fonts: TMenuItem;
    Edit1: TEdit;
    ReloadButton: TButton;
    BackButton: TButton;
    FwdButton: TButton;
    HistoryMenuItem: TMenuItem;
    Exit1: TMenuItem;
    PrintDialog: TPrintDialog;
    About1: TMenuItem;
    Edit2: TMenuItem;
    Find1: TMenuItem;
    FindDialog: TFindDialog;
    Viewer: THTMLViewer;
    CopyItem: TMenuItem;
    N2: TMenuItem;
    SelectAllItem: TMenuItem;
    OpenTextFile: TMenuItem;
    OpenImageFile: TMenuItem;
    MediaPlayer: TMediaPlayer;
    PopupMenu: TPopupMenu;
    CopyImageToClipboard: TMenuItem;
    Viewimage: TMenuItem;
    N3: TMenuItem;
    OpenInNewWindow: TMenuItem;
    MetaTimer: TTimer;
    Print1: TMenuItem;
    Printpreview: TMenuItem;
    procedure OpenFileClick(Sender: TObject);
    procedure HotSpotChange(Sender: TObject; const URL: string);
    procedure HotSpotClick(Sender: TObject; const URL: string;
              var Handled: boolean);
    procedure ShowImagesClick(Sender: TObject);
    procedure ReloadButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FwdBackClick(Sender: TObject);
    procedure HistoryClick(Sender: TObject);
    procedure HistoryChange(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FontColorsClick(Sender: TObject);
    procedure Print1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SubmitEvent(Sender: TObject; Const AnAction, Target, EncType, Method: String;
      Results: TStringList);
    procedure Find1Click(Sender: TObject);
    procedure FindDialogFind(Sender: TObject);
    procedure ProcessingHandler(Sender: TObject; ProcessingOn: Boolean);
    procedure CopyItemClick(Sender: TObject);
    procedure Edit2Click(Sender: TObject);
    procedure SelectAllItemClick(Sender: TObject);
    procedure OpenTextFileClick(Sender: TObject);
    procedure OpenImageFileClick(Sender: TObject);
    procedure PrintFooter(Sender: TObject; Canvas: TCanvas; NumPage,
      W, H: Integer; var StopPrinting: Boolean);
    procedure PrintHeader(Sender: TObject; Canvas: TCanvas; NumPage,
      W, H: Integer; var StopPrinting: Boolean);
    procedure MediaPlayerNotify(Sender: TObject);
    procedure SoundRequest(Sender: TObject; const SRC: String;
      Loop: Integer; Terminate: Boolean);
    procedure CopyImageToClipboardClick(Sender: TObject);
    procedure ObjectClick(Sender, Obj: TObject; const OnClick: String);
    procedure ViewimageClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ViewerInclude(Sender: TObject; const Command: String;
      Params: TStrings; var Buffer: PChar; var BuffSize: Longint);
    procedure RightClick(Sender: TObject;
      Parameters: TRightClickParameters);
    procedure OpenInNewWindowClick(Sender: TObject);
    procedure MetaTimerTimer(Sender: TObject);
    procedure MetaRefreshEvent(Sender: TObject; Delay: Integer;
      const URL: String);
    procedure PrintpreviewClick(Sender: TObject);
  private
    { Private declarations }
    Histories: array[0..MaxHistories-1] of TMenuItem;
    MediaCount: integer;
    FoundObject: TImageObj;
    NewWindowFile: string;
    MS: TMemoryStream;
    NextFile, PresentFile: string;

    {$ifdef Win32}
    procedure wmDropFiles(var Message: TMessage); message wm_DropFiles;
    {$endif}
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  {$ifdef Win32}
  PreviewForm,
  {$endif}
  HTMLGif, HTMLun2, HTMLabt, Submit, ImgForm, FontDlg;

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
var
  I: integer;
begin
if Screen.Width <= 640 then
  Position := poDefault;  {keeps form on screen better}

OpenDialog.InitialDir := ExtractFilePath(ParamStr(0));

Caption := 'HTML Demo, Version '+HTMLAbt.Version;

ShowImages.Checked := Viewer.ViewImages;
Viewer.HistoryMaxCount := MaxHistories;  {defines size of history list}

for I := 0 to MaxHistories-1 do
  begin      {create the MenuItems for the history list}
  Histories[I] := TMenuItem.Create(HistoryMenuItem);
  HistoryMenuItem.Insert(I, Histories[I]);
  with Histories[I] do
    begin
    Visible := False;
    OnClick := HistoryClick;
    Tag := I;
    end;
  end;
{$ifdef Win32}
DragAcceptFiles(Handle, True);
{$endif}
end;

{$ifdef Windows}
procedure TForm1.FormShow(Sender: TObject);
begin
if (ParamCount >= 1) then
  Viewer.LoadFromFile(ParamStr(1));  {Parameter is file to load}
end;

{$else}
procedure TForm1.FormShow(Sender: TObject);
var
  S: string;
  I: integer;
begin
if (ParamCount >= 1) then
  begin            {Parameter is file to load}
  S := CmdLine;         
  I := Pos('" ', S);
  if I > 0 then
    Delete(S, 1, I+1)     {delete EXE name in quotes}
  else Delete(S, 1, Length(ParamStr(0)));  {in case no quote marks}
  I := Pos('"', S);
  while I > 0 do     {remove any quotes from parameter}
    begin
    Delete(S, I, 1);
    I := Pos('"', S);
    end;
  Viewer.LoadFromFile(HtmlToDos(Trim(S)));
  end;
end;
{$endif}

procedure TForm1.OpenFileClick(Sender: TObject);
begin
if Viewer.CurrentFile <> '' then
  OpenDialog.InitialDir := ExtractFilePath(Viewer.CurrentFile);
if OpenDialog.Execute then
  begin
  Viewer.LoadFromFile(OpenDialog.Filename);
  Caption := Viewer.DocumentTitle;
  end;
end;

procedure TForm1.HotSpotChange(Sender: TObject; const URL: string);
{mouse moved over or away from a hot spot.  Change the status line}
begin
Panel1.Caption := URL;
end;

procedure TForm1.HotSpotClick(Sender: TObject; const URL: string;
          var Handled: boolean);
{This routine handles what happens when a hot spot is clicked.  The assumption
 is made that DOS filenames are being used. .EXE, .WAV, .MID, and .AVI files are
 handled here, but other file types could be easily added.

 If the URL is handled here, set Handled to True.  If not handled here, set it
 to False and ThtmlViewer will handle it.}
const
  snd_Async = $0001;  { play asynchronously }
var
  PC: array[0..255] of char;
  S, Params: string[255];
  Ext: string[5];
  I, J, K: integer;

begin
Handled := False;
I := Pos(':', URL);
J := Pos('FILE:', UpperCase(URL));
if (I <= 2) or (J > 0) then
  begin                      {apparently the URL is a filename}
  S := URL;
  K := Pos(' ', S);     {look for parameters}
  if K = 0 then K := Pos('?', S);  {could be '?x,y' , etc}
  if K > 0 then
    begin
    Params := Copy(S, K+1, 255); {save any parameters}
    S[0] := chr(K-1);            {truncate S}
    end
  else Params := '';
  S := Viewer.HTMLExpandFileName(S);
  Ext := Uppercase(ExtractFileExt(S));
  if Ext = '.WAV' then
    begin
    Handled := True;
    sndPlaySound(StrPCopy(PC, S), snd_ASync);
    end
  else if Ext = '.EXE' then
    begin
    Handled := True;
    WinExec(StrPCopy(PC, S+' '+Params), sw_Show);
    end
  else if (Ext = '.MID') or (Ext = '.AVI')  then
    begin
    Handled := True;
    WinExec(StrPCopy(PC, 'MPlayer.exe /play /close '+S), sw_Show);
    end;
  {else ignore other extensions}
  Edit1.Text := URL;
  Exit;
  end;
{$ifdef Win32}
I := Pos('MAILTO:', UpperCase(URL));
J := Pos('HTTP:', UpperCase(URL));
if (I > 0) or (J > 0) then
  begin
  ShellExecute(0, nil, pchar(URL), nil, nil, SW_SHOWNORMAL);
  Handled := True;
  Exit;
  end;
{$endif}
Edit1.Text := URL;   {other protocall}
end;

procedure TForm1.ShowImagesClick(Sender: TObject);
{The Show Images menu item was clicked}
begin
With Viewer do
  begin
  ViewImages := not ViewImages;
  (Sender as TMenuItem).Checked := ViewImages;
  end;
end;

procedure TForm1.ReloadButtonClick(Sender: TObject);
{the Reload button was clicked}
begin
with Viewer do
  begin
  ReLoadButton.Enabled := False;
  ReLoad;
  ReLoadButton.Enabled := CurrentFile <> '';
  Viewer.SetFocus;
  end;
end;

procedure TForm1.FwdBackClick(Sender: TObject);
{Either the Forward or Back button was clicked}
begin
with Viewer do
  begin
  if Sender = BackButton then
    HistoryIndex := HistoryIndex +1
  else
    HistoryIndex := HistoryIndex -1;
  Self.Caption := DocumentTitle;      
  end;
end;

procedure TForm1.HistoryChange(Sender: TObject);
{This event occurs when something changes history list}
var
  I: integer;
  Cap: string[80];
begin
with Sender as ThtmlViewer do
  begin
  {check to see which buttons are to be enabled}
  FwdButton.Enabled := HistoryIndex > 0;
  BackButton.Enabled := HistoryIndex < History.Count-1;

  {Enable and caption the appropriate history menuitems}
  HistoryMenuItem.Visible := History.Count > 0;
  for I := 0 to MaxHistories-1 do
    with Histories[I] do
      if I < History.Count then
        Begin
        Cap := History.Strings[I];
        if TitleHistory[I] <> '' then
          Cap := Cap + '--' + TitleHistory[I];
        Caption := Cap;    {Cap limits string to 80 char}
        Visible := True;
        Checked := I = HistoryIndex;
        end
      else Histories[I].Visible := False;
  Caption := DocumentTitle;    {keep the caption updated}
  Viewer.SetFocus;  
  end;
end;

procedure TForm1.HistoryClick(Sender: TObject);
{A history list menuitem got clicked on}
begin
  {Changing the HistoryIndex loads and positions the appropriate document}
  Viewer.HistoryIndex := (Sender as TMenuItem).Tag;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
Close;
end;

procedure TForm1.FontColorsClick(Sender: TObject);
var
  FontForm: TFontForm;
begin
FontForm := TFontForm.Create(Self);
try
  with FontForm do
    begin
    FontName := Viewer.DefFontName;
    FontColor := Viewer.DefFontColor;
    FontSize := Viewer.DefFontSize;
    HotSpotColor := Viewer.DefHotSpotColor;
    Background := Viewer.DefBackground;
    if ShowModal = mrOK then
      begin
      Viewer.DefFontName := FontName;
      Viewer.DefFontColor := FontColor;
      Viewer.DefFontSize := FontSize;
      Viewer.DefHotSpotColor := HotSpotColor;
      Viewer.DefBackground := Background; 
      ReloadButtonClick(Self);    {reload to see how it looks}
      end;
    end;
finally
  FontForm.Free;
 end;
end;

procedure TForm1.Print1Click(Sender: TObject);
begin
with PrintDialog do
  if Execute then
    if PrintRange = prAllPages then
      viewer.Print(1, 9999)
    else
      Viewer.Print(FromPage, ToPage);
end;

procedure TForm1.About1Click(Sender: TObject);
begin
AboutBox := TAboutBox.CreateIt(Self, 'HTMLDemo', 'ThtmlViewer');
try
  AboutBox.ShowModal;
finally
  AboutBox.Free;
  end;
end;


procedure TForm1.SubmitEvent(Sender: TObject; const AnAction, Target, EncType, Method: String;
  Results: TStringList);
begin
with SubmitForm do
  begin
  ActionText.Text := AnAction;
  MethodText.Text := Method;
  ResultBox.Items := Results;
  Results.Free;
  Show;
  end;
end;

procedure TForm1.Find1Click(Sender: TObject);
begin
FindDialog.Execute;
end;

procedure TForm1.FindDialogFind(Sender: TObject);
begin
with FindDialog do
  begin
  if not Viewer.Find(FindText, frMatchCase in Options) then
    MessageDlg('No further occurances of "'+FindText+'"', mtInformation, [mbOK], 0);
  end;
end;

procedure TForm1.ProcessingHandler(Sender: TObject; ProcessingOn: Boolean);
begin
if ProcessingOn then
  begin    {disable various buttons and menuitems during processing}
  FwdButton.Enabled := False;
  BackButton.Enabled := False;
  ReLoadButton.Enabled := False;
  Print1.Enabled := False;
  PrintPreview.Enabled := False;
  Find1.Enabled := False;
  SelectAllItem.Enabled := False;
  Open.Enabled := False;
  end
else
  begin
  FwdButton.Enabled := Viewer.HistoryIndex > 0;
  BackButton.Enabled := Viewer.HistoryIndex < Viewer.History.Count-1;
  ReLoadButton.Enabled := Viewer.CurrentFile <> '';
  Print1.Enabled := Viewer.CurrentFile <> '';
  {$ifdef Win32}
  PrintPreview.Enabled := Viewer.CurrentFile <> '';
  {$endif}
  Find1.Enabled := Viewer.CurrentFile <> '';
  SelectAllItem.Enabled := Viewer.CurrentFile <> '';
  Open.Enabled := True;
  end;
end;

procedure TForm1.CopyItemClick(Sender: TObject);
var
  Rslt: word;
begin
Rslt := mrOK;
if Viewer.SelLength > 32000 then
  Rslt := MessageDlg('Selection exceeds buffer size and may be truncated',
    mtWarning, [mbOK, mbCancel], 0);
if Rslt = mrOK then Viewer.CopyToClipboard;
end;

procedure TForm1.Edit2Click(Sender: TObject);
begin
CopyItem.Enabled := Viewer.SelLength > 0; 
end;

procedure TForm1.SelectAllItemClick(Sender: TObject);
begin
Viewer.SelectAll;
end;

procedure TForm1.OpenTextFileClick(Sender: TObject);
begin
if Viewer.CurrentFile <> '' then
  OpenDialog.InitialDir := ExtractFilePath(Viewer.CurrentFile);
OpenDialog.Filter := 'HTML Files (*.htm,*.html)|*.htm;*.html'+
    '|Text Files (*.txt)|*.txt'+
    '|All Files (*.*)|*.*';
if OpenDialog.Execute then
  begin
  ReloadButton.Enabled := False;
  Viewer.LoadTextFile(OpenDialog.Filename);
  if Viewer.CurrentFile  <> '' then
    begin
    Caption := Viewer.DocumentTitle;
    ReLoadButton.Enabled := True;
    end;
  end;
end;

procedure TForm1.OpenImageFileClick(Sender: TObject);
begin
if Viewer.CurrentFile <> '' then
  OpenDialog.InitialDir := ExtractFilePath(Viewer.CurrentFile);
OpenDialog.Filter := 'Graphics Files (*.bmp,*.gif,*.jpg,*.jpeg,*.png)|'+
    '*.bmp;*.jpg;*.jpeg;*.gif;*.png|'+
    'All Files (*.*)|*.*';
if OpenDialog.Execute then
  begin
  ReloadButton.Enabled := False;
  Viewer.LoadImageFile(OpenDialog.Filename);
  if Viewer.CurrentFile  <> '' then
    begin
    Caption := Viewer.DocumentTitle;
    ReLoadButton.Enabled := True;
    end;
  end;
end;

{$ifdef Win32}
procedure TForm1.wmDropFiles(var Message: TMessage);
var
  S: string[200];
  Ext: string;
  Count: integer;
begin
Count := DragQueryFile(Message.WParam, 0, @S[1], 200);
Length(S) := Count;
DragFinish(Message.WParam);
if Count >0 then
  begin
  Ext := LowerCase(ExtractFileExt(S));
  if (Ext = '.htm') or (Ext = '.html') then
    Viewer.LoadFromFile(S)
  else if (Ext = '.txt') then
    Viewer.LoadTextFile(S)
  else if (Ext = '.bmp') or (Ext = '.gif') or (Ext = '.jpg')
        or (Ext = '.jpeg') or (Ext = '.png') then
    Viewer.LoadImageFile(S);
  end;
Message.Result := 0;
end;
{$endif}

procedure TForm1.PrintHeader(Sender: TObject; Canvas: TCanvas;
  NumPage, W, H: Integer; var StopPrinting: Boolean);
var
  AFont: TFont;
begin
AFont := TFont.Create;
AFont.Name := 'Arial';
AFont.Size := 8;
with Canvas do
  begin
  Font.Assign(AFont);
  SetTextAlign(Handle, TA_Top or TA_Left);
  TextOut(50, 40, Viewer.DocumentTitle);
  SetTextAlign(Handle, TA_Top or TA_Right);
  TextOut(W-50, 40, Viewer.CurrentFile);
  end;
AFont.Free;
end;

procedure TForm1.PrintFooter(Sender: TObject; Canvas: TCanvas;
  NumPage, W, H: Integer; var StopPrinting: Boolean);
var
  AFont: TFont;
begin
AFont := TFont.Create;
AFont.Name := 'Arial';
AFont.Size := 8;
with Canvas do
  begin
  Font.Assign(AFont);
  SetTextAlign(Handle, TA_Bottom or TA_Left);
  TextOut(50, 20, DateToStr(Date));
  SetTextAlign(Handle, TA_Bottom or TA_Right);
  TextOut(W-50, 20, 'Page '+IntToStr(NumPage));
  end;
AFont.Free;
end;

procedure TForm1.MediaPlayerNotify(Sender: TObject);
begin
try
  With MediaPlayer do
    if NotifyValue = nvSuccessful then
      begin
      if MediaCount > 0 then
        begin
        Play;
        Dec(MediaCount);
        end
      else
        Close;
      end;
except
  end;
end;

procedure TForm1.SoundRequest(Sender: TObject; const SRC: String;
  Loop: Integer; Terminate: Boolean);
begin
try
  with MediaPlayer do
    if Terminate then
      Close
    else
      begin
      Filename := (Sender as ThtmlViewer).HTMLExpandFilename(SRC);
      Notify := True;
      Open;
      if Loop < 0 then MediaCount := 9999
        else if Loop = 0 then MediaCount := 1
        else MediaCount := Loop;
      end;
except
  end;
end;

procedure TForm1.ViewimageClick(Sender: TObject);
var
  AForm: TImageForm;
begin
AForm := TImageForm.Create(Self);
with AForm do
  begin
  ImageFormBitmap := FoundObject.Bitmap;
  Caption := '';
  Show;
  end;
end;

procedure TForm1.CopyImageToClipboardClick(Sender: TObject);
begin
Clipboard.Assign(FoundObject.Bitmap);
end;

procedure TForm1.ObjectClick(Sender, Obj: TObject; const OnClick: String);
var
  S: string;
begin
if OnClick = 'display' then
  begin
  if Obj is TFormControlObj then
    with TFormControlObj(Obj) do
      begin
      if TheControl is TCheckBox then
        with TCheckBox(TheControl) do
          begin
          S := Value + ' is ';
          if Checked then S := S + 'checked'
            else S := S + 'unchecked';
          MessageDlg(S, mtCustom, [mbOK], 0);
          end
      else if TheControl is TRadioButton then
        with TRadioButton(TheControl) do
          begin
          S := Value + ' is checked';
          MessageDlg(S, mtCustom, [mbOK], 0);
          end;
      end;
  end
else if OnClick <> '' then
      MessageDlg(OnClick, mtCustom, [mbOK], 0);
end;


procedure TForm1.ViewerInclude(Sender: TObject; const Command: String;
  Params: TStrings; var Buffer: PChar; var BuffSize: LongInt);
{OnInclude handler}  
const
  S: string[255] = '';    {so will work in Delphi 1}
var
  Filename: string;
  I: integer;
begin
BuffSize := 0;
if CompareText(Command, 'Date') = 0 then
  begin                { <!--#date --> }
  S := DateToStr(Date);
  Buffer := @S[1];
  BuffSize := Length(S);
  end
else if CompareText(Command, 'Time') = 0 then
  begin                { <!--#time -->  }
  S := TimeToStr(Time);
  Buffer := @S[1];
  BuffSize := Length(S);
  end
else if CompareText(Command, 'Include') = 0 then
  begin   {an include file <!--#include FILE="filename" -->  }
  if (Params.count >= 1) then
    begin
    I := Pos('FILE="', Params[0]);
    if I > 0 then
      begin
      Filename := copy(Params[0],  7, 255);
      I := Pos('"', Filename);
      if I > 0 then Delete(Filename, I, 255);
      If MS = Nil then
        MS := TMemoryStream.Create;
      try
        MS.LoadFromFile(Filename);
        Buffer := MS.Memory;
        BuffSize := MS.Size;
      except
        end;
      end;
    end;
  end;
Params.Free;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
MS.Free;
end;

procedure TForm1.RightClick(Sender: TObject; Parameters: TRightClickParameters);
var
  Pt: TPoint;
  S, Dest: string;
  I: integer;
  HintWindow: THintWindow;  {7.01}
  ARect: TRect;
begin
with Parameters do
  begin
  FoundObject := Image;
  ViewImage.Enabled := (FoundObject <> Nil) and (FoundObject.Bitmap <> Nil);
  CopyImageToClipboard.Enabled := (FoundObject <> Nil) and (FoundObject.Bitmap <> Nil);

  if URL <> '' then
    begin
    S := URL;
    I := Pos('#', S);
    if I >= 1 then
      begin
      Dest := System.Copy(S, I, 255);  {local destination}
      S := System.Copy(S, 1, I-1);     {the file name}
      end
    else
      Dest := '';    {no local destination}
    if S = '' then S := Viewer.CurrentFile
      else S := Viewer.HTMLExpandFileName(S);
    NewWindowFile := S+Dest;
    OpenInNewWindow.Enabled := FileExists(S);
    end
  else OpenInNewWindow.Enabled := False;

  GetCursorPos(Pt);
  if Length(CLickWord) > 0 then
    begin
    HintWindow := THintWindow.Create(Self);    {7.01}
    try
      ARect := Rect(0,0,0,0);
      DrawText(HintWindow.Canvas.Handle, @ClickWord[1], Length(ClickWord), ARect, DT_CALCRECT);
      with ARect do
        HintWindow.ActivateHint(Rect(Pt.X+20, Pt.Y-(Bottom-Top)-15, Pt.x+30+Right, Pt.Y-15), ClickWord);
      PopupMenu.Popup(Pt.X, Pt.Y);
    finally
      HintWindow.Free;
      end;
    end
  else PopupMenu.Popup(Pt.X, Pt.Y);
  end;
end;

procedure TForm1.OpenInNewWindowClick(Sender: TObject);
var
  PC: array[0..255] of char;
begin
{$ifdef Windows}
WinExec(StrPCopy(PC, ParamStr(0)+' '+NewWindowFile), sw_Show);
{$else}
WinExec(StrPCopy(PC, ParamStr(0)+' "'+NewWindowFile+'"'), sw_Show);
{$endif}
end;

procedure TForm1.MetaTimerTimer(Sender: TObject);
begin
MetaTimer.Enabled := False;
if Viewer.CurrentFile = PresentFile then  {don't load if current file has changed}
  begin
  Viewer.LoadFromFile(NextFile);
  Caption := Viewer.DocumentTitle;
  end;
end;

procedure TForm1.MetaRefreshEvent(Sender: TObject; Delay: Integer;
  const URL: String);
begin
NextFile := Viewer.HTMLExpandFilename(URL);  
if FileExists(NextFile) then
  begin
  PresentFile := Viewer.CurrentFile;
  MetaTimer.Interval := Delay*1000;
  MetaTimer.Enabled := True;
  end;
end;

procedure TForm1.PrintpreviewClick(Sender: TObject);
{$ifdef Win32}  {Print Preview not available in Delphi 1}
var
  pf: TPreviewForm;
  Abort: boolean;
begin
pf := TPreviewForm.CreateIt(Self, Viewer, Abort);
try
  if not Abort then
    pf.ShowModal;
finally
  pf.Free;
  end;
end;
{$else}
begin
end;
{$endif}

end.

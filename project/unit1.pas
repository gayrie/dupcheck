unit Unit1;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ComCtrls, AsyncProcess, md5, Unit2;
type
  { TForm1_DupCheck }
  TForm1_DupCheck = class(TForm)
    dir_ign_add: TBitBtn;
    dir_ign_list: TListBox;
    dir_ign_rem: TBitBtn;
    dir_ign_text: TLabel;
    hasher: TAsyncProcess;
    file_list_load: TBitBtn;
    file_list_hash_stop: TBitBtn;
    file_list_reset: TBitBtn;
    dir_add: TBitBtn;
    dir_rem: TBitBtn;
    dir_list: TListBox;
    dir_text: TLabel;
    file_list: TListView;
    file_list_hash_calc: TBitBtn;
    file_text: TLabel;
    dir_dlg: TSelectDirectoryDialog;
    pbar: TProgressBar;
    sbar: TStatusBar;
    procedure dir_addClick(Sender: TObject);
    procedure dir_ign_addClick(Sender: TObject);
    procedure dir_ign_remClick(Sender: TObject);
    procedure dir_remClick(Sender: TObject);
    procedure file_list_hash_calcClick(Sender: TObject);
    procedure file_list_hash_stopClick(Sender: TObject);
    procedure file_list_loadClick(Sender: TObject);
    procedure file_list_resetClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    //procedure resize_controls;
  private
    { private declarations }
  public
    { public declarations }
  end;
var //global
  Form1_DupCheck: TForm1_DupCheck;
  hash_isRunning: Boolean;
implementation
{$R *.lfm}
{ TForm1_DupCheck }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

// resize_controls
procedure resize_controls(t: TForm1_DupCheck);
var
  sx: Integer;
  butheight: Integer;
  y: Integer;
begin
  sx:= Trunc(t.Width/22);

  //x axis
  {dir_*}
  t.dir_text.Left := sx;
  t.dir_list.Left := sx;
  t.dir_list.Width:= sx*6;

  t.dir_add.Left := sx;
  t.dir_add.Width:= trunc(sx * 2.5);

  t.dir_rem.Left := trunc(sx * 4.5);
  t.dir_rem.Width:= trunc(sx * 2.5);
  {dir_ign*}
  t.dir_ign_text.Left := sx;
  t.dir_ign_list.Left := sx;
  t.dir_ign_list.Width:= sx*6;

  t.dir_ign_add.Left := sx;
  t.dir_ign_add.Width:= trunc(sx * 2.5);

  t.dir_ign_rem.Left := trunc(sx * 4.5);
  t.dir_ign_rem.Width:= trunc(sx * 2.5);
  {file_*}
  t.file_text.Left := sx * 9;
  t.file_list.Left := sx * 9;
  t.file_list.Width:= sx * 12;

  t.file_list_load.Width:= trunc(sx * 2.5);
  t.file_list_load.Left := sx * 9;

  t.file_list_reset.Width:= trunc(sx * 2.5);
  t.file_list_reset.Left := trunc(sx * 12.5);

  t.file_list_hash_calc.Width:= sx * 5;
  t.file_list_hash_calc.Left := sx * 16;

  t.file_list_hash_stop.Width:= sx * 5;
  t.file_list_hash_stop.Left := sx * 16;
  {*}
  t.pbar.Width:= sx * 20;
  t.pbar.Left :=sx;

  t.sbar.Panels.Items[0].Width := Form1_DupCheck.Width;

  //y axis -> from bot to top; over file_list

  t.pbar.Top := t.Height -t.sbar.Height -sx - trunc(t.pbar.Height /2);

  butheight := t.Height -t.sbar.Height -sx *2 -30;
  t.dir_ign_add.Top := butheight;
  t.dir_ign_rem.Top := butheight;
  t.file_list_load.Top := butheight;
  t.file_list_reset.Top := butheight;
  t.file_list_hash_calc.Top := butheight;
  t.file_list_hash_stop.Top := butheight;

  t.file_list.Height := butheight -sx -8; //8 is hardcode distance betw. neighbor items
  t.file_list.Top := sx;

  t.file_text.Top := sx - t.file_text.Height;
  t.dir_text.Top := t.file_text.Top;

  // -> the 2 dir_*list's and their stuff can
  //have all as much space as: > file_list.Height (var: y)
  y := t.file_list.Height;

  t.dir_list.Height := trunc((y -16 -30 -t.dir_ign_text.Height) /2);
  t.dir_ign_list.Height := t.dir_list.Height;
  {16: 2x8 hardcode distance
   30: button height
   /2: because we have 2 lists}

  t.dir_list.Top := sx;
  t.dir_add.Top := t.dir_list.Top +t.dir_list.Height +8; //8: hardcode val
  t.dir_rem.Top := t.dir_add.Top;
  t.dir_ign_text.Top := t.dir_add.Top +t.dir_add.Height +8; // hardcode
  t.dir_ign_list.Top := t.dir_ign_text.Top +t.dir_ign_text.Height; //hardcode

end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//dir_add: Click
procedure TForm1_DupCheck.dir_addClick(Sender: TObject);
var
  i, j: Integer;
  add: Boolean;
  w, maxw: Integer;
begin
  if dir_dlg.Execute then
  begin
    for i:=0 to dir_dlg.Files.Count-1 do
    //for [all dir's to add] do...
    begin
      add := true;
      if dir_list.Items.Count > 0 then
      //if there's entries already
      begin
        for j:=dir_list.Items.Count - 1 downto 0 do
        //for [all existing dir's] do...
        begin
          if dir_dlg.Files.Strings[i] = dir_list.Items.Strings[j] then
          //if dir already present: don't add
          begin
            ShowMessage('Directory already present:'+sLineBreak+'> '+dir_dlg.Files.Strings[i]);
            add := false;
          end;
          if pos(dir_list.Items.Strings[j], dir_dlg.Files.Strings[i]) = 1 then
          //if subDir of existing one: don't add
          begin
            ShowMessage('Not adding'+sLineBreak+'> '+dir_dlg.Files.Strings[i]+sLineBreak+'Is a subdirectory of'+sLineBreak+'> '+dir_list.Items.Strings[j]);
            add := false;
          end;
          if pos(dir_dlg.Files.Strings[i], dir_list.Items.Strings[j]) = 1 then
          //if there's subdirs of the dir to add in the list: remove subdirs from list
          begin
            ShowMessage('> '+dir_dlg.Files.Strings[i]+sLineBreak+'contains'+sLineBreak+'> '+dir_list.Items.Strings[j]+sLineBreak+'Removing subdirectory from list.');
            dir_list.Items.Delete(dir_list.Items.IndexOf(dir_list.Items.Strings[j]));
          end;
        end;
      end;
      if add then
      begin
        dir_list.Items.Add(dir_dlg.Files.Strings[i]);
      end;
    end;
  end;
  //create hor.scrollbar
  maxw := 0;
  for i := 0 to dir_list.Items.Count-1 do
  begin
    w := dir_list.Canvas.TextWidth(dir_list.Items.Strings[i] + 'x');
    if maxw < w then
      maxw := w;
  end;
  dir_list.ScrollWidth:=maxw;
  //dis/enable controls
  if dir_list.Items.Count > 0 then
  begin
    file_list_load.Enabled := true;
    dir_rem.Enabled := true
  end
  else
  begin
    file_list_load.Enabled := false;
    dir_rem.Enabled := false;
  end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//dir_ign_add: Click
procedure TForm1_DupCheck.dir_ign_addClick(Sender: TObject);
var
  i, j: Integer;
  add: Boolean;
  w, maxw: Integer;
begin
  if dir_dlg.Execute then
  begin
    for i:=0 to dir_dlg.Files.Count-1 do
    //for [all dir's to add] do...
    begin
      add := true;
      if dir_ign_list.Items.Count > 0 then
      //if there's entries already
      begin
        for j:=dir_ign_list.Items.Count - 1 downto 0 do
        //for [all existing dir's] do...
        begin
          if dir_dlg.Files.Strings[i] = dir_ign_list.Items.Strings[j] then
          //if dir already present: don't add
          begin
            ShowMessage('Directory already present:'+sLineBreak+'> '+dir_dlg.Files.Strings[i]);
            add := false;
          end;
          if pos(dir_ign_list.Items.Strings[j], dir_dlg.Files.Strings[i]) = 1 then
          //if subDir of existing one: don't add
          begin
            ShowMessage('Not adding'+sLineBreak+'> '+dir_dlg.Files.Strings[i]+sLineBreak+'Is a subdirectory of'+sLineBreak+'> '+dir_ign_list.Items.Strings[j]);
            add := false;
          end;
          if pos(dir_dlg.Files.Strings[i], dir_ign_list.Items.Strings[j]) = 1 then
          //if there's subdirs of the dir to add in the list: remove subdirs from list
          begin
            ShowMessage('> '+dir_dlg.Files.Strings[i]+sLineBreak+'contains'+sLineBreak+'> '+dir_ign_list.Items.Strings[j]+sLineBreak+'Removing subdirectory from list.');
            dir_ign_list.Items.Delete(dir_ign_list.Items.IndexOf(dir_ign_list.Items.Strings[j]));
          end;
        end;
      end;
      if add then
      begin
        dir_ign_list.Items.Add(dir_dlg.Files.Strings[i]);
      end;
    end;
  end;
  //create hor.scrollbar
  maxw := 0;
  for i := 0 to dir_list.Items.Count-1 do
  begin
    w := dir_ign_list.Canvas.TextWidth(dir_ign_list.Items.Strings[i] + 'x');
    if maxw < w then
      maxw := w;
  end;
  dir_ign_list.ScrollWidth:=maxw;
  //dis/enable controls
  if dir_ign_list.Items.Count > 0 then
  begin
    dir_ign_rem.Enabled := true
  end
  else
  begin
    dir_ign_rem.Enabled := false;
  end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//dir_ign_rem: Click
procedure TForm1_DupCheck.dir_ign_remClick(Sender: TObject);
var
  i: Integer;
  w, maxw: Integer;
begin
  if dir_ign_list.SelCount > 0 then
    for i:=dir_ign_list.Items.Count - 1 downto 0 do
      if dir_ign_list.Selected[i] then
      begin
        dir_ign_list.Items.Delete(i);
      end;
  //create hor.scrollbar
  maxw := 0;
  for i := 0 to dir_ign_list.Items.Count-1 do
  begin
    w := dir_ign_list.Canvas.TextWidth(dir_ign_list.Items.Strings[i] + 'x');
    if maxw < w then
      maxw := w;
  end;
  dir_ign_list.ScrollWidth:=maxw;
  //dis-enable controls
  if dir_ign_list.Items.Count > 0 then
  begin
    dir_ign_rem.Enabled := true;
  end
  else
  begin
    dir_ign_rem.Enabled := false;
  end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//dir_rem: Click
procedure TForm1_DupCheck.dir_remClick(Sender: TObject);
var
  i: Integer;
  w, maxw: Integer;
begin
  if dir_list.SelCount > 0 then
    for i:=dir_list.Items.Count - 1 downto 0 do
      if dir_list.Selected[i] then
      begin
        dir_list.Items.Delete(i);
      end;
  //create hor.scrollbar
  maxw := 0;
  for i := 0 to dir_list.Items.Count-1 do
  begin
    w := dir_list.Canvas.TextWidth(dir_list.Items.Strings[i] + 'x');
    if maxw < w then
      maxw := w;
  end;
  dir_list.ScrollWidth:=maxw;
  //dis-enable controls
  if dir_list.Items.Count > 0 then
  begin
    file_list_load.Enabled := true;
    dir_rem.Enabled := true;
  end
  else
  begin
    file_list_load.Enabled := false;
    dir_rem.Enabled := false;
  end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//file_list_hash_calc: Click
procedure TForm1_DupCheck.file_list_hash_calcClick(Sender: TObject);
var
  i, j, k: Integer;
  li: TlistItem;
  {lu: TTime;}
begin
  //handle controls
  file_list_hash_calc.Visible := false;
  file_list_hash_stop.Visible := true;
  file_list_hash_stop.enabled := true;
  file_list_reset.Enabled:=false;
  hash_isRunning := true;

  //get start item (in case it's a resume)
  sbar.Panels.Items[0].Text:= 'Preparing to hash files...';
  j:=0;
  {lu := Time;}
  for i:=0 to file_list.Items.Count-1 do
  begin
    li := file_list.Items.Item[j];
    if li.Subitems.Text = '' then
    begin
      k:=j;  //first empty subitem is starting point,
      Break; //index is stored in var `k`
    end;
    j+=1;
  end;

  sbar.Panels.Items[0].Text:= 'Hashing files...';
  pbar.Max:=file_list.Items.Count;
  pbar.Position:=k;
  j:=k;

  for i:=k to file_list.Items.Count -1 do
  begin
    li := file_list.Items.Item[j];
    if FileExists(li.Caption) then li.SubItems.Add(MD5Print(MD5File(li.Caption))) else li.SubItems.Add('FILE_NOT_FOUND');
    pbar.position := pbar.Position + 1;
    j+=1;
    Application.ProcessMessages;
    if hash_isRunning = false then break;
  end;
  file_list_hash_calc.Visible := true;
  file_list_hash_calc.Enabled := true;
  file_list_hash_stop.Visible := false;
  file_list_reset.Enabled:=true;
  if hash_isRunning = true then
  begin
    sbar.Panels.Items[0].Text:= 'Generating report...';
    report.list := file_list;
    report.Show;
    hash_isRunning := false;
    sbar.Panels.Items[0].Text:= '';
    file_list_reset.Click;
  end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//file_list_hash_stop: Click
procedure TForm1_DupCheck.file_list_hash_stopClick(Sender: TObject);
begin
  hash_isRunning:= false;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//file_list_load: Click
procedure TForm1_DupCheck.file_list_loadClick(Sender: TObject);
var
  i, j, k: Integer;
  sl: TStringList;
  li: TListItem;
  lu: String;
  add: boolean;
begin
  //disable controls
  dir_add.Enabled := false;
  dir_rem.Enabled := false;
  dir_ign_add.Enabled := false;
  dir_ign_rem.Enabled := false;
  file_list_load.Enabled := false;

  //add each entry's items.
  lu := timeToStr(Time);
  for i:=0 to dir_list.Items.Count - 1 do
  begin
    //init loop
    sbar.Panels.Items[0].Text:= 'Adding files from ' + dir_list.Items.Strings[i];
    sl := FindAllFiles(dir_list.Items.Strings[i], '*', True);
    pbar.Max:=sl.Count-1;
    pbar.Position:=0;

    //for each file found do
    for j:=0 to sl.Count -1 do
    begin
      add := true;
      //for each in dir_ign_list check if file's name begins with dir_ign_ignore entry.
      for k:=0 to dir_ign_list.Items.Count-1 do
      begin
        if pos(dir_ign_list.Items.Strings[k], sl[j]) = 1 then add := false;
        if add = false then break;
      end;
      //if not then add it.
      if add then
      begin
        li := file_list.Items.Add;
        li.Caption := sl[j];
      end;
      //finally, update pbar
      pbar.position := pbar.Position + 1;

      //update form
      if lu <> timeToStr(Time) then //Update from every second
      begin
        Application.ProcessMessages;
        lu:=timeToStr(Time);
      end;
    end;
  end;
  //update controls
  file_text.Caption:='Files (' + IntToStr(file_list.Items.Count) + ' total)';
  sbar.Panels.Items[0].Text:= '';
  //enable controls
  file_list_reset.Enabled := true;
  if file_list.Items.Count > 0 then file_list_hash_calc.Enabled := true;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//file_list_reset: Click
procedure TForm1_DupCheck.file_list_resetClick(Sender: TObject);
begin
  sbar.Panels.Items[0].Text:= 'Clearing file list...';
  file_list.Clear;
  //update file_text
  file_text.Caption:='Files';
  //dis-enable controls
  dir_add.Enabled := true;
  dir_rem.Enabled := true;
  dir_ign_add.Enabled := true;
  dir_ign_rem.Enabled := true;
  dir_list.Enabled := true;
  file_list_load.Enabled := true;
  file_list_reset.Enabled := false;
  file_list_hash_calc.Enabled := false;
  sbar.Panels.Items[0].Text:= '';
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//form_close
procedure TForm1_DupCheck.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if report.IsVisible then
  begin
    if MessageDlg('Close report?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      Abort;
    end;
  end;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//FormResize + FormShow
procedure TForm1_DupCheck.FormResize(Sender: TObject);
begin
  resize_controls(Form1_DupCheck);
end;

procedure TForm1_DupCheck.FormShow(Sender: TObject);
begin
  //height of buttons - set only ONCE
  pbar.Height := 30;
  dir_add.Height := 30;
  dir_rem.Height := 30;
  dir_ign_add.Height := 30;
  dir_ign_rem.Height := 30;
  file_list_load.Height := 30;
  file_list_reset.Height := 30;
  file_list_hash_calc.Height := 30;
  file_list_hash_stop.Height := 30;

  file_list_hash_stop.Visible := false;
  resize_controls(Form1_DupCheck);
  pbar.Min:=0;
  pbar.Smooth:=true;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

end.






















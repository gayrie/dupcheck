unit Unit2;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  Buttons, ComCtrls;
type
  { Treport }
  Treport = class(TForm)
    report_save: TSaveDialog;
    tree_export: TBitBtn;
    report_close: TBitBtn;
    sbar: TStatusBar;
    tree: TTreeView;
    file_delete: TBitBtn;
    procedure file_deleteClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure report_closeClick(Sender: TObject);
    procedure tree_exportClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    list: TListView;
  end;

var //global var
  report: Treport;

implementation
{$R *.lfm}
{ Treport }

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//resize_controls
procedure resize_controls(t: Treport);
var
  sx: Integer;
begin
  sx := trunc(t.Width/3);

  t.tree.Width := t.Width;
  t.tree.Height:= t.Height -16 -t.tree_export.Height -t.sbar.Height;
  t.tree.Top := 0;
  t.tree.Left:= 0;

  t.tree_export.Width := sx -16;
  t.tree_export.Top := t.tree.Height +8;
  t.tree_export.Left:= 8;

  t.file_delete.Width := sx -16;
  t.file_delete.Top := t.tree.Height +8;
  t.file_delete.Left:= sx +8;

  t.report_close.Width := sx -16;
  t.report_close.Top := t.tree.Height +8;
  t.report_close.Left:= sx *2 +8;

  t.sbar.Panels.Items[0].Width := t.Width;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//load
procedure load(t:Treport);
var
  i, j: Integer;
  li: TListItem;
  node: TTreeNode;
  s: string;
begin
  //clear tree
  t.tree.Items.Clear;
  t.sbar.Panels.Items[0].Text:='Generating Report...';
  s := 'FILE_NOT_FOUND';

  //fill tree
  for i:=0 to t.list.Items.Count -1 do
  begin //with each file/entry...
    li := t.list.Items.Item[i];
    node := nil;
    //... if item has been hashed...
    if li.SubItems.Strings[0] <> s then
    begin //... iterate through tree to know if hash node exists,
      for j:=0 to t.tree.Items.Count-1 do
      begin
        if li.SubItems.Strings[0] = t.tree.Items.Item[j].Text then node := t.tree.Items.Item[j];
      end;
      //... if node is empty, create a node
      if node = nil then node := t.tree.Items.Add(nil,li.SubItems.Strings[0]);
      //... add entry to node
      t.tree.Items.AddChild(node, li.Caption);
    end;
  end;

  //remove nodes with one child
  for i := t.tree.Items.TopLvlCount-1 downto 0 do
  begin //with each node...
    if t.tree.Items.TopLvlItems[i].SubTreeCount < 3 then t.tree.Items.TopLvlItems[i].Delete;
  end;
  t.sbar.Panels.Items[0].Text:='Report generated: '+intToStr(t.tree.Items.TopLvlCount)+' files appear more than once.';
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//form_resize
procedure Treport.FormResize(Sender: TObject);
begin
  resize_controls(report);
end;

//form_close
procedure Treport.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if MessageDlg('Close report?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    Abort;
  end;
end;

//form_show
procedure Treport.FormShow(Sender: TObject);
begin
  resize_controls(report);
  load(report);
  tree.FullExpand;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//report_close
procedure Treport.report_closeClick(Sender: TObject);
begin
  Close;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//tree_export: Click
procedure Treport.tree_exportClick(Sender: TObject);
var
  i: Integer;
  f: String;
  csv: TextFile;
begin
  report_save.Execute;
  f := report_save.FileName;
  sbar.Panels.Items[0].Text := 'Saving report to ' + f + '...';
  //generate text
  try
  AssignFile(csv, f);
    Rewrite(csv);
    for i:=1 to tree.Items.Count-1 do
    begin
      if not tree.Items.Item[i].HasChildren then
       writeLn(csv, tree.Items.Item[i].Parent.Text + #9 + tree.Items.Item[i].Text)
     else
       writeLn(csv, '');
    end;
  finally
    CloseFile(csv);
  end;
  sbar.Panels.Items[0].Text := '';
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

//delete_file: Click
procedure Treport.file_deleteClick(Sender: TObject);
var
  node: TTreeNode;
begin

  if tree.Selected.HasChildren = false then
  begin //if it's a child that's selected...
    node := tree.Selected;
    if MessageDlg('Delete file from filesystem?'+sLineBreak+IntToStr(node.Parent.SubTreeCount-2)+' duplicate(s) seem to exist.', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin // ... and if the confirm dlg returns yes ...
      // ... delete then file
      try
        if FileExists(node.Text) then
        begin
          DeleteFile(node.Text);
          node.Delete;
        end
        else
          if MessageDlg('File not found!'+sLineBreak+sLineBreak+'Delete node anyway?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then node.Delete;
      finally
      end;
    end;
  end;
end;
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

end.


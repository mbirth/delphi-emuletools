program GapMerger;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  rbrConsTools in '..\rbrConsTools\rbrConsTools.pas';

const
  AppTitle: string = 'eMule Gap Merger';
  AppVersion: string = '1.0';

var
  OldConsTitle: PChar;
  infile1,infile2,outfile: file of char;
  Buf1, Buf2: array[1..64] of char;
  i,i1,i2,j: integer;
  WX,WY: integer;
  ct,bw,be: integer;
  ofs,ifs: longint;
  incon: longint;
  isempty: boolean;

begin
try
  OldConsTitle := PChar(AllocMem(256));
  GetConsoleTitle(OldConsTitle,255);
  SetConsoleTitle(PChar(AppTitle+' '+AppVersion));
  TextColor(white);
  WriteLn('--==# '+AppTitle+' '+AppVersion+' #==--');
  TextColor(LightGray);
  WriteLn('(c)2003 by Markus Birth <mbirth@webwriters.de>');
  WriteLn;
  if (ParamCount<3) then begin
    TextColor(LightRed);
    WriteLn('Not enough actual parameters.');
    TextColor(LightGray);
    SetConsoleTitle(OldConsTitle);
    Halt(1);
  end;
  Write('Assigning files...');
  AssignFile(infile1,ParamStr(1));
  AssignFile(infile2,ParamStr(2));
  AssignFile(outfile,ParamStr(3));
  WriteLn('done.');
  Write('Opening files (existing output file will be overwritten)...');
  Reset(infile1);
  Reset(infile2);
  Rewrite(outfile);
  WriteLn('done.');
  if (FileSize(infile1)=FileSize(infile2)) then begin
    ifs := FileSize(infile1);
    WriteLn('Infiles are each ',ifs,' Bytes ~ ',ifs DIV 64,' Blocks');
    Write('Start merging...');
    WX := WhereX;
    WY := WhereY;
    ct := 0;
    bw := 0;
    be := 0;
    incon := 0;
    repeat
      BlockRead(infile1,Buf1,SizeOf(Buf1),i1);
      BlockRead(infile2,Buf2,SizeOf(Buf2),i2);
      if (i2>i1) then i := i2 else i := i1;
      isempty := true;
      for j:=1 to 64 do begin
        if (Ord(Buf1[j])=0) AND (Ord(Buf2[j])<>0) then Buf1[j] := Buf2[j];
        if (Ord(Buf2[j])<>0) AND (Buf1[j]<>Buf2[j]) then Inc(incon);
        if (Ord(Buf1[j])<>0) then isempty := false;
      end;
      BlockWrite(outfile,Buf1,i);
      Inc(bw);
      if isempty then Inc(be);
      Inc(ct);
      if (ct>=10000) then begin
        GotoXY(WX,WY);
        Write(bw,' Blocks written (',be,' empty)');
        ct := 0;
      end;
    until i=0;
    GotoXY(WX,WY);
    Write(bw,' Blocks written (',be,' empty)');
    WriteLn(' ... done.');
    ofs := FileSize(outfile);
    WriteLn('Outfile is ',ofs,' Bytes ~ ',ofs DIV 64,' Blocks');
    if (incon>0) then begin
      TextColor(LightRed);
      WriteLn('WARNING! Inconsistencies found! Output file may be corrupt!');
      WriteLn(incon,' inconsistent byte(s) found! (',incon*100/ofs:7:3,'%)');
      TextColor(LightGray);
    end;
  end else begin
    TextColor(lightred);
    WriteLn('!!ERROR!! Infiles have different sizes.');
    TextColor(lightgray);
  end;
  Write('Closing files...');
  CloseFile(infile1);
  CloseFile(infile2);
  CloseFile(outfile);
  WriteLn('done.');
  SetConsoleTitle(OldConsTitle);
except
  on e: Exception do begin
    TextColor(LightRed+blink);
    WriteLn('error!');
    TextColor(LightRed);
    TextBackground(Black);
    WriteLn('Exception: '+e.Message);
    TextColor(LightGray);
  end;
end;
end.


program GapRemover;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  rbrConsTools in '..\rbrConsTools\rbrConsTools.pas';

const
  AppTitle: string = 'eMule Gap Remover';
  AppVersion: string = '1.0';

var
  OldConsTitle: PChar;
  infile,outfile: file of char;
  Buf: array[1..64] of char;
  i,j: integer;
  isnull: boolean;
  WX,WY: integer;
  ct,bw,bs: integer;
  ofs,ifs: longint;

begin
  OldConsTitle := PChar(AllocMem(256));
  GetConsoleTitle(OldConsTitle,255);
  SetConsoleTitle(PChar(AppTitle+' '+AppVersion));
  TextColor(white);
  WriteLn('--==# '+AppTitle+' '+AppVersion+' #==--');
  TextColor(LightGray);
  WriteLn('(c)2003 by Markus Birth <mbirth@webwriters.de>');
  WriteLn;
  if (ParamCount<2) then begin
    TextColor(LightRed);
    WriteLn('Not enough actual parameters.');
    TextColor(LightGray);
    SetConsoleTitle(OldConsTitle);
    Halt(1);
  end;
  Write('Assigning files...');
  AssignFile(infile,ParamStr(1));
  AssignFile(outfile,ParamStr(2));
  WriteLn('done.');
  Write('Opening files (existing output file will be overwritten)...');
  Reset(infile);
  Rewrite(outfile);
  WriteLn('done.');
  ifs := FileSize(infile);
  WriteLn('Infile is ',ifs,' Bytes ~ ',ifs DIV 64,' Blocks');
  Write('Start copying...');
  WX := WhereX;
  WY := WhereY;
  ct := 0;
  bw := 0;
  bs := 0;
  repeat
    BlockRead(infile,Buf,SizeOf(Buf),i);
    isnull := true;
    for j:=1 to 64 do if Ord(Buf[j])<>0 then isnull:=false;
    if NOT isnull then begin
      BlockWrite(outfile,Buf,i);
      Inc(bw);
    end else Inc(bs);
    Inc(ct);
    if (ct>=10000) then begin
      GotoXY(WX,WY);
      Write('Blocks: ',bw+bs,' processed / ',bw,' written / ',bs,' skipped');
      ct := 0;
    end;
  until i=0;
  GotoXY(WX,WY);
  Write('Blocks: ',bw+bs,' processed / ',bw,' written / ',bs,' skipped');
  WriteLn(' ... done.');
  ofs := FileSize(outfile);
  WriteLn('Outfile is ',ofs,' Bytes ~ ',ofs DIV 64,' Blocks');
  WriteLn('Outfile is ',ofs*100/ifs:7:3,'% of Infile');
  Write('Closing files...');
  CloseFile(infile);
  CloseFile(outfile);
  WriteLn('done.');
  SetConsoleTitle(OldConsTitle);
end.

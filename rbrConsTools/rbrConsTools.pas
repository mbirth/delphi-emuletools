unit rbrConsTools;

interface

  const
    Black        = 0;
    Blue         = 1;
    Green        = 2;
    Cyan         = 3;
    Red          = 4;
    Magenta      = 5;
    Brown        = 6;
    LightGray    = 7;
    DarkGray     = 8;
    LightBlue    = 9;
    LightGreen   = 10;
    LightCyan    = 11;
    LightRed     = 12;
    LightMagenta = 13;
    Yellow       = 14;
    White        = 15;
    blink        = 128;

  procedure TextColor(x: byte);
  procedure TextBackground(x: byte);
  procedure GotoXY(x,y: integer);
  function WhereX: integer;
  function WhereY: integer;
  procedure ClrScr;
  procedure ClrEol;
  function ReadKeyAsWord: Word;
  function keypressed: boolean;
  function ProgBar(width: integer; pos: double; memslot: byte = 1; forcewrite: boolean = false): boolean;
  function ProgBarLn(width: integer; pos: double; memslot: byte = 1; forcewrite: boolean = false): boolean;
  function ProgBarAt(x,y: integer; width: integer; pos: double; memslot: byte = 1; forcewrite: boolean = false): boolean;
  function working(step: longint = 1; memslot: byte = 1): boolean;

implementation

  uses Windows;

  const
    wiString = '/-\|';

  var
    hConsoleInput: THandle;
    hConsoleOutput: THandle;
    wiPos: array[1..10] of byte;
    wkPos: array[1..10] of longint;
    ProgBarSave: array[1..10] of integer;
    i: integer;

  procedure TextColor(x: byte);
  var BI  : CONSOLE_SCREEN_BUFFER_INFO;
      att : word;
  begin
    GetConsoleScreenBufferInfo(hConsoleOutput, BI);
    att := BI.wAttributes;
    att := att AND $F0;
    { ANDing with 11110000 to let the current bg-color remain }
    SetConsoleTextAttribute(hConsoleOutput, x+att);
  end;

  procedure TextBackground(x: byte);
  var BI  : CONSOLE_SCREEN_BUFFER_INFO;
      att : word;
  begin
    GetConsoleScreenBufferInfo(hConsoleOutput, BI);
    att := BI.wAttributes;
    att := att AND $0F;
    { ANDing with 00001111 to let the current fg-color remain }
    SetConsoleTextAttribute(hConsoleOutput, x*$10+att);
  end;

  procedure GotoXY(x,y: integer);
  var Pos: COORD;
  begin
    Pos.X := x-1;
    Pos.Y := y-1;
    { 1 is subtracted because the top-left pos in Pascal was (1,1) instead of (0,0) }
    SetConsoleCursorPosition(hConsoleOutput,Pos);
  end;

  function WhereX: integer;
  var SBI: CONSOLE_SCREEN_BUFFER_INFO;
  begin
    GetConsoleScreenBufferInfo(hConsoleOutput,SBI);
    WhereX := SBI.dwCursorPosition.X + 1;
    { 1 is added because in Pascal the top-left position was (1,1) and not (0,0) }
  end;

  function WhereY: integer;
  var SBI: CONSOLE_SCREEN_BUFFER_INFO;
  begin
    GetConsoleScreenBufferInfo(hConsoleOutput,SBI);
    WhereY := SBI.dwCursorPosition.Y + 1;
    { 1 is added because in Pascal the top-left position was (1,1) and not (0,0) }
  end;

  procedure ClrScr;
  var coordScreen: COORD;
      SBI: CONSOLE_SCREEN_BUFFER_INFO;
      charsWritten: longword;
      ConSize: longword;
  begin
    coordScreen.X := 0; coordScreen.Y := 0;
    GetConsoleScreenBufferInfo(hConsoleOutput, SBI);
    ConSize := SBI.dwSize.X * SBI.dwSize.Y;
    FillConsoleOutputCharacter(hConsoleOutput, ' ', ConSize, coordScreen, charsWritten);
    FillConsoleOutputAttribute(hConsoleOutput, SBI.wAttributes, ConSize, coordScreen, charsWritten);
    SetConsoleCursorPosition(hConsoleOutput, coordScreen);
  end;

  procedure ClrEol;
  var tC :tCoord;
      Len,Nw: longword;
      Cbi : TConsoleScreenBufferInfo;
  begin
    GetConsoleScreenBufferInfo(hConsoleOutput, cbi);
    len := cbi.dwsize.x-cbi.dwcursorposition.x;
    tc.x := cbi.dwcursorposition.x;
    tc.y := cbi.dwcursorposition.y;
    FillConsoleOutputAttribute(hConsoleOutput,cbi.wAttributes,len,tc,nw);
    FillConsoleOutputCharacter(hConsoleOutput,#32,len,tc,nw);
  end;

  function ReadKeyAsWord: Word;
  var Read: Cardinal;
      Rec: _INPUT_RECORD; 
  begin 
    repeat
      Rec.EventType := KEY_EVENT;
      ReadConsoleInput(hConsoleInput, Rec, 1, Read);
    until (Read = 1) AND (Rec.Event.KeyEvent.bKeyDown);
    Result := Rec.Event.KeyEvent.wVirtualKeyCode;
  end;

  function ReadKey: Char;
  var Ch: Char;
      NumRead: DWORD;
      SaveMode: DWORD;
  begin
    GetConsoleMode(hConsoleInput, SaveMode);
    SetConsoleMode(hConsoleInput, 0);
    NumRead := 0;
    while NumRead < 1 do ReadConsole(hConsoleInput, @Ch, 1, NumRead, nil);
    SetConsoleMode(hConsoleInput, SaveMode);
    Result := Ch;
  end;

  function keypressed: boolean;
  var NumberOfEvents: longword;
      InputRec: TInputRecord;
      NumRead: DWORD;
  begin
    Result := false;
    GetNumberOfConsoleInputEvents(hConsoleInput, NumberOfEvents);
    if NumberOfEvents > 0 then begin
      if PeekConsoleInput(hConsoleInput, InputRec, 1, NumRead) then begin
        if (InputRec.EventType = KEY_EVENT) AND (InputRec.Event.KeyEvent.bKeyDown) AND (InputRec.Event.KeyEvent.AsciiChar > #0) then begin
          Result := true;
        end else begin
          FlushConsoleInputBuffer(hConsoleInput);
        end;
      end;
    end;
  end;

  function ProgBarChanged(width: integer; pos: double; memslot: byte = 1): boolean;
  var nexstep: integer;
  begin
    nexstep := Trunc(3 * width * pos);  // 3 steps in 1 char
    // WriteLn('this: ',ProgBarSave[memslot],' --- next: ',nexstep);
    if (ProgBarSave[memslot] <> nexstep) then Result := true else Result := false;
  end;

  function ProgBar(width: integer; pos: double; memslot: byte = 1; forcewrite: boolean = false): boolean;
  var cp, curstep: integer;
  begin
    if (forcewrite) OR (ProgBarChanged(width, pos, memslot)) then begin
      curstep := Trunc(3 * width * pos);
      cp := 1;
      while cp<=width do begin
        if (curstep>=cp*3) then Write(Chr($db))
          else if (curstep>=(cp-1)*3+2) then Write(Chr($b2))
          else if (curstep>=(cp-1)*3+1) then Write(Chr($b1))
          else Write(Chr($b0));
        Inc(cp);
      end;
      ProgBarSave[memslot] := Trunc(3 * width * pos);
      Result := true;
    end else begin
      Result := false;
      GotoXY(WhereX+width, WhereY);
    end;
  end;

  function ProgBarLn(width: integer; pos: double; memslot: byte = 1; forcewrite: boolean = false): boolean;
  begin
    Result := ProgBar(width, pos, memslot, forcewrite);
    WriteLn;
  end;

  function ProgBarAt(x,y: integer; width: integer; pos: double; memslot: byte = 1; forcewrite: boolean = false): boolean;
  begin
    if (ProgBarChanged(width, pos, memslot)) OR (forcewrite) then begin
      GotoXY(x,y);
      Result := ProgBar(width, pos, memslot, true);
    end else Result := false;
  end;

  function working(step: longint = 1; memslot: byte = 1): boolean;
  begin
    if (wkPos[memslot]>=step) then begin
      Write(wiString[wiPos[memslot]]);
      Inc(wiPos[memslot]);
      if (wiPos[memslot] > Length(wiString)) then wiPos[memslot] := 1;
      wkPos[memslot] := 1;
      Result := true;
    end else begin
      Inc(wkPos[memslot]);
      Result := false;
    end;
  end;

begin
  for i:=1 to 10 do begin
    wiPos[i] := 1;
    wkPos[i] := 1;
  end;
  hConsoleInput := GetStdHandle(STD_INPUT_HANDLE);
  hConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);

end.

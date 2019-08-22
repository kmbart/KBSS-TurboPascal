


program Elig;   { Generate Position Eligibility }
{200804 - cloned from CALC5}

{$I DCLSTATS.PAS }

const
  LeagueMin    : integer = 20;
  PgmName      : Str4 = 'ELIG';
  Zero_ID      : Str8 = '00000000';

{$I UTILSUBS.PAS }
{$I GETRL.PAS }

type
  MemArray = array [0..19] of Member;
  TeamArray = array [0..NumOfNL] of Team;

var
  AMember           : Member;
  APlayer           : Player;
  ArrayKeys         : array [0..999] of Str8;
  CntKeys           : integer;
  Count_C           : integer;
  Count_1           : integer;
  Count_2           : integer;
  Count_S           : integer;
  Count_3           : integer;
  Count_O           : integer;
  CurrPlayerKey     : integer;
  FileElig          : text;
  FileInfo          : text;
  FileNpos          : text;
  FilePly           : file of Player;
  FilePlyCurr       : Str24;
  FileRost          : text;
  Fraction          : integer;
  I                 : integer;
  J                 : integer;
  Line80            : Str80;
  Mantissa          : integer;
  ML                : char;
  Mode              : char;
  PlayerPosMax      : integer;
  Positions         : Str8;
  RecType           : char;
  RotLeag           : Str3;
  RptDate           : Str8;
  RptTime           : Str8;
  ShowDate          : Str8;



{========================= GetPlayerKey  =========================}
{
find ID in ArrayKeys;
if not found then
  return -1;
  write err msg;
else return index;
}

function GetPlayerKey (ID:Str8):integer;

var
  I : integer;

begin

I := -1;
if ID <> Zero_ID then begin
  I := 0;
  while (I <= CntKeys) and (ArrayKeys[I] <> ID) do I := I + 1;

  if I > CntKeys then begin
{    writeln (FileInfo,'ID ',ID,' not found in index');  }
    I := -1;
  end; {if I > CntKeys}

end; {if ID <> Zero_ID}

GetPlayerKey := I;

{ write('ID=',ID,' ,I=',I);readln; }

end; {GetPlayerKey}


{========================= IsPitcher  =========================}
{
returns TRUE if pitcher, FALSE otherwise.
}

function IsPitcher (M:Member):boolean;

var
  I : boolean;
  P : char;

begin

I := (M.RostPos = 'P');

P := copy (M.PosList,1,1);

{ write (M.Stats.Name,' , ',I,' , ',P); }

I := I or (P = 'P');
I := I or ((M.RostPos = 'U') and (P = 'P'));
I := I or ((M.RostPos = 'U') and (P = ' '));
I := I or ((M.RostPos = 'X') and (P = 'P'));
I := I or ((M.RostPos = 'X') and (P = ' '));

IsPitcher := I;

end; {IsPitcher}




{========================= DeletePlayer  =========================}
{
set the player index array at position X to '    ';
}

procedure DeletePlayer (X:integer);

begin

ArrayKeys [X] := '        ';

end; {DeletePlayer}




{========================= ParseRostLine =========================
returns TRUE if it can parse a ROST file player line into
  Name
  ID
  Salary
  RostPos
  Contract
  PosList
}

function ParseRostLine (L:Str80;var M:Member):boolean;

var
  OK     : boolean;
  I      : integer;

begin

M.Stats.Name := copy (L,2,18);
I := 18;
while M.Stats.Name [I] = ' ' do I := I - 1;
M.Stats.Name [0] := chr (I);

M.Stats.ID := copy (L,20,8);

{ write ('Name=',M.Stats.Name,'* ID=',M.Stats.ID); readln; }

OK := (GetInt (L,29,2,Mantissa)) and (GetInt (L,32,2,Fraction));
if OK then M.Salary := Mantissa + (Fraction / 100);

M.RostPos := L[35];

M.Contract := L[37] + L[38];

M.PosList := copy (L,40,8);

M.Stats.MLTeam := copy (L,52,4);

ParseRostLine := OK;

{
if OK then begin
  writeln ('name=',M.Stats.Name);
  writeln ('ID=',M.Stats.ID);
  writeln ('sal=',M.Salary);
  writeln ('pos=',M.RostPos);
  writeln ('yr=',M.Contract);
  writeln ('list=',M.PosList);
  readln;
  end;
}

end; {ParseRostLine}




{========================= M A I N =========================}
{
get the major league, rot league, date and mode;
set LeagueMinimum to X;
read in the player data and create the index array;
read ROST file;
  set positions to '??????'
  if Pitcher then set positions to P and write ELIG record
  else
    set positions to ' ';
    set all position counts to zero;
    set Player Position Max to zero;
    find player in stats file;
    set catcher count to G_C;
    if G_C > Player Position Max then set Player Position Max to G_C;
    (repeat for each position);
    if Player Position Max >= LeagueMinimum then
      set Player Position Max to LeagueMinimum;
    if catcher count >= Player Position Max then append 'C' to positions;
    (repeat for each position);
    set ELIG positions to positions;
    write ELIG record;
}

begin {Main Program}

clrscr;

PgmName := 'ELIG';

GetLeagDate (ML,StatMMDD,PrevMMDD);

{ KB/20010419=commented out - using 'TST' as default }
{
GetRotLeag (RotLeag);
}
RotLeag := 'TST';

StartUp (RotLeag);

Mode := ' ';
repeat
  if not (Mode in [' ','I','U']) then begin
    gotoxy (40,16);
    writeln ('* invalid mode *');
    end; {if invalid Mode}
  gotoxy (10,12);
  write ('Screen mode (Initialize or Update?)');
  readln (Mode);

  Mode := upcase (Mode);
  until Mode in ['I','U'];

ShowDate := copy (StatMMDD,1,2) + '/' + copy (StatMMDD,3,2)
                                + '/' + copy (CurrDate,1,2);
FilePlyCurr := '\PLY\PLY' + StatMMDD + '.' + ML;

RptDate := CurrDate;
RptTime := CurrTime;

clrscr;

assign (FilePly,FilePlyCurr);
reset (FilePly);

I := 0;
while not (eof(FilePly)) do begin
  read (FilePly,APlayer);
  ArrayKeys [I] := APlayer.ID;
{ writeln(I,' ',ArrayKeys [I],' ==>',APlayer.Name); readln; }
  I := I + 1;
  end; {while not eof FilePly}

CntKeys := I - 1;

reset (FilePly);

assign (FileRost,'\'+RotLeag+'\'+'ROST'+StatMMDD + '.' + RotLeag);
assign (FileElig,'\'+RotLeag+'\'+'ELIG'+StatMMDD + '.' + RotLeag);
assign (FileNpos,'\'+RotLeag+'\'+'NPOS'+StatMMDD + '.' + RotLeag);

reset (FileRost);
rewrite (FileElig);
rewrite (FileNpos);
writeln (FileNpos,'     POSITION ELIGIBILITY CHANGES');
writeln (FileNpos,' ');

while not (eof(FileRost)) do begin
  CurrPlayerKey := -1;
  readln (FileRost,Line80);
{  writeln ('==>',Line80:55); }

  RecType := copy (Line80,1,1);

  if RecType in ['+','?','-','!','&','~','/'] then begin
    if not ParseRostLine (Line80,AMember) then begin
      write ('no parse: ',Line80:55);readln;
      writeln (FileErr,'no parse: ',Line80:55);
      end {if not ParseRostLine}

    else begin

      if AMember.Stats.ID <> '00000000' then begin
        J := GetPlayerKey (AMember.Stats.ID);

        if J >= 0 then begin
          seek (FilePly,J);
          read (FilePly,AMember.Stats);
          DeletePlayer (J);

          if Pos('P',AMember.PosList) > 0 then
            AMember.Stats.PrimePos := 'P ';

          if AMember.Stats.PrimePos = 'P ' then Positions := 'P'
          else begin
            Positions    := '';
            PlayerPosMax := 1;
            Count_C      := 0;
            Count_1      := 0;
            Count_2      := 0;
            Count_S      := 0;
            Count_3      := 0;
            Count_O      := 0;

            with AMember.Stats.YTD do begin
              if Mode = 'I' then begin
                if G_C > PlayerPosMax then PlayerPosMax := G_C;
                if G_1 > PlayerPosMax then PlayerPosMax := G_1;
                if G_2 > PlayerPosMax then PlayerPosMax := G_2;
                if G_S > PlayerPosMax then PlayerPosMax := G_S;
                if G_3 > PlayerPosMax then PlayerPosMax := G_3;
                if G_O > PlayerPosMax then PlayerPosMax := G_O;

                if PlayerPosMax >= LeagueMin then
                  PlayerPosMax := LeagueMin;
                end {if Mode = 'I'}

              else {not Mode = 'I'} begin
                if Pos('C',AMember.PosList) > 0 then G_C := G_C + 1;
                if Pos('1',AMember.PosList) > 0 then G_1 := G_1 + 1;
                if Pos('2',AMember.PosList) > 0 then G_2 := G_2 + 1;
                if Pos('S',AMember.PosList) > 0 then G_S := G_S + 1;
                if Pos('3',AMember.PosList) > 0 then G_3 := G_3 + 1;
                if Pos('O',AMember.PosList) > 0 then G_O := G_O + 1;
                end; {not Mode = 'I'}

              if G_C >= PlayerPosMax then Positions := Positions + 'C';
              if G_1 >= PlayerPosMax then Positions := Positions + '1';
              if G_2 >= PlayerPosMax then Positions := Positions + '2';
              if G_S >= PlayerPosMax then Positions := Positions + 'S';
              if G_3 >= PlayerPosMax then Positions := Positions + '3';
              if G_O >= PlayerPosMax then Positions := Positions + 'O';

              if (Mode = 'U') and (AMember.PosList <> Positions) then
                writeln(FileNpos,AMember.Stats.Name:20,
                  '   ',AMember.PosList:7,'   ==>>   ',Positions);

              if (copy (Line80,48,25) <> '') then begin
                while (length(Positions) <= 7) do Positions := Positions + ' ';
                Line80 := copy (Line80,1,39) + Positions + copy (Line80,48,25);
                end
              else
                Line80 := copy (Line80,1,39) + Positions;

              end; {with AMember do begin}
            end; {not AMember.RostPos = 'P'}
          end; {if J >= 0}
        end; {if AMember.Stats.ID <> '00000000'}

        if (J <= 0) or (AMember.Stats.ID = '00000000') then
          Line80 := copy (Line80,1,39) + '<none>  '
                  + copy (Line80,48,25);
      end; {else ParseRostLine (Line80,AMember) then begin}
    end; {'+','?','-','!','&','~','/'}

{
  with AMember do begin
    writeln ('member = ',Stats.Name,' ',Stats.ID,' ',Salary:5:2,' ',Contract,
             ' ',Stats.Status,' ',RostPos,' ',PosList);
    readln;
    end;
}

  writeln (FileElig,Line80);

end; {while not at eof (FileRost)}

close (FileElig);
{  close (FileInfo); }
close (FilePly);
close (FileRost);
close (FileNpos);
ShutDown;

{
reset (FileErr);
writeln;
while not(eof (FileErr)) do begin
  readln (FileErr,Line120);
  writeln (Line120);
  end; } {while not at eof (FileErr)}

writeln ('ML/Date/League/Mode: ',ML,' ',StatMMDD,' ',RotLeag,' ',Mode);

{ writeln (^G)};

end. {Elig}
program Calc5;
{
calculate a league's current stats
get the major league, rot league, date and mode;
read in the player data and create the index array;
read ROST file;
  get team abbr, owner, name, mgr, phone #s, addr;
  get members of roster for the team and load onto appropriate array;
  at end of team;
    for each player on each array;
      find stats in player file;
      write player stats to hold file;
      add stats to totals;
print totals;
write FABs and free agents;
}
{9203 - added K/BB category for NRL}
{9203 - added column headers for pitchers and hitters}
{9203 - removed PLAYER IDs from report}
{9204 - rearranged format to show hdr-player-totals}
{9204 - separated teams on one page with hyphen-line}
{9204 - added date/time/page number to top of page}
{9204 - check for exactly 23 players/team}
{9209 - permit 24 players/team in September}
{9303 - use single ROST<mmdd>.<leag> file}
{9303 - added PREVIOUS and WEEK'S totals}
{9304 - generate page break for each team}
{9304 - mark players using NewPly as they are used}
{9304 - generate Free List}
{9305 - generate Hold File of Free List stats for preceding week}
{9305 - remove PREVIOUS WEEK's stats}
{9305 - include stats for NEW file in Free List}
{9403 - include owner info, status, salary, position in ROST file}
{9405 - use UTILSUBS and array instead of linked list for ID index}
{9405 - include reserves, minors, picks & FAB in ROST file}
{9406 - include asterisk trade indicator}
{9507 - show FREC and FREY}
{9603 - converted to SpinStats from TQS}
{9606 - implemented Projection Mode and QuickModes, WhatifModes}
{9608 - added ~ for waivers}
{9703 - added team name to 'needed' line; 'needed' info to front page}
{9711 - added 'FAB Remaining' to front page}
{9712 - chgd '@' to email addr and '!' to ACTIVATED}
{9803 - upped to $28, 25 players - 10th P, 2nd U}
{9803 - chgd 276 to NumOfTeams * NumOfPlayers; $312 to NumOfTeams * $28}
{0003 - minimized err list; display input parms}
{0005 - rearrange pitching stats}
{0006 - put FAB and asterisk trade on same line}
{0104 - default for ML and RL; convert to YAHOO}
{0204 - convert to YAHOO format 2 - ID is now Str8 instead of integer (NO GO)}
{0304 - convert to TQS format, 5 char IDs; swap P ER & BB columns}
{0503 - accomodate $10.00; include ! players in #/$ calcs}
{0504 - ignore '/' lines in roster file; adjust for 11 teams/$28/27 players}
{0604 - correct FA Pitcher stats display (not recognizing PrimePos = P)}
{0703 - add K and RS to categories; return to 12 teams/$26/25 players}
{0903 - incorporate position-setting}
{1002 - add "Z" = zombie}
{1201 - return to $26/23 players}

{$I DCLSTATS.PAS }

const
  NumOfPlayers  : integer = 23;
  LeagueMinimum : integer = 20;
  PgmName       : Str4 = 'CALC';
  AllModes      : set of char = [' ','F','I','L','P','R','S','T'];
  QuickModes    : set of char = ['F','I','P','R'];
  ScreenModes   : set of char = ['F','I','P','R','T'];
  TeamBudget    : integer = 26;
  WhatifModes   : set of char = ['I','P','R'];
  Zero_ID       : Str8 = '00000000';

{$I UTILSUBS.PAS }
{$I GETRL.PAS }

type
  MemArray = array [0..25] of Member;
  TeamArray = array [0..NumOfNL] of Team;

var
  Active            : boolean;
  AfterSept1        : boolean;
  AMember           : Member;
  APlayer           : Player;
  ArrayActPit       : MemArray;
  ArrayActHit       : MemArray;
  ArrayMinors       : MemArray;
  ArrayPicks        : MemArray;
  ArrayResPit       : MemArray;
  ArrayResHit       : MemArray;
  ArrayUtilHit      : MemArray;
  ArrayUtilPit      : MemArray;
  ArrayXtraHit      : MemArray;
  ArrayXtraPit      : MemArray;
  ArrayKeys         : array [0..999] of Str8;
  AsterTrade        : Str24;
  ATeam             : Team;
  Ave               : real;
  CntKeys           : integer;
  CntLeagPlyrs      : integer;
  CntTeamPlyrs      : integer;
  Cont              : char;
  Count_C           : integer;
  Count_1           : integer;
  Count_2           : integer;
  Count_S           : integer;
  Count_3           : integer;
  Count_O           : integer;
  CurrPlayerKey     : integer;
  CurrTeam          : Str24;
  ERA               : real;
  Err               : boolean;
  FabRemaining      : real;
  FileCWKs          : text;
  FileFABs          : text;
  FileFreC          : text;
  FileFreY          : text;
  FileHold          : text;
  FileInfo          : text;
  FileLeag          : file of Team;
  FileNeed          : text;
  FileNew           : text;
  FilePly           : file of Player;
  FilePlyCurr       : Str24;
  FilePos           : text;
  FileRost          : text;
  FileWaiv          : text;
  FileYTDs          : text;
  Fraction          : integer;
  HitPts            : array [1..NumOfNL] of real;
  I                 : integer;
  J                 : integer;
  LeagExtraPlayer   : integer;
  LeagExtraSalary   : real;
  Line80            : Str80;
  Line120           : Str120;
  Mantissa          : integer;
  MaxC              : integer;
  MaxH              : integer;
  MaxOF             : integer;
  MaxMemArray       : integer;
  MaxP              : integer;
  MaxUHit           : integer;
  MaxUPit           : integer;
  MaxXHit           : integer;
  MaxXPit           : integer;
  ML                : char;
  Mode              : char;
  NewID             : Str8;
  NewPlyInd         : boolean;
  NumOfTeams        : integer;
  OffsetC           : integer;
  OffsetMinors      : integer;
  OffsetOF          : integer;
  OffsetP           : integer;
  OffsetPicks       : integer;
  OffsetResPit      : integer;
  OffsetResHit      : integer;
  OffsetUtilP       : integer;
  OffsetUtilH       : integer;
  OldPos            : char;
  P1,P2             : Str40;
  PageNum           : integer;
  PitPts            : array [1..NumOfNL] of real;
  PlayerPosMax      : integer;
  Positions         : Str8;
  PrevTeam          : Str12;
  PriceLeag         : real;
  PriceTeam         : real;
  RecType           : char;
  Regs              : Registers;
  RotLeag           : Str3;
  RptDate           : Str8;
  RptTime           : Str8;
  RS                : integer;
  ShowDate          : Str8;
  StartPtr          : ListPtr;
  StartAveList,
  StartERAList,
  StartHPtsList,
  StartHRList,
  StartPKList,
  StartPPtsList,
  StartRBIList,
  StartRSList,
  StartSBList,
  StartSVList,
  StartTieList,
  StartTPtsList,
  StartWHIPList,
  StartWinList      : RankPtr;
  TeamAbbr          : Str4;
  TeamCurrArray     : TeamArray;
  TeamExtra         : record
    Owner           : Str18;
    Mgr             : Str40;
    Email           : Str80;
    PhoneH,PhoneW   : Str12;
    PlayerExtra     : integer;
    SalaryExtra     : real;
    end; {TeamExtra}
  TeamNum           : integer;
  TeamPrevArray     : TeamArray;
  TempStr2          : Str2;
  TotalPts          : array [1..NumOfNL] of real;
  WkFactor          : real;
  WkNum             : integer;
  WHIP              : real;
  WrkPlayer         : Player;



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
    writeln (FileInfo,'ID ',ID,' not found in index');
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


{========================= InitMemberArray  =========================}
{
for each elt from 0 to (MaxMemArray - 1) do ID := Zero_ID;
}

procedure InitMemberArray (var A:MemArray);

var
  I : integer;

begin

for I := 0 to (MaxMemArray - 1) do begin
  A [I].RostPos  := ' ';
  A [I].Stats.ID := Zero_ID;
end; {for I := 0 to (MaxMemArray - 1) do begin}


end; {InitMemberArray}




{========================= DeletePlayer  =========================}
{
set the player index array at position X to '    ';
}

procedure DeletePlayer (X:integer);

begin

ArrayKeys [X] := '        ';

end; {DeletePlayer}




{========================= DeleteList  =========================}
{
trace thru a linked list and dispose of each elt.
}

procedure DeleteList (var L:RankPtr);

var
   X : RankPtr;

begin

while (L <> NIL) do begin
  X := L;
  L := L^.Next;
  dispose (X);
  end; {while L <> NIL}

end; {DeleteList}



{========================= GetPosList  =========================}
{
create the Position List for member M for the period P;

set the Positions to null, max to 1, and all counts to 0;
if initializing positions
  find max for this player
  if player max is >= league max, use league max else use player max;
else not initializing
  player max stays at 1
  add 1 to each position count that is already on the PosList;
if position count is >= player max
  add that position to the Positions
pad Positions on right
copy Positions to PosList
}

procedure GetPosList(var M:Member;P:char);

var
  X        : PlayerStats;

begin

Positions    := '';
PlayerPosMax := 1;
Count_C      := 0;
Count_1      := 0;
Count_2      := 0;
Count_S      := 0;
Count_3      := 0;
Count_O      := 0;

if P = 'C' then X := M.Stats.CWK else X := M.Stats.YTD;

with X do begin

   if Mode = 'I' then begin
      if G_C > PlayerPosMax then PlayerPosMax := G_C;
      if G_1 > PlayerPosMax then PlayerPosMax := G_1;
      if G_2 > PlayerPosMax then PlayerPosMax := G_2;
      if G_S > PlayerPosMax then PlayerPosMax := G_S;
      if G_3 > PlayerPosMax then PlayerPosMax := G_3;
      if G_O > PlayerPosMax then PlayerPosMax := G_O;

      if PlayerPosMax >= LeagueMinimum then PlayerPosMax := LeagueMinimum;
      end {if Mode = 'I'}

   else {not Mode = 'I'} begin
      if Pos('C',M.PosList) > 0 then G_C := G_C + 1;
      if Pos('1',M.PosList) > 0 then G_1 := G_1 + 1;
      if Pos('2',M.PosList) > 0 then G_2 := G_2 + 1;
      if Pos('S',M.PosList) > 0 then G_S := G_S + 1;
      if Pos('3',M.PosList) > 0 then G_3 := G_3 + 1;
      if Pos('O',M.PosList) > 0 then G_O := G_O + 1;
      end; {not Mode = 'I'}

   if G_C >= PlayerPosMax then Positions := Positions + 'C';
   if G_1 >= PlayerPosMax then Positions := Positions + '1';
   if G_2 >= PlayerPosMax then Positions := Positions + '2';
   if G_S >= PlayerPosMax then Positions := Positions + 'S';
   if G_3 >= PlayerPosMax then Positions := Positions + '3';
   if G_O >= PlayerPosMax then Positions := Positions + 'O';

   if M.PosList <> Positions then
     writeln(FilePos,M.Stats.Name:15,':',M.PosList:7,
                                     '   ==>>   ',Positions);

   while (length(Positions) <= 7) do Positions := Positions + ' ';
   M.PosList := Positions;

end; {with X do}

end; {GetPosList}



{========================= ShowStats  =========================}
{
write to file F the stats for member M for the period P;
if P = 'C' then current week else year-to-date.
}

procedure ShowStats (var F:text;M:Member;P:char);

var
  AVG,
  ERA,
  WHIP     : real;
  I        : integer;
  Pitcher  : boolean;
  X        : PlayerStats;

begin

{
writeln ('name=',M.Stats.Name);
writeln ('id=  ',M.Stats.ID);
writeln ('pos= ',M.RostPos);
readln;
}
{',pos=',M.PosList[1]); }

with M do if (Stats.ID >= Zero_ID) and (RostPos <> ' ') then begin
  if P = 'C' then X := Stats.CWK else X := Stats.YTD;

  Pitcher := (RostPos = 'P') or (M.Stats.PrimePos = 'P ');

  with X do begin
    if (Stats.Status = '?') or (Stats.Status = '!') then write (F,Stats.Status)
    else write (F,' ');
    write (F,RostPos);
    write (F,' ');
    if ord(Stats.Name[0]) > 15 then Stats.Name[0] := chr(15);
    I := 16 - ord(Stats.Name[0]);
    write (F,Stats.Name,' ':I);
    write (F,Salary:5:2);
    if (copy (ShowDate,7,2) = copy (Contract,1,2))
        or (copy (Contract,1,1) = 'Z')
        or ((Salary >= 2.50) and (copy (Contract,1,1) <> 'F')) then
      write (F,'* ')
    else write (F,'  ');
    for I := 1 to 2 do write (F,Contract [I]);

    if Pitcher then begin
      if IP > 0 then begin
        WHIP := (X.H + X.BB) / X.IP;
        ERA := ER * 9 / IP;
        WHIP := (X.H + X.BB) / IP;
        end
      else begin
        ERA := 0;
        WHIP := 0;
        end; {else IP = 0}

      write (F,W:3);
      write (F,SV:4);
      write (F,K:5);
      write (F,ERA:8:3);
      write (F,WHIP:8:3);
      write (F,IP:7:1);
      write (F,X.H:5);
      write (F,BB:5);
      write (F,ER:5);
      writeln (F);
      end {if Pitcher}

    else {Hitter} begin

{     GetPosList (M,P); }

{ writeln;write ('Name=',M.Stats.Name,' ,pos=',M.PosList,'*');readln; }

      if AB > 0 then AVG := X.H / AB
      else AVG := 0;

      write (F,AB:4);
      write (F,X.H:5);
      write (F,HR:5);
      write (F,RBI:5);
      write (F,R:5);
      write (F,SB:5);
      write (F,AVG:8:4);
      write (F,PosList:7);
      writeln (F);

      end; {else Hitter}
    end; {with X do}
  end; {with M if Stats.ID > Zero_ID}

end; {ShowStats}



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
if not (M.RostPos in PositionSet) then M.RostPos := ' ';
{ writeln ('PosSet-name:',M.Stats.Name,' ,RostPos:',M.RostPos,'|');}

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



{========================= AddToTotals =========================}
{
for each member M of team T;
  adds the stats of M to the current total for T;
}
procedure AddToTotals (T:integer;var A:MemArray;N:integer);

var
  I,K     : integer;
  Pitcher : boolean;

begin

for I := 0 to (N - 1) do with A [I].Stats do

  if (ID >= Zero_ID) and (A [I].RostPos <> ' ') then
    with TeamCurrArray [T] do begin

    PriceTeam := PriceTeam + A [I].Salary;

    Pitcher := (A[I].PosList[1] = 'P');

    if (Mode = 'P') then
      if Pitcher then begin
        Wins   := Wins  + round (YTD.W  * WkFactor);
        Saves  := Saves + round (YTD.SV * WkFactor);
        ERuns  := ERuns + round (YTD.ER * WkFactor);
        PHits  := PHits + round (YTD.H  * WkFactor);
        PKs    := PKs   + round (YTD.K  * WkFactor);
        Walks  := Walks + round (YTD.BB * WkFactor);
        Inns   := Inns  + round (YTD.IP * WkFactor);
        end

      else begin
        HRuns  := HRuns  + round (YTD.HR  * WkFactor);
        RBIs   := RBIs   + round (YTD.RBI * WkFactor);
        Runs   := Runs   + round (YTD.R   * WkFactor);
        Steals := Steals + round (YTD.SB  * WkFactor);
        HHits  := HHits  + round (YTD.H   * WkFactor);
        ABats  := ABats  + round (YTD.AB  * WkFactor);
      end {else hitter}

    else if not (Mode = 'R') then
      if Pitcher then begin
        Wins   := Wins  + CWK.W;
        Saves  := Saves + CWK.SV;
        ERuns  := ERuns + CWK.ER;
        PHits  := PHits + CWK.H;
        PKs    := PKs   + CWK.K;
        Walks  := Walks + CWK.BB;
        Inns   := Inns  + CWK.IP;
        end

      else begin
        HRuns  := HRuns  + CWK.HR;
        RBIs   := RBIs   + CWK.RBI;
        Runs   := Runs   + CWK.R;
        Steals := Steals + CWK.SB;
        HHits  := HHits  + CWK.H;
        ABats  := ABats  + CWK.AB;
      end; {else hitter}

    end; {if ID >= Zero_ID}

end; {AddToTotals}




{========================= AssignToPosition =========================}
{
place member M in appropriate array at specific position.
}

procedure AssignToPosition (var A:MemArray;P:integer;M:Member);

begin

if A[P].Stats.ID <> Zero_ID then begin
  writeln ('overlay on ',A[P].Stats.Name,' by ',M.Stats.Name);
  writeln (FileErr,'overlay on ',A[P].Stats.Name,' by ',M.Stats.Name);
  end {if A[P].Stats.ID <> Zero_ID then begin}

else A[P] := M;

end; {AssignToPosition}




{========================= PutOnTeam =========================}
{
place member M in appropriate array:
  active pitcher;
  active hitter;
  reserve pitcher;
  reserve hitter;
}

procedure PutOnTeam (T:integer;M:Member);

var
  Pos        : char;
  TempBase   : integer;
  TempMax    : integer;
  TempOffset : integer;
  Pitcher    : boolean;

begin

Pos := M.RostPos;
Pitcher := (M.PosList[1] = 'P') or (M.RostPos = 'P');

if not Active then begin
  if Pitcher then begin
    ArrayResPit [OffsetResPit] := M;
    OffsetResPit := OffsetResPit + 1;
    end
  else begin
    ArrayResHit [OffsetResHit] := M;
    OffsetResHit := OffsetResHit + 1;
    end;
  if M.Stats.Status = '!' then begin
    TeamExtra.PlayerExtra := TeamExtra.PlayerExtra + 1;
    TeamExtra.SalaryExtra := TeamExtra.SalaryExtra + M.Salary;
    end;
  end {if not Active}

else begin
  CntTeamPlyrs := CntTeamPlyrs + 1;
  if Pitcher then begin
    if Pos = 'X' then AssignToPosition (ArrayXtraPit,0,M)
    else if Pos = 'U' then begin
      TempBase    := 0;
      TempOffset  := OffsetUtilP;
      TempMax     := MaxUPit;
      OffsetUtilP := OffsetUtilP + 1;

      if TempOffset >= TempMax then TempOffset := TempMax
      else AssignToPosition (ArrayUtilPit,TempBase + TempOffset,M);
      end {else if Pos = 'U'}
    else begin
      AssignToPosition (ArrayActPit,OffsetP,M);
      OffsetP  := OffsetP + 1;
      end {else not U or X}
    end {if Pitcher}
  else begin
    if Pos = 'X' then AssignToPosition (ArrayXtraHit,0,M)
    else if Pos = 'U' then begin
      TempBase    := 0;
      TempOffset  := OffsetUtilH;
      TempMax     := MaxUHit;
      OffsetUtilH := OffsetUtilH + 1;

      if TempOffset >= TempMax then TempOffset := TempMax
      else AssignToPosition (ArrayUtilHit,TempBase + TempOffset,M);
      end {else if Pos = 'U'}

    else begin
      TempOffset := 0;
      TempMax := 1;
      case Pos of
        'C' : begin
              TempBase   := 0;
              TempOffset := OffsetC;
              TempMax    := MaxC;
              OffsetC    := OffsetC + 1;
              end;
        'O' : begin
              TempBase   := 8;
              TempOffset := OffsetOF;
              TempMax    := MaxOF;
              OffsetOF   := OffsetOF + 1;
              end;
        '1' : TempBase   := 2;
        '2' : TempBase   := 3;
        'S' : TempBase   := 4;
        '3' : TempBase   := 5;
        'W' : TempBase   := 6;
        'M' : TempBase   := 7;
        else  begin
              writeln ('pos not found: ',Pos,' for: ',M.Stats.Name);
              writeln (FileErr,'pos not found: ',Pos,' for: ',M.Stats.Name);
              end;
        end; {case Pos of}

      if TempOffset >= TempMax then TempOffset := TempMax
      else AssignToPosition (ArrayActHit,TempBase + TempOffset,M);

      end; {else not U or X}

    end; {else not Pitcher}

{
write ('pos = ',Pos,
       ' Cnt = ',CntTeamPlyrs,
       ' ,Name:',M.Stats.Name,
       ' ,P?',Pitcher
       );
readln;
}

  end; {else Active}

end; {PutOnTeam}



{========================= InsertTeamInList =========================
create an entry in the given category's list for ATeam.}

procedure InsertTeamInList (ATeam:Team;Val:real;var StartList:RankPtr;Dir:char);

var
  APtr,
  CurrPlayerKey  : RankPtr;

begin

with ATeam do begin
  new (APtr);
  APtr^.Name    := Name;
  APtr^.Abbr    := Abbr;
  APtr^.TeamNum := TeamNum;
  APtr^.Value   := Val;
  APtr^.Pts     := 0;
  APtr^.Tied    := ' ';
  APtr^.Next    := NIL;
  APtr^.Prev    := NIL;

  if StartList = NIL then StartList := APtr
  else begin
    CurrPlayerKey := StartList;
    while CurrPlayerKey <> NIL do begin
      if (Val = CurrPlayerKey^.Value) then begin
        APtr^.Tied    := '*';
        CurrPlayerKey^.Tied := '*';
        end; {if tied}

      if ((Dir = 'A') and (Val > CurrPlayerKey^.Value))
                    or ((Dir = 'D') and (Val < CurrPlayerKey^.Value)) then begin
        if CurrPlayerKey^.Next = NIL then begin
          APtr^.Prev := CurrPlayerKey;
          CurrPlayerKey^.Next := APtr;
          CurrPlayerKey := NIL;
          end {if at end of list}
        else CurrPlayerKey := CurrPlayerKey^.Next;
        end {if still looking}

      else begin
        if CurrPlayerKey^.Prev = NIL then StartList := APtr
        else CurrPlayerKey^.Prev^.Next := APtr;
        APtr^.Prev := CurrPlayerKey^.Prev;
        CurrPlayerKey^.Prev := APtr;
        APtr^.Next := CurrPlayerKey;
        CurrPlayerKey := NIL;
        end; {else insert here}
      end; {while not at end of list}
    end; {else non-null list}
  end; {with APtr}

end; {InsertTeamInList}


{========================= PageBreak =========================
generates new page hdr
}

procedure PageBreak;

var
  I : integer;

begin

PageNum := PageNum + 1;

writeln (FileHold,^L);
writeln (FileHold,RptDate,' ',RptTime:5,' ':16,RotLeag,' Standings',
                  'Page: ':27,PageNum);
writeln (FileHold);

if (PageNum <> (2 * int (PageNum / 2))) then begin
  writeln (FileFreC,^L);
  writeln (FileFreC,RptDate,' ',RptTime:5,' ':16,RotLeag,' Standings',
                    'Page: ':27,PageNum);
  end {if PageNum is even}
else for I := 1 to 75 do write (FileFreC,'-');
writeln (FileFreC);

end; {PageBreak}



{========================= ComputePointsInList =========================
read thru list and compute points for each elt;
read thru list and add points to the appropriate team's totals
  for pitching or hitting.}

procedure ComputePointsInList (StartPtr:RankPtr;Catg:char);

var
  NumPts   : real;
  I,
  PtsLeft  : integer;
  BeginPtr,
  CurrPlayerKey  : RankPtr;

begin

BeginPtr := StartPtr;
CurrPlayerKey  := StartPtr;
NumPts   := NumOfTeams;
PtsLeft  := NumOfTeams;

while CurrPlayerKey <> NIL do begin
  PtsLeft := PtsLeft - 1;

  if CurrPlayerKey^.Next <> NIL then begin
    if CurrPlayerKey^.Value <> CurrPlayerKey^.Next^.Value then begin
      repeat
        BeginPtr^.Pts := NumPts;
        BeginPtr := BeginPtr^.Next;
        until BeginPtr = CurrPlayerKey^.Next;
      NumPts := PtsLeft;
      end {if CurrVal = NextVal}
    else NumPts := NumPts - 0.5;
    end {if Next is not end of list}
  else
    repeat
      BeginPtr^.Pts := NumPts;
      BeginPtr := BeginPtr^.Next;
      until BeginPtr = CurrPlayerKey^.Next;
  CurrPlayerKey := CurrPlayerKey^.Next;
  end; {while not at end of list}

CurrPlayerKey := StartPtr;
while CurrPlayerKey <> NIL do begin
  if Catg = 'P' then
    PitPts [CurrPlayerKey^.TeamNum] := PitPts [CurrPlayerKey^.TeamNum] + CurrPlayerKey^.Pts
  else
    HitPts [CurrPlayerKey^.TeamNum] := HitPts [CurrPlayerKey^.TeamNum] + CurrPlayerKey^.Pts;
  CurrPlayerKey := CurrPlayerKey^.Next;
  end;

end; {ComputePointsInList}


{========================= CalcPointTotals =========================}
{
for each team, initialize pitching and hitting points to zero;
assign points to each entry in list;
insert pitching totals, hitting totals and overall totals to new lists;
}

procedure CalcPointTotals (var A:TeamArray);

begin

for I := 1 to NumOfTeams do begin
  PitPts [I] := 0;
  HitPts [I] := 0;
  end; {initialize arrays to zero}

ComputePointsInList (StartWinList,'P');
ComputePointsInList (StartSVList,'P');
ComputePointsInList (StartPKList,'P');
ComputePointsInList (StartERAList,'P');
ComputePointsInList (StartWHIPList,'P');
ComputePointsInList (StartHRList,'H');
ComputePointsInList (StartRBIList,'H');
ComputePointsInList (StartRSList,'H');
ComputePointsInList (StartSBList,'H');
ComputePointsInList (StartAveList,'H');

for I := 1 to NumOfTeams do begin
  InsertTeamInList (A [I],PitPts[I],StartPPtsList,'D');
  InsertTeamInList (A [I],HitPts[I],StartHPtsList,'D');
  InsertTeamInList (A [I],PitPts[I]+HitPts[I],StartTPtsList,'D');
  end; {for each team}

end; {CalcPointTotals}


{ ---------------------------------------------------------------------- }
{                   R E S O L V E   T I E S                              }
{                                                                        }
{ Show 3 * IP + AB for tied teams.                                       }
{ ---------------------------------------------------------------------- }
procedure ResolveTies (var F:text;AnAbbr:Str4);

var
  CurrPlayerKey      : RankPtr;

begin

CurrPlayerKey := StartTieList;

while (CurrPlayerKey <> NIL) do
  if (CurrPlayerKey^.Abbr = AnAbbr) then begin
    write (F,'*   (3*IP+AB)=',CurrPlayerKey^.Value:5:0);
    CurrPlayerKey := NIL;
    end {if team is found}
  else CurrPlayerKey := CurrPlayerKey^.Next;

end; {ResolveTies}


{========================= PrintStds =========================}
{
print hdrs;
for overall, pitching and hitting category groups;
  read thru lists;
    for each of the four categories print team abbr, category value and points;
}

procedure PrintStds (var F:text);

var
  AvePtr,
  ERAPtr,
  HitPtr,
  HRPtr,
  PKPtr,
  RBIPtr,
  RSPtr,
  SBPtr,
  SVPtr,
  WinPtr,
  WHIPPtr        : RankPtr;

  PointsBehind,
  PointsMax      : real;

begin

clrscr;

writeln (F);

write (F,'                             ');
writeln (F,RotLeag,' STANDINGS BY CATEGORY - ',ShowDate);
writeln (F);
writeln (F);
writeln (F);
write (F,'           WINS           SAVES                K',
         '              ERA                 WHIP');
writeln (F);

WinPtr  := StartWinList;
SVPtr   := StartSVList;
PKPtr   := StartPKList;
ERAPtr  := StartERAList;
WHIPPtr := StartWHIPList;

while WinPtr <> NIL do begin
  write (F,'       ');
  write (F,WinPtr^.Abbr,WinPtr^.Value:4:0,WinPtr^.Pts:5:1,'   ');
  write (F,SVPtr^.Abbr,SVPtr^.Value:4:0,SVPtr^.Pts:5:1,'   ');
  write (F,PKPtr^.Abbr,PKPtr^.Value:5:0,PKPtr^.Pts:5:1,'   ');
  write (F,ERAPtr^.Abbr,ERAPtr^.Value:8:5,ERAPtr^.Pts:5:1,'   ');
  write (F,WHIPPtr^.Abbr,WHIPPtr^.Value:8:5,WHIPPtr^.Pts:5:1);
  writeln (F);

  WinPtr  := WinPtr^.Next;
  SVPtr   := SVPtr^.Next;
  PKPtr   := PKPtr^.Next;
  ERAPtr  := ERAPtr^.Next;
  WHIPPtr := WHIPPtr^.Next;
  end; {while not at end of list}

if Mode = 'T' then readln;

clrscr;
writeln (F);
writeln (F);
writeln (F);
writeln (F,'             HR              RBI               RS',
           '              SB               AVE');

HRPtr  := StartHRList;
RBIPtr := StartRBIList;
RSPtr  := StartRSList;
SBPtr  := StartSBList;
AvePtr := StartAveList;

while HRPtr <> NIL do begin
  write (F,'       ');
  write (F,HRPtr^.Abbr,HRPtr^.Value:4:0,HRPtr^.Pts:5:1,'   ');
  write (F,RBIPtr^.Abbr,RBIPtr^.Value:5:0,RBIPtr^.Pts:5:1,'   ');
  write (F,RSPtr^.Abbr,RSPtr^.Value:5:0,RSPtr^.Pts:5:1,'   ');
  write (F,SBPtr^.Abbr,SBPtr^.Value:4:0,SBPtr^.Pts:5:1,'   ');
  write (F,AvePtr^.Abbr,AvePtr^.Value:8:5,AvePtr^.Pts:5:1);
  writeln (F);

  HRPtr  := HRPtr^.Next;
  RBIPtr := RBIPtr^.Next;
  RSPtr  := RSPtr^.Next;
  SBPtr  := SBPtr^.Next;
  AvePtr := AvePtr^.Next;
  end; {while not at end of list}

if Mode = 'T' then readln;

clrscr;

writeln (F);
writeln (F);
writeln (F);
writeln (F,'                 OVERALL STANDINGS - ',ShowDate);
writeln (F);
writeln (F,'       PITCHING     HITTING      TOTAL      POINTS BEHIND');

ERAPtr := StartPPtsList;
HRPtr  := StartHPtsList;
WinPtr := StartTPtsList;

PointsMax := WinPtr^.Value;

while WinPtr <> NIL do begin
  PointsBehind := PointsMax - WinPtr^.Value;

  write (F,'       ');
  write (F,ERAPtr^.Abbr,ERAPtr^.Value:5:1,'   ');
  write (F,HRPtr^.Abbr,HRPtr^.Value:5:1,'   ');
  write (F,WinPtr^.Abbr,WinPtr^.Value:5:1,'   ');
  if PointsBehind = 0 then write (F,'--':8,'      ')
  else write (F,'     ',PointsBehind:4:1,'     ');

  if (WinPtr^.Tied = '*') then ResolveTies (F,WinPtr^.Abbr);

  writeln (F);

  ERAPtr := ERAPtr^.Next;
  HRPtr  := HRPtr^.Next;
  WinPtr := WinPtr^.Next;

  end; {while not at end of list}

end; {PrintStds}




{========================= PrintPitHdr =========================}
{Prints the pitching headers in file F}

procedure PrintPitHdr (var F:text);

begin

write (F,'    PITCHER');
write (F,'          $');
write (F,'    YR');
write (F,'  W');
write (F,'  SV');
write (F,'    K');
write (F,'    ERA');
write (F,'     WHIP');
write (F,'    IP');
write (F,'     H');
write (F,'   BB');
write (F,'   ER');
writeln (F);

end; {PrintPitHdr}



{========================= PrintHitHdr =========================}
{Prints the hitting headers in file F}

procedure PrintHitHdr (var F:text);

begin

write (F,'    HITTER');
write (F,'           $');
write (F,'    YR');
write (F,'  AB');
write (F,'    H');
write (F,'   HR');
write (F,'  RBI');
write (F,'   RS');
write (F,'   SB');
write (F,'   AVE');
writeln (F);

end; {PrintHitHdr}



{========================= PrintPitTotals =========================
Prints the pitching totals for a team.}

procedure PrintPitTotals (var F:text;T:Team;PWC:char);

var
  PWCLabel : array [1..9] of char;

begin

case PWC of
  'C'  : PWCLabel := 'Current: ';
  'P'  : PWCLabel := 'Previous:';
  'W'  : PWCLabel := 'For Week:';
  else   PWCLabel := '???      ';
  end; {case PWC}

with T do begin

  write (F,TeamAbbr,' Pitching ',PWCLabel,'    ');
  write (F,Wins:4);
  write (F,Saves:4);
  write (F,PKs:5);
  write (F,ERA:8:3);
  write (F,WHIP:8:3);
  write (F,Inns:7:1);
  write (F,PHits:5);
  write (F,Walks:5);
  write (F,ERuns:5);
  writeln (F);

  end; {with T}

end; {PrintPitTotals}



{========================= PrintHitTotals =========================
Prints the hitting totals for a team.}

procedure PrintHitTotals (var F:text;T:Team;PWC:char);

var
  PWCLabel : array [1..10] of char;

begin

case PWC of
  'C'  : PWCLabel := 'Current:  ';
  'P'  : PWCLabel := 'Previous: ';
  'W'  : PWCLabel := 'For Week: ';
  else   PWCLabel := '???       ';
  end; {case PWC}

with T do begin

  write (F,TeamAbbr,' Hitting ',PWCLabel,'    ');
  write (F,ABats:5);
  write (F,HHits:5);
  write (F,HRuns:5);
  write (F,RBIs:5);
  write (F,Runs:5);
  write (F,Steals:5);
  write (F,Ave:8:4);
  writeln (F);

  end; {with T}

end; {PrintHitTotals}



{========================= PrintMemberArray =========================}
{
for each member from 0 to X in array A
  show stats from period P in file F;
}

procedure PrintMemberArray (var F:text;A:MemArray;X:integer;P:char);

var
   I : integer;

begin

for I := 0 to (X - 1) do ShowStats (F,A [I],P);

end; {PrintMemberArray}




{========================= PrintTeamExtra =========================}
{
with team T, write to file F
  reserved players for period P;
  FAB remaining;
  Asterisk Trade status;
  minor leaguers;
  draft picks;
}

procedure PrintTeamExtra (var F:text;T:integer;P:char);

var
  I,J : integer;
  Plyrs,Dollars,Price : real;

begin

if OffsetMinors > 0 then begin
  writeln (F);
  writeln (F,'Minor Leaguers:');
  for I:= 0 to (OffsetMinors - 1) do
    with ArrayMinors [I] do begin
      J := 20 - ord(Stats.Name[0]);
      writeln (F,Stats.Name,' ':J,Stats.MLTeam:4,Salary:6:2,'   ',PosList);
    end; {with ArrayMinors [I]}
end; {if OffsetMinors > 0}

writeln (F);

write (F,TeamAbbr,' FAB Remaining: $ ',FabRemaining:5:2);
write (FileFABs,TeamAbbr,' FAB Remaining: $ ',FabRemaining:5:2);

writeln (F,'   /   ',TeamAbbr ,' - ',AsterTrade);

if OffsetPicks > 0 then begin
{  writeln (F);  }
  write (F,'Draft Picks: ');
  for I:= 0 to (OffsetPicks - 1) do with ArrayPicks [I] do begin
    J := 16;
    while (J > 1) and (Stats.Name [J] = ' ') do J := J - 1;
    if J > 1 then write (F,copy (Stats.Name,1,J));
    if I < (OffsetPicks - 1) then write (F,', ');
  end; {for I := 0 to OffsetPicks}
  writeln (F);
end; {if OffsetPicks > 0}

{
writeln (F);
write (F,TeamAbbr,': ',CntTeamPlyrs:2,' for $ ',PriceTeam:5:2);
write (FileNeed,TeamAbbr,': ',CntTeamPlyrs:2,' for $ ',PriceTeam:5:2);
}

if CntTeamPlyrs = NumOfPlayers then begin
  Plyrs   := 0;
  Dollars := 0;
  Price   := 0;
  end
else begin
  Plyrs   := NumOfPlayers - CntTeamPlyrs;
  Dollars := TeamBudget - PriceTeam;
  Price   := Dollars / Plyrs;
  end; {if CntTeamPlyrs = NumOfPlayers}

{
write (F,'; need ',Plyrs:2:0,' for $ ',Dollars:5:2,' = ',Price:5:2);
write (FileNeed,'; need ',Plyrs:2:0,' for $ ',Dollars:5:2,' = ',Price:5:2);
}

if (CntTeamPlyrs + TeamExtra.PlayerExtra) = NumOfPlayers then begin
  Plyrs   := 0;
  Dollars := 0;
  Price   := 0;
  end
else begin
  Plyrs   := NumOfPlayers - CntTeamPlyrs - TeamExtra.PlayerExtra;
  Dollars := TeamBudget - PriceTeam - TeamExtra.SalaryExtra;
  Price   := Dollars / Plyrs;
  end; {if (CntTeamPlyrs + TeamExtra.PlayerExtra) = NumOfPlayers}

{
write (F,' (',Plyrs:2:0,' for $ ',Dollars:5:2,' = ',Price:5:2,')');
write (FileNeed,' (',Plyrs:2:0,' for $ ',Dollars:5:2,' = ',Price:5:2,')');

writeln (F);
writeln (FileNeed);
}

end; {PrintTeamExtra}



{========================= PrintTeamTotals =========================
Prints the pitching and hitting totals for a team.}

procedure PrintTeamTotals (T:integer);

begin

PrintPitHdr (CON);
PrintPitHdr (FileHold);
PrintPitHdr (FileFreC);

AddToTotals (T,ArrayActPit,MaxP);
PrintMemberArray (CON,ArrayActPit,MaxP,'Y');
PrintMemberArray (FileHold,ArrayActPit,MaxP,'Y');
PrintMemberArray (FileFreC,ArrayActPit,MaxP,'C');

AddToTotals (T,ArrayUtilPit,OffsetUtilP + 1);
PrintMemberArray (CON,ArrayUtilPit,OffsetUtilP + 1,'Y');
PrintMemberArray (FileHold,ArrayUtilPit,OffsetUtilP + 1,'Y');
PrintMemberArray (FileFreC,ArrayUtilPit,OffsetUtilP + 1,'C');

AddToTotals (T,ArrayXtraPit,1);
PrintMemberArray (CON,ArrayXtraPit,1,'Y');
PrintMemberArray (FileHold,ArrayXtraPit,1,'Y');
PrintMemberArray (FileFreC,ArrayXtraPit,1,'C');

with TeamPrevArray[T] do begin
  Wins   := TeamCurrArray[T].Wins   - Wins;
  Saves  := TeamCurrArray[T].Saves  - Saves;
  Inns   := TeamCurrArray[T].Inns   - Inns;
  ERuns  := TeamCurrArray[T].ERuns  - ERuns;
  PHits  := TeamCurrArray[T].PHits  - PHits;
  Walks  := TeamCurrArray[T].Walks  - Walks;
  PKs    := TeamCurrArray[T].PKs    - PKs;
  ERA  := 0;
  WHIP := 0;
  if Inns > 0 then begin
    ERA := ERuns * 9 / Inns;
    WHIP := (PHits + Walks) / Inns;
    end;
  end; {with TeamPrevArray}

PrintPitTotals (CON,TeamPrevArray[T],'W');
PrintPitTotals (FileHold,TeamPrevArray[T],'W');
PrintPitTotals (FileFreC,TeamPrevArray[T],'W');

with TeamCurrArray[T] do begin
  ERA  := 0;
  WHIP := 0;
  if Inns > 0 then begin
    ERA := ERuns * 9 / Inns;
    WHIP := (PHits + Walks) / Inns;
    end;
  end; {with TeamCurrArray}

PrintPitTotals (CON,TeamCurrArray[T],'C');
PrintPitTotals (FileHold,TeamCurrArray[T],'C');
PrintPitTotals (FileFreC,TeamCurrArray[T],'C');

PrintHitHdr (CON);
PrintHitHdr (FileHold);
PrintHitHdr (FileFreC);

AddToTotals (T,ArrayXtraHit,1);
PrintMemberArray (CON,ArrayXtraHit,1,'Y');
PrintMemberArray (FileHold,ArrayXtraHit,1,'Y');
PrintMemberArray (FileFreC,ArrayXtraHit,1,'C');

AddToTotals (T,ArrayUtilHit,OffsetUtilH + 1);
PrintMemberArray (CON,ArrayUtilHit,OffsetUtilH + 1,'Y');
PrintMemberArray (FileHold,ArrayUtilHit,OffsetUtilH + 1,'Y');
PrintMemberArray (FileFreC,ArrayUtilHit,OffsetUtilH + 1,'C');

AddToTotals (T,ArrayActHit,MaxH);
PrintMemberArray (CON,ArrayActHit,MaxH,'Y');
PrintMemberArray (FileHold,ArrayActHit,MaxH,'Y');
PrintMemberArray (FileFreC,ArrayActHit,MaxH,'C');

with TeamPrevArray[T] do begin
  ABats  := TeamCurrArray[T].ABats  - ABats;
  HHits  := TeamCurrArray[T].HHits  - HHits;
  HRuns  := TeamCurrArray[T].HRuns  - HRuns;
  RBIs   := TeamCurrArray[T].RBIs   - RBIs;
  Runs   := TeamCurrArray[T].Runs   - Runs;
  Steals := TeamCurrArray[T].Steals - Steals;
  if ABats > 0 then Ave := HHits / ABats else Ave := 0;
{ write ('AB=',ABats,' ,H=',HHits,' ,Ave=',Ave);readln }
end; {with TeamPrevArray}

PrintHitTotals (CON,TeamPrevArray[T],'W');
PrintHitTotals (FileHold,TeamPrevArray[T],'W');
PrintHitTotals (FileFreC,TeamPrevArray[T],'W');

with TeamCurrArray[T] do begin
  if ABats > 0 then Ave := HHits / ABats else Ave := 0;
{ write ('AB=',ABats,' ,H=',HHits,' ,Ave=',Ave);readln }
end; {with TeamCurrArray}

PrintHitTotals (CON,TeamCurrArray[T],'C');
PrintHitTotals (FileHold,TeamCurrArray[T],'C');
PrintHitTotals (FileFreC,TeamCurrArray[T],'C');

if OffsetResPit > 0 then begin
  writeln (CON);
  writeln (FileHold);
  writeln (FileFreC);
  writeln (CON,'Reserved Pitchers:');
  writeln (FileHold,'Reserved Pitchers:');
  writeln (FileFreC,'Reserved Pitchers:');
  PrintMemberArray (CON,ArrayResPit,OffsetResPit,'Y');
  PrintMemberArray (FileHold,ArrayResPit,OffsetResPit,'Y');
  PrintMemberArray (FileFreC,ArrayResPit,OffsetResPit,'C');
  end; {if OffsetResPit > 0}

if OffsetResHit > 0 then begin
  writeln (CON);
  writeln (FileHold);
  writeln (FileFreC);
  writeln (CON,'Reserved Hitters:');
  writeln (FileHold,'Reserved Hitters:');
  writeln (FileFreC,'Reserved Hitters:');
  PrintMemberArray (CON,ArrayResHit,OffsetResHit,'Y');
  PrintMemberArray (FileHold,ArrayResHit,OffsetResHit,'Y');
  PrintMemberArray (FileFreC,ArrayResHit,OffsetResHit,'C');
  end; {if OffsetResHit > 0}

PrintTeamExtra (CON,T,'Y');
PrintTeamExtra (FileHold,T,'Y');

CntLeagPlyrs := CntLeagPlyrs + CntTeamPlyrs;
PriceLeag := PriceLeag + PriceTeam;

if CntTeamPlyrs <> NumOfPlayers then begin
  if not ((CntTeamPlyrs = NumOfPlayers + 1) and AfterSept1) then begin
    write ('!!!!! ',CntTeamPlyrs:2,' players found for the ',TeamAbbr,' !!!!!');
    if Mode = 'T' then readln else writeln;
    end; {if not 24 in Sept}
  writeln (FileErr,'  !!!!! ',CntTeamPlyrs:2,
                   ' players found for the ',TeamAbbr,' !!!!!');
  end; {if NumOfPlayers players}

end; {PrintTeamTotals}



{========================= InitTeam =========================
Resets counters and initializes team arrays.}

procedure InitTeam;

var
   I : integer;

begin

TeamNum := 1;
while (TeamNum <= NumOfTeams)
               and (TeamCurrArray[TeamNum].Abbr <> ATeam.Abbr) do
  TeamNum := TeamNum + 1;

if TeamNum > NumOfTeams then begin
  writeln ('error in FileRost: ',ATeam.Abbr);
  TeamNum := 1;
  while (TeamNum <= NumOfTeams)
  and (TeamCurrArray[TeamNum].Abbr <> ATeam.Abbr) do
    begin
    TeamNum := TeamNum + 1;
    writeln (TeamNum,' = ',TeamCurrArray[TeamNum].Abbr);
    end; {while not at end of TeamNum}
  Ave := 1/0;
  end; {if no such Team Abbr found}

ATeam.Name := TeamCurrArray[TeamNum].Name;

CntTeamPlyrs := 0;
OffsetResPit := 0;
OffsetResHit := 0;
OffsetC      := 0;
OffsetMinors := 0;
OffsetOF     := 0;
OffsetP      := 0;
OffsetPicks  := 0;
OffsetUtilP  := 0;
OffsetUtilH  := 0;
PriceTeam    := 0;
FabRemaining := 10;

InitMemberArray (ArrayActPit);
InitMemberArray (ArrayActHit);
InitMemberArray (ArrayResPit);
InitMemberArray (ArrayResHit);
InitMemberArray (ArrayUtilHit);
InitMemberArray (ArrayUtilPit);
InitMemberArray (ArrayXtraHit);
InitMemberArray (ArrayXtraPit);

end; {InitTeam}



{========================= StartTeam =========================
Prints headers.}

procedure StartTeam;

var
   I : integer;

begin

TeamNum := 1;
while (TeamNum <= NumOfTeams)
               and (TeamCurrArray[TeamNum].Abbr <> ATeam.Abbr) do
  TeamNum := TeamNum + 1;

if TeamNum > NumOfTeams then begin
  writeln ('error in FileRost: ',ATeam.Abbr);
  Ave := 1/0;
  end; {if no such Team Abbr found}

ATeam.Name := TeamCurrArray[TeamNum].Name;

PageBreak;

if Mode in ScreenModes then begin
  with TeamCurrArray[TeamNum] do writeln (Abbr,' - ',Name,
                                          ' Mgr: ':20,TeamExtra.Mgr);
  with TeamExtra do writeln (Owner,' H:',PhoneH,' W:',PhoneW);
  with TeamExtra do writeln (Email);
  end; {if ScreenModes}

with TeamCurrArray[TeamNum] do writeln (FileHold,Abbr,' - ',Name,
                                                 ' Mgr: ':20,TeamExtra.Mgr);
with TeamExtra do writeln (FileHold,Owner,' H:',PhoneH,' W:',PhoneW);
with TeamExtra do writeln (FileHold,'email addr:',Email);
writeln (FileHold);

with TeamCurrArray[TeamNum] do writeln (FileFreC,Abbr,' - ',Name,
                                                 ' Mgr: ':20,TeamExtra.Mgr);
with TeamExtra do writeln (FileFreC,Owner,' H:',PhoneH,' W:',PhoneW);
with TeamExtra do writeln (FileFreC,'email addr:',Email);
writeln (FileFreC);

end; {StartTeam}


{========================= PutTeamOnList =========================}
{
print team T totals;
insert team T in array A in various category lists;
}

procedure PutTeamOnList (T:integer;A:TeamArray);

begin

with A [T] do begin
  InsertTeamInList (A [T],Wins,StartWinList,'D');
  InsertTeamInList (A [T],Saves,StartSVList,'D');
  InsertTeamInList (A [T],PKs,StartPKList,'D');
  InsertTeamInList (A [T],HRuns,StartHRList,'D');
  InsertTeamInList (A [T],RBIs,StartRBIList,'D');
  InsertTeamInList (A [T],Runs,StartRSList,'D');
  InsertTeamInList (A [T],Steals,StartSBList,'D');

  ERA  := 0;
  WHIP := 0;
  if Inns > 0 then begin
    ERA := ERuns * 9 / Inns;
    WHIP := (PHits + Walks) / Inns;
    end;

  if ABats > 0 then Ave := HHits / ABats else Ave := 0;

  InsertTeamInList (A [T],ERA,StartERAList,'A');
  InsertTeamInList (A [T],WHIP,StartWHIPList,'A');
  InsertTeamInList (A [T],Ave,StartAveList,'D');
  InsertTeamInList (A [T],3*Inns+ABats,StartTieList,'D');
  end; {with A [T]}

end; {PutTeamOnList}



{========================= M A I N =========================}
{
perform set ups;
read in the player ID and create the index array;
read ROST file
  get team name, abbreviation, owner, manager
  for each player on the roster
    load the player into the active/reserve pitcher/hitter arrays;
  for each player in the arrays
    get stats from PLY file;
    show stats on screen and in YTDS file;
    add stats to totals;
calculate overall standings and show them on screen and in YTDS file;
show FABS;
show FREE AGENTS;
show errors;
}

begin {Main Program}

clrscr;

PgmName := 'CALC';

GetLeagDate (ML,StatMMDD,PrevMMDD);

{ KB/20010419=commented out - using 'DSL' as default
GetRotLeag (RotLeag);
}
RotLeag := 'DSL';

StartUp (RotLeag);

Mode := ' ';
repeat
  if not (Mode in AllModes) then begin
    gotoxy (40,16);
    writeln ('* invalid mode *');
    end; {if invalid Mode}
  gotoxy (3,15);                   {column,row}
  write ('Screen mode (Fast/Line/Init Pos/Projection/Roster',
         '/Summary/Team-by-Team)? ');
  readln (Mode);

  Mode := upcase (Mode);

  until (Mode in AllModes) and (Mode <> ' ');

if Mode = 'I' then begin
  gotoxy (9,20);                   {column,row}
  write ('Initializing Positions with a League Minimum of: ',LeagueMinimum);
  readln;
  end; {if Mode = 'I'}

if Mode = 'P' then begin
  WkNum := 1;
  repeat
    if not (WkNum > 0) and (WkNum < 26) then begin
      gotoxy (40,17);
      writeln ('* week must be 1 to 25 *');
      end; {if invalid WkNum}
    gotoxy (10,17);
    write ('Current week? ');
    readln (TempStr2);

    if not GetInt (TempStr2,1,2,WkNum) then WkNum := 0;

    until (WkNum > 0) and (WkNum < 26);

  WkFactor := (26 - WkNum) / WkNum;
  end {if Mode = 'P' then begin}

else WkFactor := 1;

ShowDate := copy (StatMMDD,1,2) + '/' + copy (StatMMDD,3,2)
                                + '/' + copy (CurrDate,1,2);
FilePlyCurr := '\PLY\PLY' + StatMMDD + '.' + ML;

RptDate := CurrDate;
RptTime := CurrTime;

if (copy (RptDate,3,2) > '08') then AfterSept1 := TRUE
else AfterSept1 := FALSE;

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

NumOfTeams   := 0;
PriceLeag    := 0;
CntLeagPlyrs := 0;
MaxMemArray  := 20;
{ MaxUHit      := 2; }
{ MaxUPit      := 2; }
MaxUHit      := 3;
MaxUPit      := 3;
MaxXHit      := 1;
MaxXPit      := 1;
MaxC         := 2;
MaxH         := 13;
MaxOF        := 5;
{ MaxP         := 10; }
MaxP         := 11;
PageNum      := 1;  {was 2 until 20090820}

StartAveList  := NIL;
StartERAList  := NIL;
StartHPtsList := NIL;
StartHRList   := NIL;
StartPKList   := NIL;
StartPPtsList := NIL;
StartRBIList  := NIL;
StartRSList   := NIL;
StartSBList   := NIL;
StartSVList   := NIL;
StartTPtsList := NIL;
StartWHIPList := NIL;
StartWinList  := NIL;
StartTieList  := NIL;

assign (FileCWKs,'\'+RotLeag+'\'+'CWKS'+StatMMDD + '.' + RotLeag);
assign (FileFABs,'\'+RotLeag+'\'+'FABS'          + '.' + RotLeag);
assign (FileFreC,'\'+RotLeag+'\'+'FREC'+StatMMDD + '.' + RotLeag);
assign (FileFreY,'\'+RotLeag+'\'+'FREY'+StatMMDD + '.' + RotLeag);
assign (FileHold,'\'+RotLeag+'\'+'HOLD'+StatMMDD + '.' + RotLeag);
assign (FileInfo,'\'+RotLeag+'\'+'INFO'+StatMMDD + '.' + RotLeag);
assign (FileLeag,'\'+RotLeag+'\'+'LEAG'+PrevMMDD + '.' + RotLeag);
assign (FileNeed,'\'+RotLeag+'\'+'NEEDS'         + '.' + RotLeag);
assign (FilePos ,'\'+RotLeag+'\'+'POS' +StatMMDD + '.' + RotLeag);
assign (FileRost,'\'+RotLeag+'\'+'ROST'+StatMMDD + '.' + RotLeag);
assign (FileWaiv,'\'+RotLeag+'\'+'WAIVERS'       + '.' + RotLeag);
assign (FileYTDs,'\'+RotLeag+'\'+'YTDS'+StatMMDD + '.' + RotLeag);

if Mode in WhatifModes then begin
  assign (FileRost,'\'+RotLeag+'\'+'ROSTCURR.' + RotLeag);
  assign (FileLeag,'\'+RotLeag+'\'+'LEAG'+StatMMDD + '.' + RotLeag);
  assign (FileYTDs,'\'+RotLeag+'\'+'YTDSCURR.' + RotLeag);
  assign (FileCWKs,'\'+RotLeag+'\'+'CWKSCURR.' + RotLeag);
  end; {if Mode in WhatifModes}

reset (FileRost);
reset (FileLeag);
rewrite (FileCWKs);
rewrite (FileHold);
rewrite (FileInfo);
rewrite (FileFreC);
rewrite (FileFreY);
rewrite (FileWaiv);
rewrite (FileNeed);
rewrite (FileFABs);
rewrite (FilePos);
rewrite (FileYTDs);

while not (eof(FileLeag)) do begin
  NumOfTeams := NumOfTeams + 1;
  read (FileLeag,ATeam);
  TeamCurrArray[NumOfTeams]         := ATeam;
  TeamCurrArray[NumOfTeams].TeamNum := NumOfTeams;
  TeamPrevArray[NumOfTeams]         := ATeam;
  TeamPrevArray[NumOfTeams].TeamNum := NumOfTeams;
  end; {while not at eof (FileLeag)}

CntTeamPlyrs          := 0;
OffsetResPit          := 0;
OffsetResHit          := 0;
TeamExtra.PlayerExtra := 0;
TeamExtra.SalaryExtra := 0.0;
LeagExtraPlayer       := 0;
LeagExtraSalary       := 0.0;

while not (eof(FileRost)) do begin

  CurrPlayerKey := -1;
  with AMember do begin
    Stats.Name := ' ';
    Stats.ID   := Zero_ID;
    Salary     := 0;
    Contract   := '  ';
    RostPos    := ' ';
    PosList    := ' ';
    Stats.YTD  := ZeroRec;
    Stats.CWK  := ZeroRec;
    end; {with AMember}

  readln (FileRost,Line80);
{  writeln ('==>',Line80:55);  }

  RecType := copy (Line80,1,1);
  if not (RecType in RecTypeSet) then
    writeln ('not in RecTypeSet = ',RecType);

  case RecType of
    '*' : begin
          ATeam.Abbr := copy (Line80,2,4);
          if (CntTeamPlyrs > 0) or (OffsetResPit > 0) or (OffsetResHit > 0)
            then begin
            PrintTeamTotals (TeamNum);
            PutTeamOnList (TeamNum,TeamCurrArray);
            if not (Mode in QuickModes) then readln (Cont);
            end; {if CntTeamPlyrs > 0}

          LeagExtraPlayer       := LeagExtraPlayer + TeamExtra.PlayerExtra;
          LeagExtraSalary       := LeagExtraSalary + TeamExtra.SalaryExtra;
          TeamExtra.PlayerExtra := 0;
          TeamExtra.SalaryExtra := 0.0;
          TeamAbbr              := ATeam.Abbr;
          end; {'*'}
    '%' : begin
          with TeamExtra do begin
            Owner  := copy (Line80,2,16);
            PhoneH := copy (Line80,21,12);
            PhoneW := copy (Line80,34,12);
            Mgr    := copy (Line80,47,34);
            InitTeam;
            end; {with TeamExtra}
          end; {'%'}
    '@' : begin
          with TeamExtra do begin
            Email  := copy (Line80,2,80);
            StartTeam;
            end; {with TeamExtra}
          end; {'@'}
    '=' : begin
          AsterTrade := copy (Line80,2,24);
          end; {'='}
    '+','?','-','!','&','~' : begin
          if not ParseRostLine (Line80,AMember) then begin
            writeln ('no parse: ',Line80:55);
            writeln (FileErr,'no parse: ',Line80:55);
            end {if not ParseRostLine}
          else begin
            Active := (RecType = '+')  or (RecType = '?');

            J := GetPlayerKey (AMember.Stats.ID);

            if J >= 0 then begin
              seek (FilePly,J);
              read (FilePly,AMember.Stats);
              DeletePlayer (J);
            end; {if J >= 0}
            AMember.Stats.Status := RecType;

            if RecType = '&' then begin
              if AMember.Stats.PrimePos = 'P ' then AMember.RostPos := 'P'
              else AMember.RostPos := 'H';
              ArrayMinors [OffsetMinors] := AMember;
              OffsetMinors := OffsetMinors + 1;
            end {if RecType = '&'}
            else if RecType = '~' then begin
              if AMember.Stats.PrimePos = 'P ' then AMember.RostPos := 'P'
              else AMember.RostPos := 'H';
              ShowStats (FileWaiv,AMember,'C');
            end {if RecType = '~'}
            else PutOnTeam (TeamNum,AMember);

            end; {else ParseRostLine}
          end; {'+','?','-','!','&','~'}
    '#' : begin
          AMember.Stats.Name := copy (Line80,2,16);
          ArrayPicks [OffsetPicks] := AMember;
          OffsetPicks := OffsetPicks + 1;
          end; {'#'}
    '$' : begin
          if (GetInt (Line80,26,2,Mantissa)) and (GetInt (Line80,29,2,Fraction))
            then FabRemaining := FabRemaining - (Mantissa + (Fraction / 100));
          end; {'$'}
    else  begin
          if RecType <> '/' then begin
            writeln ('invalid RecType = ',RecType);
            writeln (FileErr,'invalid RecType = ',RecType);
            end;
          end; {else}
    end; {case of RecType}

{
  with AMember do begin
    writeln ('member = ',Stats.Name,' ',Stats.ID,' ',Salary:5:2,' ',Contract,
             ' ',Stats.Status,' ',RostPos,' ',PosList);
    readln;
    end;
}

  end; {while not at eof (FileRost)}

PrintTeamTotals (TeamNum);
PutTeamOnList (TeamNum,TeamCurrArray);

close (FileRost);
close (FileLeag);
close (FileWaiv);
close (FileNeed);
close (FileFABs);

if Mode = 'L' then readln;

{---generate YTD standings---}
CalcPointTotals (TeamCurrArray);

PrintStds (CON);
PrintStds (FileYTDs);

{---Financial info page headers---}
PageNum := 1;   {was 2 until 20090820}
{
writeln (RptDate,' ',RptTime:8,' ':9,RotLeag,
         ' Financial and Budget Information','Page: ':15,PageNum);
writeln (FileYTDs,^L,RptDate,' ',RptTime:8,' ':9,RotLeag,
         ' Financial and Budget Information','Page: ':15,PageNum);
}

{---Kept players info---}
writeln (FileYTDs,^L);
writeln (FileYTDs);

writeln ('Total # of players kept = ',CntLeagPlyrs);
writeln ('Total $ of players kept = ',PriceLeag:6:2);
writeln (FileYTDs,'Total # of players kept = ',CntLeagPlyrs);
writeln (FileYTDs,'Total $ of players kept = ',PriceLeag:6:2);

writeln;
writeln (FileYTDs);

writeln ('# of Pending (!) players = ',LeagExtraPlayer);
writeln ('$ of Pending (!) players = ',LeagExtraSalary:6:2);
writeln (FileYTDs,'# of Pending (!) players = ',LeagExtraPlayer);
writeln (FileYTDs,'$ of Pending (!) players = ',LeagExtraSalary:6:2);

{---Needed players info---}
if CntLeagPlyrs <> (NumOfTeams * NumOfPlayers) then begin
  LeagExtraPlayer := (NumOfTeams * NumOfPlayers)
                     - CntLeagPlyrs - LeagExtraPlayer;
  LeagExtraSalary := (NumOfTeams * TeamBudget)
                     - PriceLeag - LeagExtraSalary;
  CntLeagPlyrs := (NumOfTeams * NumOfPlayers) - CntLeagPlyrs;
  PriceLeag    := (NumOfTeams * TeamBudget) - PriceLeag;

  writeln;
  writeln (FileYTDs);
  writeln (FileYTDs);

  writeln ('# of players still needed = ',CntLeagPlyrs);
  writeln ('$ of players still needed = ',PriceLeag:6:2);
  writeln (FileYTDs,'# of players still needed = ',CntLeagPlyrs);
  writeln (FileYTDs,'$ of players still needed = ',PriceLeag:6:2);

  PriceLeag := PriceLeag / CntLeagPlyrs;
  writeln ('Average price per player still needed = ',PriceLeag:6:2);
  writeln (FileYTDs,'Average price per player still needed = ',PriceLeag:6:2);

  end; {if CntLeagPlyrs <> (NumOfTeams * NumOfPlayers)}

reset (FileWaiv);
writeln;
writeln(FileYTDS);
writeln(FileYTDS);
writeln ('   WAIVER PLAYERS FOR THIS WEEK');
writeln (FileYTDS,'   WAIVER PLAYERS FOR THIS WEEK');

while not(eof (FileWaiv)) do begin
  readln (FileWaiv,Line120);
  if Line120[2] = 'P' then begin
    writeln (Line120);
    writeln (FileYTDS,Line120);
    end; {if Line120[2] = 'P'}
  end; {while not at eof (FileWaiv)}

reset (FileWaiv);
while not(eof (FileWaiv)) do begin
  readln (FileWaiv,Line120);
  if Line120[2] <> 'P' then begin
    writeln (Line120);
    writeln (FileYTDS,Line120);
    end; {if Line120[2] <> 'P'}
  end; {while not at eof (FileWaiv)}

{---append team-by-team 'FAB Remaining' and 'Players Needed'---}
{---reads twice because the PrintTeamExtra routine is called twice above---}
{---(once for CON, once for YTDS) and duplicates are created---}
reset (FileFABs);
writeln (FileYTDs);
while not(eof (FileFABs)) do begin
  readln (FileFABs,Line120);
  readln (FileFABs,Line120);
  writeln (FileYTDs,Line120);
  end; {while not at eof (FileFABs)}

reset (FileNeed);
writeln (FileYTDs);
while not(eof (FileNeed)) do begin
  readln (FileNeed,Line120);
  readln (FileNeed,Line120);
  writeln (FileYTDs,Line120);
  end; {while not at eof (FileNeed)}

{---append team-by-team stats---}
reset (FileHold);
while not(eof (FileHold)) do begin
  readln (FileHold,Line120);
  writeln (FileYTDs,Line120);
  end; {while not at eof (FileHold)}

close (FileYTDs);

{---delete YTD lists---}
DeleteList (StartWinList);
DeleteList (StartSVList);
DeleteList (StartERAList);
DeleteList (StartPKList);
DeleteList (StartWHIPList);
DeleteList (StartHRList);
DeleteList (StartRBIList);
DeleteList (StartRSList);
DeleteList (StartSBList);
DeleteList (StartAveList);
DeleteList (StartTPtsList);
DeleteList (StartPPtsList);
DeleteList (StartHPtsList);
DeleteList (StartTieList);

{---produce CWK lists---}
for I := 1 to NumOfTeams do PutTeamOnList (I,TeamPrevArray);

{---generate CWK standings---}
CalcPointTotals (TeamPrevArray);

PrintStds (CON);
PrintStds (FileCWKs);

{---append team-by-team stats---}
reset (FileFreC);
while not(eof (FileFreC)) do begin
  readln (FileFreC,Line120);
  writeln (FileCWKs,Line120);
  end; {while not at eof (FileFreC)}

close (FileCWKs);

{---write this week's LEAG file totals---}
if not (Mode in WhatifModes) then begin
  assign (FileLeag,'\'+RotLeag+'\'+'LEAG'+StatMMDD + '.' + RotLeag);
  rewrite (FileLeag);
  for I := 1 to NumOfTeams do begin
    seek (FileLeag,FileSize(FileLeag));
    write (FileLeag,TeamCurrArray [I]);
    end; {for each team}
  close (FileLeag);
  end; {if not (Mode in WhatifModes) then begin}

{for each group - FABs, WAIVERs, FREE AGENTs, write pitchers to FileFreC and
hitters to FileHold, then append FileHold to FileFrec.}

{---write this week's FABS---}
rewrite (FileFreC);
rewrite (FileHold);

writeln (FileFreC,^L,'     FAB PITCHER STATS FOR THIS WEEK');
writeln (FileFreC);

writeln (FileHold);
writeln (FileHold,'     FAB HITTER STATS FOR THIS WEEK');

assign (FileNew,'\PLY'+'\'+'NEW'+StatMMDD+'.'+ML);
reset (FileNew);
while not eof (FileNew) do begin
  readln (FileNew,AMember.Stats.Name,AMember.Stats.ID);
  CurrPlayerKey := GetPlayerKey (AMember.Stats.ID);
  if CurrPlayerKey >= 0 then begin
    seek (FilePly,CurrPlayerKey);
    read (FilePly,WrkPlayer);
    AMember.Stats    := WrkPlayer;
    AMember.RostPos  := 'H';
    AMember.Contract := '  ';
    AMember.Salary   := 0;
    AMember.PosList  := ' ';
    if WrkPlayer.PrimePos = 'P ' then begin
      AMember.RostPos  := 'P';
      ShowStats (FileFreC,AMember,'C')
    end {if WrkPlayer.PrimePos = 'P ' then begin}
    else
      ShowStats (FileHold,AMember,'C');
    DeletePlayer (CurrPlayerKey);
    end; {if CurrPlayerKey >= 0}
  end; {while not eof FileNew}

reset (FileHold);
while not(eof (FileHold)) do begin
  readln (FileHold,Line120);
  writeln (FileFreC,Line120);
  end; {while not at eof (FileHold)}

{---write this week's WAIVERS---}
reset (FileWaiv);
rewrite (FileHold);

writeln (FileFreC);
writeln (FileFreC);
writeln (FileFreC);
writeln (FileFreC,'   WAIVER PITCHER STATS FOR THIS WEEK');

writeln (FileHold);
writeln (FileHold,'   WAIVER HITTER STATS FOR THIS WEEK');

while not(eof (FileWaiv)) do begin
  readln (FileWaiv,Line120);
  if Line120[2] = 'P' then writeln (FileFreC,Line120)
  else writeln (FileHold,Line120);
  end; {while not at eof (FileWaiv)}

reset (FileHold);
while not(eof (FileHold)) do begin
  readln (FileHold,Line120);
  writeln (FileFreC,Line120);
  end; {while not at eof (FileHold)}

{---write this week's FREE AGENTS current week's stats---}
rewrite (FileHold);
writeln (FileFreC,^L,'     FREE-AGENT PITCHER STATS FOR THIS WEEK');
writeln (FileHold,^L,'     FREE-AGENT HITTER STATS FOR THIS WEEK');

AMember.Salary := 1;
for CurrPlayerKey := 0 to (CntKeys - 1) do
  if ArrayKeys [CurrPlayerKey] >= Zero_ID then begin
    seek (FilePly,CurrPlayerKey);
    read (FilePly,WrkPlayer);
    AMember.Stats    := WrkPlayer;
    AMember.RostPos  := 'H';
    AMember.PosList  := ' ';
    AMember.Contract := '  ';

    if (WrkPlayer.PrimePos = 'P ') then begin
      AMember.RostPos  := 'P';
      ShowStats (FileFreC,AMember,'C')
    end {if (WrkPlayer.PrimePos = 'P ') then begin}
    else {Hitter}
      ShowStats (FileHold,AMember,'C');
    end; {if WrkPlayer.PrimePos = 'P'}

reset (FileHold);
while not(eof (FileHold)) do begin
  readln (FileHold,Line120);
  writeln (FileFreC,Line120);
  end; {while not at eof (FileHold)}

{---write this week's FREE AGENTS year-to-date stats---}
rewrite (FileHold);
writeln (FileFreY,^L,'     FREE-AGENT PITCHER STATS FOR YEAR-TO-DATE');
writeln (FileHold,^L,'     FREE-AGENT HITTER STATS FOR YEAR-TO-DATE');

for CurrPlayerKey := 0 to (CntKeys - 1) do begin
  if ArrayKeys [CurrPlayerKey] >= Zero_ID then begin
    seek (FilePly,CurrPlayerKey);
    read (FilePly,WrkPlayer);
    AMember.Stats    := WrkPlayer;
    AMember.RostPos  := 'H';
    AMember.PosList  := ' ';
    AMember.Contract := '  ';

    if (WrkPlayer.PrimePos = 'P ') then begin
      AMember.RostPos  := 'P';
      ShowStats (FileFreY,AMember,'Y')
    end {if (WrkPlayer.PrimePos = 'P ') then begin}
    else
      ShowStats (FileHold,AMember,'Y');
  end; {if WrkPlayer.PrimePos = 'P'}
end; {for CurrPlayerKey := 0 to (CntKeys - 1) do begin}

reset (FileHold);
while not(eof (FileHold)) do begin
  readln (FileHold,Line120);
  writeln (FileFreY,Line120);
  end; {while not at eof (FileHold)}

close (FileFreC);
close (FileFreY);
close (FileHold);
close (FileInfo);
close (FilePly);
close (FileWaiv);
close (FileNeed);
close (FileFABs);
close (FilePos);

erase (FileHold);
erase (FileWaiv);
erase (FileNeed);
erase (FileFABs);

ShutDown;
clrscr;

reset (FileErr);
writeln;
while not(eof (FileErr)) do begin
  readln (FileErr,Line120);
  writeln (Line120);
  end; {while not at eof (FileErr)}

writeln ('ML/Date/League/Mode: ',ML,' ',StatMMDD,' ',RotLeag,' ',Mode);

{ writeln (^G)};

end. {Calc5}
program MakePlyr;
{This program is used to initialize the PLY files.  It assumes that the player
data read in from CSW is in alphabetical order.
      get league and date;
      read stats file;
        validate data and convert to PLY format;
      list error file.}

{$I DCLSTATS.PAS }
{$I GETSETUP.PAS }

var
   APlayer           : Player;
   Cont              : char;
   CurrDate          : Str4;
   CurrPtr           : ListPtr;
   PlyFile           : file of Player;
   Err               : boolean;
   ErrFile           : text;
   Fraction          : integer;
   Line              : Str80;
   Mantissa          : integer;
   ML                : char;
   NewFile           : text;
   PrevDate          : Str4;
   StartPtr          : ListPtr;
   CSWFile           : text;
   WrkFile           : file of Player;
   WrkPlayer         : Player;


{========================= GetInt =========================
returns true if it can parse AStr at Start for Len into an integer}

function GetInt (AStr:Str80;Start,Len:integer;var AnInt:integer):boolean;

var
  Err : integer;

begin
val (copy(AStr,Start,Len),AnInt,Err);
if Err <> 0 then begin
  writeln (ErrFile,'invalid digit @ ',AStr[Start+Err-1]);
  GetInt := false
  end
else GetInt := true;
end; {GetInt:boolean}


{========================= ValidPos =========================
returns 'A' (for AL) if DH, 'N' (for NL) for other valid positions,
' ' for not found.}

function ValidPos (APos:Str2):char;

var
  I : integer;

begin
ValidPos := ' ';
if APos = PosAbbrs[1] then ValidPos := 'A';
for I := 1 to NumOfPos do if APos = PosAbbrs[I] then ValidPos := 'N';
end; {ValidPos:char}


{========================= ValidTeam =========================
returns 'A' (for AL), 'N' (for NL), ' ' for not found.}

function ValidTeam (ATeam:Str3):char;

var
  I : integer;

begin
ValidTeam := ' ';
for I := 1 to NumOfAL do if ATeam = ALAbbrs[I] then ValidTeam := 'A';
for I := 1 to NumOfNL do if ATeam = NLAbbrs[I] then ValidTeam := 'N';
end; {ValidTeam:char}



{========================= GetCommonStats =========================
Parses global APlayer into common stats.}

procedure GetCommonStats;

var
  I : integer;

begin

{map to upper case}
for I := 1 to 80 do
  Line[I] := UpCase (Line[I]);

{replace numeric blanks w/ zeroes}
for I := 21 to 24 do if Line[I] = ' ' then Line[I] := '0';
for I := 34 to 80 do if Line[I] = ' ' then Line[I] := '0';

with APlayer do begin


  Name     := copy (Line,2,18);
  if not ( GetInt (Line,21,4,ID)) then Err := true;

  MLTeam   := copy (Line,26,3) + ' ';
  PrimePos := copy (Line,30,2);
  MLStatus := copy (Line,1,1) + ' ';

  if ValidTeam (MLTeam) = ' ' then begin
    writeln (ErrFile,'invalid team ',MLTeam);
    Err := true
    end;

  if ValidPos (PrimePos) = ' ' then begin
    writeln (ErrFile,'invalid position ',PrimePos);
    Err := true
    end;

  end; {with APlayer}
end; {GetCommonStats}

{========================= GetHitterStats =========================
Parses global APlayer into hitter-specific stats.}

procedure GetHitterStats;

begin

if (Line[39] <> '.') then begin
  writeln (ErrFile,'bad decimal in BA ',Line[39]);
  Err := true
  end;

if (Line[70] <> '.') then begin
  writeln (ErrFile,'bad decimal in OB ',Line[70]);
  Err := true
  end;

with APlayer do begin
  Bats := copy (Line,33,1) + ' ';
  if not ((Bats = 'L ') or (Bats = 'R ')
  or (Bats = 'S ') or (Bats = 'X ')) then begin
    writeln (ErrFile,'invalid bats ',Bats);
    Err := true
    end;

  {parse integers}

  if not ( GetInt (Line,35,3,G))
    or not ( GetInt (Line,43,3,AB))
    or not ( GetInt (Line,46,3,H))
    or not ( GetInt (Line,49,2,D))
    or not ( GetInt (Line,51,2,T))
    or not ( GetInt (Line,53,2,HR))
    or not ( GetInt (Line,55,3,RBI))
    or not ( GetInt (Line,58,3,RS))
    or not ( GetInt (Line,61,3,SB))
    or not ( GetInt (Line,64,2,CS))
    or not ( GetInt (Line,66,3,BB))
    or not ( GetInt (Line,74,3,K))
    or not ( GetInt (Line,77,2,E)) then Err := true;

  {parse reals}
  if GetInt(Line,38,1,Mantissa) and GetInt(Line,40,3,Fraction)
    then BA := Mantissa + Fraction/1000
  else Err := true;

  if GetInt(Line,69,1,Mantissa) and GetInt(Line,71,3,Fraction)
    then OB := Mantissa + Fraction/1000
  else Err := true;

  DifAB := AB;
  DifCS := CS;
  DifD  := D;
  DifHR := HR;
  DifRBI:= RBI;
  DifSB := SB;
  DifT  := T;

  end; {with APlayer}
end; {GetHitterStats:boolean}


{========================= GetPitcherStats =========================
Parses global APlayer into pitcher-specific stats.}

procedure GetPitcherStats;

begin

if (Line[36] <> '.') then begin
  writeln (ErrFile,'bad decimal in ERA ',Line[36]);
  Err := true
  end;

if (Line[46] <> '.') then begin
  writeln (ErrFile,'bad decimal in IP ',Line[46]);
  Err := true
  end;

with APlayer do begin
  Throws := copy (Line,32,1) + ' ';
  if not ((Throws = 'L ') or (Throws = 'R ')
  or (Throws = 'S ') or (Throws = 'X ')) then begin
    writeln (ErrFile,'invalid throws ',Throws);
    Err := true
    end;

  {parse integers}

  if not ( GetInt (Line,39,2,G))
  or not ( GetInt (Line,41,2,GS))
  or not ( GetInt (Line,48,3,K))
  or not ( GetInt (Line,51,3,BB))
  or not ( GetInt (Line,54,3,H))
  or not ( GetInt (Line,57,3,RS))
  or not ( GetInt (Line,60,3,ER))
  or not ( GetInt (Line,63,2,W))
  or not ( GetInt (Line,65,2,L))
  or not ( GetInt (Line,67,2,SV))
  or not ( GetInt (Line,69,2,QS))
  or not ( GetInt (Line,71,2,CG))
  or not ( GetInt (Line,73,2,SH))
  or not ( GetInt (Line,75,2,E)) then Err := true;

  {parse reals}
  if GetInt(Line,34,2,Mantissa) and GetInt(Line,37,2,Fraction)
    then ERA := Mantissa + Fraction/100
  else Err := true;

  if GetInt(Line,43,3,Mantissa) and GetInt(Line,47,1,Fraction)
    then IP := Mantissa + Fraction/3
  else Err := true;

  DifGS := GS;
  DifER := ER;
  DifW  := W;
  DifL  := L;
  DifSV := SV;
  DifQS := QS;
  DifCG := CG;
  DifSH := SH;
  DifIP := IP;

  end; {with APlayer}
end; {GetPitcherStats:boolean}


{========================= ImportStats =========================
reads thru the CSW stats, converts the data, adds the player.}

procedure ImportStats;

begin

assign (CSWFile,'\CSW\CSW'+ML+CurrDate);   {this week's stats from CSW}
reset (CSWFile);

assign (PlyFile,'\PLY\PLY'+ML+CurrDate);   {this week's player stats}
rewrite (PlyFile);

while not (eof(CSWFile)) do begin
  readln (CSWFile,Line);
  Err := false;

  GetCommonStats;
  if not (Err) then
    with APlayer do begin
      if (PrimePos = 'S ') or (PrimePos = 'R ') then GetPitcherStats
      else GetHitterStats;
      DifBB := BB;
      DifE  := E;
      DifG  := G;
      DifH  := H;
      DifK  := K;
      DifRS := RS;
      end; {with APlayer do}

  if Err then begin
    writeln (ErrFile,'error(s) found on line:');
    writeln (ErrFile,Line);
    writeln (ErrFile,' ');
    end
  else begin
    write (PlyFile,APlayer);
    end; {else no Err}

  end;

close (CSWFile);
close (PlyFile);

end; {ImportStats}


{========================= M A I N =========================
import and validate weekly stats.}

begin {Main Program}

writeln ('beginning of program');

GetSetup (ML,CurrDate,PrevDate);

assign (ErrFile,'ERR'+ML+CurrDate);     {errors found during data import}
rewrite (ErrFile);

ImportStats;

reset (ErrFile);
while not (eof(ErrFile)) do begin
  readln (ErrFile,Line);
  writeln (Line)
  end;
close (ErrFile);

writeln; writeln ('end of program.')

end. {MakePlyr}
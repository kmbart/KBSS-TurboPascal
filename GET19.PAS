program Get19;
{Import raw stats from Rotowire (Stats, Inc. feed)}

{
Get league and date;
read RW report line;
  filter out non-stat lines;
  validate data;
  print exceptions on screen;
}

{$I DCLSTATS.PAS }

const
  PgmName  : Str4 = 'GET19';

{$I UTILSUBS.PAS }

var
   APlayer           : Player;
   ArrayPrevID       : array [0..1499] of Str8;
   ArrayStatFields   : array [0..25] of Str18;
   AService          : StatFeedRec;
   AStr              : Str80;
   Cont              : char;
   CntCurrPlayers    : integer;
   CntPrevPlayers    : integer;
   CurrPtr           : ListPtr;
   Err               : boolean;
   FileCurr          : file of Player;
   FileT             : text;
   FileJunk          : text;
   FileNew           : text;
   FilePrev          : file of Player;
   Fraction          : integer;
   I                 : integer;
   Initing           : boolean;
   Line              : Str160;
   LineLen           : integer;
   LinePtr           : integer;
   Mantissa          : integer;
   ML                : char;
   StartIDPtr        : ListPtr;
   StartNamePtr      : ListPtr;
   WrkPlayer         : Player;



{============================================================================}
{                           G E T S T R V A R                                }
{============================================================================}
{
get a string with variable length (between spaces).
}

function GetStrVar (AStr:Str160;var APtr:integer;var XStr:Str8):boolean;

var
  I,J  : integer;

begin

{
write ('AStr=',AStr:25);
write (' ,APtr=',APtr);
readln;
}

while (AStr [APtr] =  ' ') and (APtr <= LineLen) do APtr := APtr + 1;
I := APtr;

while (AStr [APtr] <> ' ') and (APtr <= LineLen) do APtr := APtr + 1;

if (AStr [APtr] = ' ') or (APtr > LineLen) then J := APtr - I else J := 0;

{ APtr := APtr + 1; }

while (AStr [APtr] = ' ') and (APtr <= LineLen) do APtr := APtr + 1;

{
write (' ,APtr=',APtr);
write (' ,I=',I);
write (' ,J=',J);
readln;
}

XStr := '';
if J > 0 then XStr := copy (AStr,I,J);

GetStrVar := not (XStr = '');

end; {function GetStrVar:boolean}



{============================================================================}
{                           G E T R E A L V A R                              }
{============================================================================}
{
break a string of digits into mantissa and decimal substrings.
}

function GetRealVar (AStr:Str8;var AMan:Str8;var ADec:Str8):boolean;

var
  I,J : integer;

begin

I := 1;
while (AStr [I] <> '.') and (I < 9) do I := I + 1;

AMan := copy (AStr,1,I - 1);

ADec := '00000000';
if AStr [I] = '.' then begin
  I := I + 1;
  J := 8;
  while AStr[J] = ' ' do J := J - 1;
  if J < I then J := 0;
  if J > 3 then J := 3;
  ADec := copy (AStr,I,J);
end; {if AStr [I] = '.'}

GetRealVar := not ( (AMan = '') and (ADec = '') );

end; {GetRealVar:boolean}


{============================================================================}
{                           V A L I D   T E A M                              }
{============================================================================}
{
returns 'A' (for AL), 'N' (for NL), ' ' for not found.
}

function ValidTeam (ATeam:Str3):char;

var
  I : integer;

begin

for I := 1 to 3 do ATeam[I] := upcase(ATeam[I]);

ValidTeam := ' ';

for I := 1 to NumOfAL do if ATeam = AService.AbbrsAL[I] then ValidTeam := 'A';
for I := 1 to NumOfNL do if ATeam = AService.AbbrsNL[I] then ValidTeam := 'N';

end; {ValidTeam:char}



{============================================================================}
{                         L O A D   P L A Y E R                              }
{============================================================================}
{
if P not in FilePrev then P.New := TRUE
else begin
  P.New := FALSE;
  calc weekly difs for each category;
}

procedure LoadPlayer (var P:Player);

var
  I     : integer;
  PrevP : Player;

begin

I := 0;
P.New := TRUE;

while (I < CntPrevPlayers) and (P.New) do
  if P.ID = ArrayPrevID [I] then begin
    P.New := FALSE;
    seek (FilePrev,I);
    read (FilePrev,PrevP);
    end {if P.ID = ArrayPrevID [I]}
  else I := I + 1;

if P.New then P.CWK := P.YTD

else
  with PrevP.YTD do begin
    P.CWK.BB := P.YTD.BB - BB;
    P.CWK.D  := P.YTD.D  - D;
    P.CWK.G  := P.YTD.G  - G;
    P.CWK.H  := P.YTD.H  - H;
    P.CWK.HP := P.YTD.HP - HP;
    P.CWK.HR := P.YTD.HR - HR;
    P.CWK.K  := P.YTD.K  - K;
    P.CWK.R  := P.YTD.R  - R;
    P.CWK.T  := P.YTD.T  - T;

   if P.PrimePos = 'P ' then begin
      P.CWK.BS := P.YTD.BS - BS;
      P.CWK.ER := P.YTD.ER - ER;
      P.CWK.GF := P.YTD.GF - GF;
      P.CWK.GS := P.YTD.GS - GS;
      P.CWK.L  := P.YTD.L  - L;
      P.CWK.SV := P.YTD.SV - SV;
      P.CWK.W  := P.YTD.W  - W;
      P.CWK.IP := P.YTD.IP - IP;
      end {if P.PrimePos = 'P '}

    else begin
      P.CWK.AB  := P.YTD.AB  - AB;
      P.CWK.CS  := P.YTD.CS  - CS;
      P.CWK.E   := P.YTD.E   - E;
      P.CWK.HR  := P.YTD.HR  - HR;
      P.CWK.G_C := P.YTD.G_C - G_C;
      P.CWK.G_D := P.YTD.G_D - G_D;
      P.CWK.G_O := P.YTD.G_O - G_O;
      P.CWK.G_S := P.YTD.G_S - G_S;
      P.CWK.G_1 := P.YTD.G_1 - G_1;
      P.CWK.G_2 := P.YTD.G_2 - G_2;
      P.CWK.G_3 := P.YTD.G_3 - G_3;
      P.CWK.RBI := P.YTD.RBI - RBI;
      P.CWK.SB  := P.YTD.SB  - SB;
      end; {if P.PrimePos <> 'P '}

    end; {with PrevP.YTD do}

I := FileSize (FileCurr);
seek (FileCurr,I);
write (FileCurr,P);

CntCurrPlayers := I;

end; {LoadPlayer}



{============================================================================}
{                           F I L T E R   L I N E                            }
{============================================================================}
{
parse comma-delimited Line into separate fields in array
determine if Line is garbage, free-agent or rostered, pitcher or hitter.
}

procedure FilterLine (var RecType:StatLineType);

var
  F      : Str18;
  I,J,K  : integer;

begin

F := ' ';
for I := 1 to 25 do ArrayStatFields[I] := F;

I := 1;
J := 1;
K := 1;

while I < LineLen do begin
  if Line[I] <> ',' then begin
    F[J] := Line[I];
    J := J + 1;
  end {if Line[I] <> ','}

  else begin
    F[0] := char(J - 1);
    ArrayStatFields[K] := F;
    F[0] := char(0);
    K := K + 1;
    J := 1;
  end; {else not Line[I] <> ','}

  I := I + 1;
end; {while I <= LineLen do}

F[0] := char(J - 1);
ArrayStatFields[K] := F;

{
writeln ('LineLen=',LineLen,' ,K=',K,' ,J=',J,' ,F=',F,'*');
for I := 1 to K do write ('[',I,']=',ArrayStatFields[I],',');
readln;
}

F := ArrayStatFields [3];
if not (F[1] in ['0'..'9']) then RecType := G
else begin
  F := ArrayStatFields [18];
  if F = ' ' then RecType := P else RecType := H;
end; {else (F[1] in ['0'..'9'])}

{
if RecType = G then write ('RecType=G');
if RecType = H then write ('RecType=H');
if RecType = P then write ('RecType=P');
readln;
}

end; {FilterLine}



{============================================================================}
{                      G E T   C O M M O N   S T A T S                       }
{============================================================================}
{
Load first name, last name, player ID, team from ArrayStatFields.
}

procedure GetCommonStats (var APlayer:Player);

var
  F           : Str18;
  I,J         : integer;

begin

with APlayer do begin

  {get name - from first + last to last + comma + first}
  for I := 1 to 18 do Name[I] := ' ';

  F := ArrayStatFields[2];
  I := ord(F[0]);
  Name := copy (F,1,I) + ',';

  F := ArrayStatFields[1];
  J := ord(F[0]);
  if (I + J) > 17 then J := 17 - I;
  Name := Name + copy (F,1,J);
{  Name[0] := char (I + J + 1); }
  Name[0] := char (18);

{ write (Name,' ',PrimePos);readln; }

  {get ID}
  F := ArrayStatFields[3];
  J := ord(F[0]);
  ID := '00000000';
  for I := 1 to J do
    if F[I] in ['0'..'9'] then
      ID[8 - J + I] := F[I]
    else begin
      writeln ('bad ID:',F,'* @ pos=',I);
      Err := true;
    end; {else not F[I] in ['0'..'9']}

  ID[0] := char (8);

{ write ('ID=',ID);readln; }

  {get team abbr}
  F := ArrayStatFields[4];
  J := ord(F[0]);
  MLTeam := copy (F,1,3);
  if MLTeam = 'SAN' then begin
    MLTeam[2] := 'N';
    MLTeam[3] := F[4];
  end; {if MLTeam = 'SAN'}
  ML := ValidTeam (MLTeam);
  if ML = ' ' then begin
    writeln (FileErr,'invalid team ',MLTeam);
    Err := true;
  end; {if bad MLTeam}
  if ML <> 'N' then Err := true;

  {get games}
  F := ArrayStatFields[5];
  J := ord(F[0]);
  if not GetInt(F,1,8,YTD.G) then begin
    writeln ('bad games:',F);
    Err := true;
  end; {if not GetInt(F,1,8,YTD.G) then }

end; {with APlayer}

end; {GetCommonStats}




{============================================================================}
{                      G E T   H I T T E R   S T A T S                       }
{============================================================================}
{
Parses Line into hitter-specific stats.
}

procedure GetHitterStats (var APlayer:Player);

begin

Err := FALSE;

with APlayer.YTD do begin

  Err := Err or not GetInt(ArrayStatFields[06],1,8,AB);
  Err := Err or not GetInt(ArrayStatFields[07],1,8,R);
  Err := Err or not GetInt(ArrayStatFields[08],1,8,H);
  Err := Err or not GetInt(ArrayStatFields[09],1,8,D);
  Err := Err or not GetInt(ArrayStatFields[10],1,8,T);
  Err := Err or not GetInt(ArrayStatFields[11],1,8,HR);
  Err := Err or not GetInt(ArrayStatFields[12],1,8,RBI);
  Err := Err or not GetInt(ArrayStatFields[13],1,8,SB);
  Err := Err or not GetInt(ArrayStatFields[14],1,8,CS);
  Err := Err or not GetInt(ArrayStatFields[15],1,8,BB);
  Err := Err or not GetInt(ArrayStatFields[16],1,8,K);
  Err := Err or not GetInt(ArrayStatFields[17],1,8,E);
  Err := Err or not GetInt(ArrayStatFields[18],1,8,G_C);
  Err := Err or not GetInt(ArrayStatFields[19],1,8,G_1);
  Err := Err or not GetInt(ArrayStatFields[20],1,8,G_2);
  Err := Err or not GetInt(ArrayStatFields[21],1,8,G_3);
  Err := Err or not GetInt(ArrayStatFields[22],1,8,G_S);
  Err := Err or not GetInt(ArrayStatFields[23],1,8,G_O);
{ Err := Err or not GetInt(ArrayStatFields[??],1,8,G_D); }

  if Err then writeln ('bad HITTER # for ',APlayer.Name,'...',APlayer.ID);

end; {with APlayer.YTD do}

{
writeln ('Player:',APlayer.Name,' ,ID:',APlayer.ID);
writeln ('G =',APlayer.YTD.G);
writeln ('R =',APlayer.YTD.R);
writeln ('H =',APlayer.YTD.H);
writeln ('D =',APlayer.YTD.D);
writeln ('T =',APlayer.YTD.T);
writeln ('HR=',APlayer.YTD.HR);
writeln ('BB=',APlayer.YTD.BB);
writeln ('K =',APlayer.YTD.K);

with APlayer.YTD do begin
  writeln ('AB=',AB);
  writeln ('RBI=',RBI);
  writeln ('SB=',SB);
  writeln ('CS=',CS);
  writeln ('E=',E);
  writeln ('G_D=',G_D);
  writeln ('G_C=',G_C);
  writeln ('G_1=',G_1);
  writeln ('G_2=',G_2);
  writeln ('G_3=',G_3);
  writeln ('G_S=',G_S);
  writeln ('G_O=',G_O);
  readln;
end;
}

if Initing then APlayer.CWK := APlayer.YTD;

end; {GetHitterStats}



{============================================================================}
{                      G E T   P I T C H E R   S T A T S                     }
{============================================================================}
{
Parses Line into pitcher-specific stats.
}

procedure GetPitcherStats (var APlayer:Player);

var
  Frac, Mant  : Str8;

begin

Err := FALSE;

with APlayer.YTD do begin

  Err := Err or not GetInt(ArrayStatFields[06],1,8,W);
  Err := Err or not GetInt(ArrayStatFields[07],1,8,L);
  Err := Err or not GetInt(ArrayStatFields[08],1,8,SV);
  Err := Err or not GetInt(ArrayStatFields[09],1,8,BS);

  Err := not GetRealVar(ArrayStatFields[10],Mant,Frac);
  if GetInt(Mant,1,8,Mantissa) and GetInt(Frac,1,8,Fraction) then
    IP := Mantissa + Fraction / 1000
  else Err := TRUE;

  Err := Err or not GetInt(ArrayStatFields[11],1,8,H);
  Err := Err or not GetInt(ArrayStatFields[12],1,8,HR);
  Err := Err or not GetInt(ArrayStatFields[13],1,8,BB);
  Err := Err or not GetInt(ArrayStatFields[14],1,8,HP);
  Err := Err or not GetInt(ArrayStatFields[15],1,8,R);
  Err := Err or not GetInt(ArrayStatFields[16],1,8,ER);
  Err := Err or not GetInt(ArrayStatFields[17],1,8,K);

  if Err then writeln ('bad PITCHER # for ',APlayer.Name,'=',APlayer.ID);
  if Err then readln;

end; {with APlayer.YTD do}

{
writeln ('Name: ',APlayer.Name,' ,ID: ',APlayer.ID);
with APlayer.YTD do begin
  writeln ('W = ',APlayer.YTD.W);
  writeln ('L = ',APlayer.YTD.L);
  writeln ('SV= ',APlayer.YTD.SV);
  writeln ('BS= ',APlayer.YTD.BS);
  writeln ('IP= ',APlayer.YTD.IP);
  writeln ('HR= ',APlayer.YTD.HR);
  writeln ('BB= ',APlayer.YTD.BB);
  writeln ('HP= ',APlayer.YTD.HP);
  writeln ('R = ',APlayer.YTD.R);
  writeln ('ER= ',APlayer.YTD.ER);
  writeln ('K=',APlayer.YTD.K);
  readln;
end;
}

if Initing then APlayer.CWK := APlayer.YTD;

end; {GetPitcherStats}



{============================================================================}
{                      I M P O R T   S T A T S                               }
{============================================================================}
{
open RW file;
open CURR file;
read RW record;
  filter out non-player lines and determine record type (G, H, P);
  if player not in ArrayPrevIDs then mark as NEW;
  case of
    H(itter)  GetHitterStats
    P(itcher) GetPitcherStats
  if no error then UpdatePlayer;
}

procedure ImportStats;

var
   I       : integer;
   RecType : StatLineType;

begin

assign (FileCurr,'\PLY\PLY'+StatMMDD+'.'+ML); {current week's stats}
rewrite (FileCurr);

assign (FileJunk,'\RW\JUNK'+StatMMDD+'.'+ML);
rewrite (FileJunk);

while not (eof(FileT)) do begin
  LineLen := 160;
  for I := 1 to LineLen do Line [I] := ' ';
  readln (FileT,Line);
  while Line [LineLen - 1] = ' ' do LineLen := LineLen - 1;

  Err := Err or false;

  FilterLine (RecType);

  if RecType = G then writeln (FileJunk,Line)

  else begin

    APlayer.PrimePos := 'H ';
    if RecType = P then APlayer.PrimePos := 'P ';

    APlayer.YTD := ZeroRec;

    GetCommonStats (APlayer);

    case RecType of
      H : GetHitterStats (APlayer);
      P : GetPitcherStats (APlayer);
    end; {case RecType of}

    if Cont = 'Y' then with APlayer do begin
      writeln ('Name: ',Name);
      writeln ('Team: ',MLTeam);
      writeln ('ID #:',ID);
      with YTD do
        if PrimePos = 'P ' then begin
          writeln ('IP  :',IP);
          writeln ('WINS:',W);
          writeln ('SVS :',SV);
          writeln ('ER  :',ER);
          end {if PrimePos = 'P '}
        else begin
          writeln ('ABS :',AB);
          writeln ('RBI :',RBI);
          writeln ('SB  :',SB);
        end; {else PrimePos <> 'P '}
      write ('Continue: '); readln (Cont);
      Cont := upcase (Cont);
      writeln;
    end; {if Cont = 'Y'}

    if Err then begin
      write (FileErr,'ERR: ');
      for I := 1 to 160 do write (FileErr,Line[I]);
      writeln (FileErr);
    end {if Err}
    else begin
{  write (APlayer.Name,APlayer.ID,' ,err=',Err); readln; }
      LoadPlayer (APlayer);
      if APlayer.New then writeln (FileNew,APlayer.Name,APlayer.ID);

    end; {else not Err}
  end; {else not PrimePos = 'G '}
end; {while not eof(FileT)}

close (FileT);
close (FileCurr);
close (FileJunk);

end; {ImportStats}


{============================================================================}
{                                 M A I N                                    }
{============================================================================}
{
get current date and time;
open error file;
get setup info;
read in previous week's player data and make index;
read in current week's player data, parse and validate;
copy errors to log file;
write summary info to log file;
close log file;
}

{***************************************************************************}
begin {Main Program}

repeat
  GetLeagDate (ML,StatMMDD,PrevMMDD);

  assign (FileT,'\RW\RW19'+StatMMDD+'.TXT'); {this week's rpt from RW}
  {$I-} reset (FileT) {$I+} ;
  if (IOResult <> 0) then begin
    writeln;
    writeln;
    write ('RW19',StatMMDD,'.TXT - file not found');
    readln;
    Err := TRUE;
    end {if (IOResult <> 0)}

  else begin
    assign (FilePrev,'\PLY\PLY'+PrevMMDD+'.'+ML);
    {$I-} reset (FilePrev) {$I+} ;
    if (IOResult = 0) then begin
      Err := FALSE;
      Initing := FALSE;
      end {if (IOResult = 0)}
    else begin
      Cont := 'Y';
      writeln;
      write ('Is this an initialization (Y/N)? ');
      readln (Cont);
      if upcase (Cont) = 'Y' then begin
        Err     := FALSE;
        Initing := TRUE;
        end {if upcase (Cont) = 'Y'}
      else if upcase (Cont) = 'N' then begin
        Err     := FALSE;
        Initing := FALSE;
        end
      else begin
        Err := TRUE;
        write('You must enter Y or N');
        readln;
        end;
      end; {else IOResult <> 0 for PrevMMDD}
    end; {else IOResult = 0 for StatMMDD}
  until not Err;

writeln;
writeln;

AService := RW;

StartUp ('RW');

I := 0;
if not Initing then begin
  while not (eof(FilePrev)) do begin
    read (FilePrev,APlayer);
    ArrayPrevID [I] := APlayer.ID;
    I := I + 1;
    end; {while not eof FilePrev}
  end; {if not Initing}

CntPrevPlayers := I;

assign (FileNew,'\PLY\NEW'+StatMMDD+'.'+ML);
rewrite (FileNew);

ImportStats;

CntCurrPlayers := CntCurrPlayers + 1;

writeln;
writeln ('# of previous week players = ',CntPrevPlayers);
writeln ('# of current weeks players = ',CntCurrPlayers);
writeln (FileErr,'# of previous week players = ',CntPrevPlayers);
writeln (FileErr,'# of current weeks players = ',CntCurrPlayers);
writeln;

if not Initing then begin
  reset (FileNew);
  while not eof(FileNew) do begin
    readln (FileNew,Line);
    writeln (FileErr,Line);
    end; {while not eof FileNew}
  end; {if not Initing}
close (FileNew);

{
reset (FileJunk);
while not eof(FileJunk) do begin
  readln (FileJunk,Line);
  writeln (Line);
  end;
close (FileJunk);
}

ShutDown;

end. {Get19}
{-------------------------------------------------------------------------}
{                          U T I L S U B S                                }
{-------------------------------------------------------------------------}
{
GetCurrDate = returns current date as YY/MM/DD
GetCurrTime = returns current time as HH:MM:SS
StartUp     = creates ZERO_REC and opens error file with start-up info
ShutDown    = closes error file with shut-down info
GetInt      = parses a string for an integer starting at Start for Len;
GetPrevMMDD = find the previous MM and DD given a current MM and DD
GetLeagDate = prompt and validate ML, MM and DD
}
{-------------------------------------------------------------------------}
procedure GetCurrDate (var D:Str8);
{-------------------------------------------------------------------------}

var
   Regs        : Registers;
   TempStr4    : Str4;

begin

{
call DOS for today's date;
copy YY from CX into D;
append '/' & MM from hi(DX) into D after replacing ' ' w/ '0' if needed;
append '/' & DD from lo(DX) into D after replacing ' ' w/ '0' if needed;
}

Regs.AX := $2A00;
MSDos (Regs);
str (Regs.CX:4,TempStr4);
D := copy (TempStr4,3,2);
str (hi(Regs.DX):2,TempStr4);
if TempStr4 [1] = ' ' then TempStr4 [1] := '0';
D := D + '/' + copy (TempStr4,1,2);
str (lo(Regs.DX):2,TempStr4);
if TempStr4 [1] = ' ' then TempStr4 [1] := '0';
D := D + '/' + copy (TempStr4,1,2);

end; {GetCurrDate}

{-------------------------------------------------------------------------}
procedure GetCurrTime (var T:Str8);
{-------------------------------------------------------------------------}

var
   Regs        : Registers;
   TempStr4    : Str4;

begin

{
call DOS for today's time;
copy HH from hi(CX) into T after replacing ' ' w/ '0' if needed;
append ':' & MM from lo(CX) into T after replacing ' ' w/ '0' if needed;
append ':' & SS from hi(DX) into T after replacing ' ' w/ '0' if needed;
}

Regs.AX := $2C00;
MSDos (Regs);
str (hi(Regs.CX):2,TempStr4);
if TempStr4 [1] = ' ' then TempStr4 [1] := '0';
T := copy (TempStr4,1,2);
str (lo(Regs.CX):2,TempStr4);
if TempStr4 [1] = ' ' then TempStr4 [1] := '0';
T := T + ':' + copy (TempStr4,1,2);
str (hi(Regs.DX):2,TempStr4);
if TempStr4 [1] = ' ' then TempStr4 [1] := '0';
T := T + ':' + copy (TempStr4,1,2);

end; {GetCurrTime}

{-------------------------------------------------------------------------}
procedure StartUp (RL:Str3);
{-------------------------------------------------------------------------}
{
initialize ZeroRec to all zeros;
get current date and time;
open error file;
log starting date and time in error file;
}

const
  Alphas  : Str24 = 'ABCDEFGHJKLMNPQRSTUVWXYZ';

var
  H       : char;
  M       : char;
  MMDD    : Str4;
  X       : integer;
  Y       : integer;

begin

with ZeroRec do begin
  AB  := 0;
  BB  := 0;
  BS  := 0;
  CS  := 0;
  D   := 0;
  E   := 0;
  ER  := 0;
  G   := 0;
  GF  := 0;
  GS  := 0;
  G_C := 0;
  G_D := 0;
  G_O := 0;
  G_S := 0;
  G_1 := 0;
  G_2 := 0;
  G_3 := 0;
  H   := 0;
  HP  := 0;
  HR  := 0;
  IP  := 0;
  K   := 0;
  L   := 0;
  R   := 0;
  RBI := 0;
  SB  := 0;
  SV  := 0;
  T   := 0;
  W   := 0;
  end; {with ZeroRec do}

GetCurrDate (CurrDate);
GetCurrTime (CurrTime);

MMDD := copy (CurrDate,4,2) + copy (CurrDate,7,2);

val(copy(CurrTime,1,2),X,Y);
if Y = 0 then H := Alphas[X + 1] else H := ' ';
{ writeln ('Y=',Y,' ,X=',X,' ,H=',H); }

val(copy(CurrTime,4,2),X,Y);
if Y = 0 then begin
  X := X div 3 + 1;
  M := Alphas[X];
end; {if Y = 0 then begin}
{ writeln ('Y=',Y,' ,X=',X,' ,M=',M); }

{ writeln;writeln;write ('E'+PgmName[1]+MMDD+H+M+'.'+RL);readln; }
assign (FileErr,'E'+PgmName[1]+MMDD+H+M+'.'+RL);
rewrite (FileErr);

writeln;writeln;writeln (PgmName,' started on ',CurrDate,' @ ',CurrTime);
writeln (FileErr,PgmName,' started on ',CurrDate,' @ ',CurrTime);

end; {StartUp}

{-------------------------------------------------------------------------}
procedure ShutDown;
{-------------------------------------------------------------------------}
{
close error file;
}

begin

GetCurrDate (CurrDate);
GetCurrTime (CurrTime);

writeln;writeln;writeln (PgmName,' ended on ',CurrDate,' @ ',CurrTime);
writeln (FileErr,PgmName,' ended on ',CurrDate,' @ ',CurrTime);

close (FileErr);

end; {ShutDown}

{-------------------------------------------------------------------------}
function GetInt (AStr:Str80;Start,Len:integer;var AnInt:integer):boolean;
{-------------------------------------------------------------------------}
{
parses AStr for an integer starting at Start for Len;
if successful then
  return TRUE;
  return value in AnInt;
else
  return FALSE;
  return location of error in AnInt;
}

var
  Err : integer;

begin
val (copy(AStr,Start,Len),AnInt,Err);
if Err <> 0 then begin
  writeln ('invalid digit @ ',AStr[Start+Err-1],' pos = ',Err);
  writeln (FileErr,'invalid digit @ ',AStr[Start+Err-1],' pos = ',Err);
  GetInt := FALSE;
  AnInt := Err;
  end
else GetInt := TRUE;

end; {GetInt:boolean}

{-------------------------------------------------------------------------}
function GetPrevMMDD (C:Str4):Str4;
{-------------------------------------------------------------------------}
{
validate current month and day in C;
compute PrevMMDD from C;
}

var
  DD,
  MM     : integer;
  PrevD,
  PrevM  : Str2;

begin

if not (GetInt (C,1,2,MM) and GetInt (C,3,2,DD)) then begin
  MM := 0;
  DD := 0;
  end; {if not MM or DD}

if (MM < 1) or (MM > 12) or (DD < 1)
or ((MM = 2) and (DD > 29))
or (((MM = 4) or (MM = 6) or (MM = 9) or (MM = 11)) and (DD > 30))
or (DD > 31) then begin
   MM := 0;
   DD := 0;
   end

else begin
  if DD > 7 then DD := DD - 7
  else begin
    if MM = 1 then MM := 12
    else MM := MM - 1;

    case MM of
      2               : DD := DD + 21;
      4,6,9,11        : DD := DD + 23;
      1,3,5,7,8,10,12 : DD := DD + 24;
      end; {case of MM}
    end; {else 1st 7 days of month}

  end; {else valid MM and DD combo}

str (MM,PrevM);
if MM < 10 then PrevM := '0' + PrevM;
str (DD,PrevD);
if DD < 10 then PrevD := '0' + PrevD;

GetPrevMMDD := PrevM + PrevD;

end; {GetPrevMMDD}

{-------------------------------------------------------------------------}
procedure GetLeagDate (var MLeague:char; var S,P:Str4);
{-------------------------------------------------------------------------}
{
clear screen;
prompt for league and stat month and day;
}

var
  CurrDay,
  CurrMth,
  DaysInMth,
  PrevMth,
  PrevDay : integer;
  OK      : boolean;
  Day,
  Mth     : Str2;

begin

clrscr;

gotoxy (1,5);
{ KB/20010419=commented out league - using 'N' as default
writeln ('      League (A/B/N) ?  _');
}
gotoxy (1,7);
writeln ('      Month?            __');
writeln ('      Day?              __');

{ KB/20010419=commented out league - using 'N' as default
repeat
  OK := true;
  gotoxy (25,5);
  readln (MLeague);
  MLeague := upcase (MLeague);
  if (MLeague <> 'A') and (MLeague <> 'B') and (MLeague <> 'N') then begin
    OK := false;
    gotoxy (10,10);
    writeln ('Choose A or B or N!');
    end
  else begin
    gotoxy (25,5);
    writeln (MLeague);
    end;
  until OK;
}
MLeague := 'N';

repeat
  OK := true;
  gotoxy (25,7);
  BufLen := 2;
  read (CurrMth);
  if (CurrMth < 1) or (CurrMth > 12) then begin
    OK := false;
    gotoxy (10,11);
    writeln ('Month must be from 1 - 12!');
    end
  else
    case CurrMth of
      2               : DaysInMth := 28;
      4,6,9,11        : DaysInMth := 30;
      1,3,5,7,8,10,12 : DaysInMth := 31;
      end; {case of CurrMth}
  until OK;

repeat
  OK := true;
  gotoxy (25,8);
  BufLen := 2;
  read (CurrDay);
  if (CurrDay < 1) or (CurrDay > DaysInMth) then begin
    OK := false;
    gotoxy (10,12);
    writeln ('Day must be from 1 - ',DaysInMth,'!');
    end; {if invalid day}
  until OK;

str (CurrMth,Mth);
if CurrMth < 10 then Mth := '0' + Mth;
str (CurrDay,Day);
if CurrDay < 10 then Day := '0' + Day;
S := Mth + Day;

P := GetPrevMMDD (S);

{
writeln (' ');
writeln ('MLeague ',MLeague,'   Curr ',S,'   Prev ',P);
writeln ('continue? ');readln (Mth);
}

end; {GetLeagDate}
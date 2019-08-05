program InitLeag;
{ input the league, current date;
  read the team file;
    get the team name and abbreviation;
    initialize the team totals;
    show the team name and abbreviation;
    write the team record out to the league's file.}

{$I DCLSTATS.PAS }

const
  PgmName           : Str4 = 'INIT';

var
  Cont              : char;
  Err               : boolean;
  ErrFile           : text;
  I                 : integer;
  InitFile          : text;
  LeagFile          : file of Team;
  Line              : Str80;
  ML                : char;
  NumOfTeams        : integer;
  RL                : Str3;
  ShowDate          : Str5;
  TeamArray         : array [1..NumOfAL] of Team;

{$I UTILSUBS.PAS}

{========================= M A I N =========================
{ input the major league, current date;
  compute previous date;
  input the rot league;
  read the team NAMES file;
    get the team name and abbreviation;
    initialize the team totals;
    show the team name and abbreviation;
    write the team record out to the LEAG file for the previous date.}

begin {Main Program}

GetLeagDate (ML,StatMMDD,PrevMMDD);

ShowDate := copy (StatMMDD,1,2) + '/' + copy (StatMMDD,3,2);

RL := 'DSL';

NumOfTeams := 0;

assign (InitFile,'\'+RL+'\'+RL+'NAMES.'+RL);
reset (InitFile);
assign (LeagFile,'\'+RL+'\LEAG'+copy(PrevMMDD,1,2)+copy(PrevMMDD,3,2)+'.'+RL);
rewrite (LeagFile);

clrscr;
writeln ('beginning of program');

while not (eof(InitFile)) do begin
  NumOfTeams := NumOfTeams + 1;
  readln (InitFile,Line);

  TeamArray[NumOfTeams].Name := copy (Line,1,18);
  TeamArray[NumOfTeams].Abbr := copy (Line,19,4);
  TeamArray[NumOfTeams].TeamNum := NumOfTeams;

  with TeamArray[NumOfTeams] do begin
    writeln ('#',TeamNum:2,' ',Name,' (',Abbr,')');
    ABats  := 0;
    ERuns  := 0;
    HHits  := 0;
    HRuns  := 0;
    PHits  := 0;
    PKs    := 0;
    RBIs   := 0;
    Runs   := 0;
    Saves  := 0;
    Steals := 0;
    Walks  := 0;
    Wins   := 0;
    Inns   := 0;
    end; {with this team do}

  seek (LeagFile,FileSize(LeagFile));
  write (LeagFile,TeamArray [NumOfTeams]);

  end; {while not at eof (LeagFile)}

close (LeagFile);
close (InitFile);

writeln ('end of program.')

end. {InitLeag}
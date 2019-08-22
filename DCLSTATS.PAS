{======================== DCLSTATS.PAS =========================
Declarations and definitions for Keith's Stat System.
}

const
  NumOfAL     = 14;
  NumOfNL     = 16;
  NumOfRL     = 5;
  NumOfPos    = 11;
  NumOfStatsH = 20;
  NumOfStatsP = 17;
  NumOfServ   = 6;

type
  Str2       = string[2];
  Str3       = string[3];
  Str4       = string[4];
  Str5       = string[5];
  Str6       = string[6];
  Str8       = string[8];
  Str12      = string[12];
  Str18      = string[18];
  Str24      = string[24];
  Str40      = string[40];
  Str80      = string[80];
  Str120     = string[120];
  Str160     = string[160];

var
  CurrDate : Str8;
  CurrTime : Str8;
  FileErr  : text;
  PrevMMDD : Str4;
  StatMMDD : Str4;

const
  RLAbbrs    : array [1..NumOfRL] of Str3 = ('DSL','GHL','NNL','NRL','TST');

  PositionSet : set of char = [
             '1',                     {1B}
             '2',                     {2B}
             '3',                     {3B}
             'C',                     {Catcher}
             'M',                     {Middle=2B or SS}
             'O',                     {OF}
             'P',                     {Pitcher}
             'S',                     {SS}
             'U',                     {Utility=any}
             'W',                     {Wing=1B or 3B}
             'X'                      {eXtra=any, but only in September}
                              ]; {PositionSet}

  RecTypeSet : set of char = [
             '*',                     {team}
             '%',                     {owner and phone and manager}
             '@',                     {email address}
             '+',                     {active}
             '-',                     {reserved}
             '?',                     {active but not in ML}
             '!',                     {in ML but not activated}
             '&',                     {minor leaguer}
             '#',                     {minor league pick}
             '$',                     {FAB remaining}
             '=',                     {asterisk trade available}
             '~'                      {waivers}
             ,'/'                     {ignore line}
                             ]; {RecTypeSet}

type

  ListPtr    = ^ListElt;

  ListElt    = record
    Name     : Str18;
    ID       : Str8;
    RecNum   : integer;
    NewPly   : boolean;
    PrevName : ListPtr;
    NextName : ListPtr;
    PrevID   : ListPtr;
    NextID   : ListPtr;
  end; {ListElt}

  Registers = record
    AX,
    BX,
    CX,
    DX,
    BP,
    SI,
    DI,
    DS,
    ES,
    Flags : integer;
  end; {Registers}

  StatFeedRec = record
    Name     : Str4;
    AbbrsAL  : array [1..NumOfAL]  of Str3;
    AbbrsNL  : array [1..NumOfNL]  of Str3;
    AbbrsPos : array [1..NumOfPos] of Str2;
  end; {StatFeedRec}

  PlayerStats = record
    BB,
    D,
    G,
    H,
    HP,
    HR,
    K,
    R,
    T
       : integer;

    case PlayerType : Str2 of
      'S ','R ','P ' :
        (
        BS,
        ER,
        GF,
        GS,
        L,
        SV,
        W
            : integer;
        IP  : real;
        );
      'DH','C ','OF','PH','PR','SS','1B','2B','3B','H ' :
        (
        AB,
        CS,
        E,
        G_C,
        G_D,
        G_O,
        G_S,
        G_1,
        G_2,
        G_3,
        RBI,
        SB
           : integer;
        )
  end; {PlayerStats}

  Player     = record
    New      : boolean;
    Status   : char;
    Name     : Str18;
    ID       : Str8;
    MLTeam   : Str4;
    PrimePos : Str2;
    MLStatus : Str2;
    Throws   : Str2;
    Bats     : Str2;
    YTD      : PlayerStats;
    CWK      : PlayerStats;
  end; {Player}

  Member     = record
    Salary   : real;
    Contract : Str2;
    RostPos  : char;
    PosList  : Str8;
    Stats    : Player;
  end; {Member}

  RankPtr    = ^RankElt;

  RankElt    = record
    Name     : Str18;
    Abbr     : Str4;
    TeamNum  : integer;
    Value    : real;
    Pts      : real;
    Tied     : char;
    Prev     : RankPtr;
    Next     : RankPtr;
  end; {RankElt}

  Team       = record
    Name     : Str18;
    Abbr     : Str4;
    TeamNum,
    ABats,
    ERuns,
    HHits,
    HRuns,
    PHits,
    PKs,
    RBIs,
    Runs,
    Saves,
    Steals,
    Walks,
    Wins     : integer;
    Inns     : real;
  end; {Team}

  StatLineType = (
    G,                      {garbage}
    H,                      {free-agent hitter}
    P                       {free-agent pitcher}
            ); {StatLineType}


const

  CSW  : StatFeedRec = (
         Name     : 'CSW  ';
         AbbrsAL  : ('BAL','BOS','CAL','CWS','CLE','DET','KC ',
                     'MIN','NYY','OAK','SEA','TAM','TEX','TOR');
         AbbrsNL  : ('ARZ','ATL','CHC','CIN','COL','FLO','HOU','LA ',
                     'MLW','MON','NYM','PHI','PIT','STL','SD ','SF ');
         AbbrsPos : ('DH','S ','R ','C ','1B','2B','SS','3B','OF','PH','PR')
                      );

  IBIC : StatFeedRec = (
         Name     : 'IBIC ';
         AbbrsAL  : ('BAL','BOS','CAL','CHW','CLE','DET',' KC',
                     'MIN','NYY','OAK','SEA','TAM','TEX','TOR');
         AbbrsNL  : ('ARZ','ATL','CHC','CIN','COL','FLA','HOU',' LA',
                     'MIL','MTL','NYM','PHI','PIT','STL',' SD',' SF');
         AbbrsPos : ('  ','P ','H ','  ','  ','  ','  ','  ','  ','  ','  ')
                       );

  RW : StatFeedRec = (
         Name     : 'RW  ';
         AbbrsAL  : ('BAL','BOS','CAL','CHW','CLE','DET','KC ',
                     'MIN','NYY','OAK','SEA','TAM','TEX','TOR');
         AbbrsNL  : ('ARI','ATL','CHC','CIN','COL','FLO','HOU','LAD',
                     'MIL','WAS','NYM','PHI','PIT','STL','SND','SNF');
         AbbrsPos : ('  ','P ','H ','  ','  ','  ','  ','  ','  ','  ','  ')
                       );

  SS : StatFeedRec = (
         Name     : 'SS  ';
         AbbrsAL  : ('BAL','BOS','CAL','CHW','CLE','DET','KC ',
                     'MIN','NYY','OAK','SEA','TAM','TEX','TOR');
         AbbrsNL  : ('ARI','ATL','CUB','CIN','COL','FLA','HOU','LA ',
                     'MIL','MON','NYM','PHI','PIT','STL','SD ','SF ');
         AbbrsPos : ('  ','P ','H ','  ','  ','  ','  ','  ','  ','  ','  ')
                       );

  TQS : StatFeedRec = (
         Name     : 'TQS  ';
         AbbrsAL  : ('ANA','BAL','BOS','CHA','CLE','DET','KC ',
                     'MIN','NYA','OAK','SEA','TB ','TEX','TOR');
         AbbrsNL  : ('ARI','ATL','CHN','CIN','COL','FLA','HOU','LA ',
                     'MIL','MON','NYN','PHI','PIT','STL','SD ','SF ');
         AbbrsPos : ('  ','P ','H ','  ','  ','  ','  ','  ','  ','  ','  ')
                       );

  YAHOO : StatFeedRec = (
         Name     : 'YAHOO';
         AbbrsAL  : ('ANA','BAL','BOS','CHA','CLE','DET','KAN',
                     'MIN','NYY','OAK','SEA','TAM','TEX','TOR');
         AbbrsNL  : ('ARI','ATL','CHN','CIN','COL','FLA','HOU','LOS',
                     'MIL','MON','NYM','PHI','PIT','STL','SDG','SFO');
         AbbrsPos : ('RP','SP','C ','1B','2B','SS','3B','OF','NA','  ','  ')
                       );

var

  ZeroRec  : PlayerStats;
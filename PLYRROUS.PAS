{PLYRROUS contains the operations for a PLAYER, such as displaying stats,
finding the record number given an ID or name.}

{$I DCLSTATS.PAS }

var
  APlayer           : Player;
  Cont              : char;
  CurrDate          : Str4;
  CurrPtr           : ListPtr;
  CurrPlyFile       : Str8;
  Err               : boolean;
  ErrFile           : text;
  Fraction          : integer;
  Kind              : char;
  Line              : Str80;
  Mantissa          : integer;
  ML                : char;
  Mode              : char;
  NewFile           : text;
  NewID             : integer;
  NewPlyInd         : boolean;
  PlyFile           : file of Player;
  PrevDate          : Str4;
  PrevPlyFile       : Str8;
  ShowDate          : Str5;
  StartPtr          : ListPtr;
  CSWFile           : text;
  WrkFile           : file of Player;
  WrkPlayer         : Player;


{========================= FindByID =========================
read thru linked list for the player with AnID and returns
the pointer if found, NIL otherwise.}

function FindByID (AnID:integer):ListPtr;

var
  CurrPtr : ListPtr;

begin

CurrPtr := StartPtr;
FindByID := NIL;

while CurrPtr <> NIL do begin
  if AnID = CurrPtr^.ID then begin
    FindByID := CurrPtr;
    CurrPtr := NIL
    end {else found}
  else CurrPtr := CurrPtr^.NextID;
  end;  {while not at end of list}

end; {FindByID}


{========================= InsertPlayerInList =========================
reads thru Name/ID linked list and inserts APtr.}

procedure InsertPlayerInList (AName:Str18;AnID,ARecNum:integer);

var
  AWrk,
  CurrPtr,
  NextWrk : ListPtr;

begin

new (AWrk);
AWrk^.Name      := AName;
AWrk^.ID        := AnID;
AWrk^.RecNum    := ARecNum;
AWrk^.NewPly    := NewPlyInd;
AWrk^.PrevID    := NIL;
AWrk^.NextID    := NIL;

CurrPtr := NIL;
NextWrk := StartPtr;

while NextWrk <> NIL do begin
  if (AWrk^.ID > NextWrk^.ID) then begin
    CurrPtr := NextWrk;
    NextWrk := NextWrk^.NextID;
    end  {if ID > list elt ID}
  else NextWrk := NIL
  end;  {while not at end of list}

if CurrPtr = NIL then begin
  AWrk^.NextID := StartPtr;
  StartPtr  := AWrk;
  end
else begin
  AWrk^.NextID  := CurrPtr^.NextID;
  CurrPtr^.NextID := AWrk;
  end;

end; {InsertPlayerInList}


{========================= MakeIDIndex =========================
reads PlyFile and sets up the Name/ID inverted lists.}

procedure MakeIDIndex;

var
  I       : integer;
  CurrPtr : ListPtr;

begin

assign (PlyFile,CurrPlyFile);
reset (PlyFile);

I := 0;
StartPtr := NIL;

while not (eof(PlyFile)) do begin
  read (PlyFile,APlayer);

  with APlayer do
    if FindByID (ID) = NIL then InsertPlayerInList (Name,ID,I)
    else writeln ('duplicate entries for: ',ID);

  I := I + 1;
 end; {while not eof PlyFile}

end; {MakeIDIndex}


{========================= ShowPlayer  =========================
get PLAYER data in record number Rec;
if Mode = Full Screen then show PLAYER's header;
if Kind = Both or Current then show current stats;
if Kind = Both or Dif then show dif stats;}

procedure ShowPlayer (Rec:integer;Mode,Kind:char);

begin
Mode := upcase (Mode);
Kind := upcase (Kind);

if Rec < 0 then writeln ('record number < 0 ',Rec)
else if not (Mode in ['F','L']) then writeln ('invalid Mode ',Mode)
else if not (Kind in ['B','C','D']) then writeln ('invalid Kind ',Kind)
else begin
  seek (PlyFile,Rec);
  read (PlyFile,WrkPlayer);

  with WrkPlayer do begin
    if Mode = 'F' then begin
      clrscr;
      gotoxy (1,70); write ('Date: ',ShowDate);
      gotoxy (1,1);  write ('Name        : ',Name);
      gotoxy (1,2);  write ('ID          : ',ID);
      gotoxy (1,3);  write ('ML Team     : ',MLTeam);
      gotoxy (1,5);  write ('Primary Pos : ',PrimePos);
      gotoxy (30,3); write ('   ML Status : ',MLStatus);
      gotoxy (30,5); write ('Eligible Pos : ');
      if (PrimePos = 'S ') or (PrimePos = 'R ') then begin
        gotoxy (30,2); write ('      Throws : ',Throws);
        gotoxy (9,7);
          writeln ('    W    L   SVS   IP     H   ER   BB    ERA    RATIO');
        writeln; writeln;
        end {if pitcher}
      else begin
        gotoxy (30,2); write ('        Bats : ',Bats);
        gotoxy (9,7);  writeln ('  ABS   H    HR  RBI   SB   BA');
        writeln; writeln;
        end; {else hitter}
      end; {if Full screen mode then show header stuff}

    if Kind in ['B','C'] then begin
      if Mode = 'F' then write ('CURR     ')
      else write (Name:18,ID:6);
      if (PrimePos = 'S ') or (PrimePos = 'R ') then begin
        write (W:5,L:5,SV:5,IP:7:1,H:5,ER:5,BB:5,ERA:8:3);
        if IP > 0 then writeln (((H + BB) / IP):8:3)
        else writeln (IP:8:3);
        end {if pitcher}
      else begin
        write (AB:5,H:5,HR:5,RBI:5,SB:5);
        if AB > 0 then writeln (BA:7:3);
        end; {else hitter}
      end; {if Kind is current then show current stats}

    if Kind in ['B','D'] then begin
      if Mode = 'F' then write ('DIFF     ')
      else write (Name:18,ID:6);
      if (PrimePos = 'S ') or (PrimePos = 'R ') then begin
        write (DifW:5,DifL:5,DifSV:5,DifIP:7:1,DifH:5,DifER:5,DifBB:5);
        if DifIP > 0 then
          writeln ((9 * DifER / DifIP):8:3,((DifH + DifBB) / DifIP):8:3)
        else writeln (DifIP:8:3,DifIP:8:3);
        end {if pitcher}
      else begin
        write (DifAB:5,DifH:5,DifHR:5,DifRBI:5,DifSB:5);
        if (DifAB > 0) then writeln ((DifH/DifAB):7:3)
        else writeln (DifAB:5);
        end; {else hitter}
      end; {if Kind is dif}

    end; {with WrkPlayer}

  end; {else all parameters valid}

end; {ShowPlayer}























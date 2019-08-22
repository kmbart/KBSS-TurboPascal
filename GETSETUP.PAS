{========================= GetSetup =========================
generates CurrDate and PrevDate.
open error file;
}
procedure GetSetup;

var
  HHM : Str3;

begin

GetCurrDate (CurrDate);

GetCurrTime (CurrTime);

HHM := copy (CurrTime,1,3);

assign (FileErr,'ERRS'+CurrDate+'.'+HHM);
rewrite (FileErr);

end; {GetSetup}
# KeithStats---TurboPascal
Original TurboPascal version of the KeithStats System
GET<yy> = import raw pitcher and hitter stats from stat source and generate weekly differences that are added to the previous week's PLY file to create the new week's PLY file for use in CALC program. (<yy> is the year the program applies to.)
CALC<#> = produce the YTD (year-to-date) and CWK (current week) report files from the ROST and PLY files for <mmdd>. (<#> is the number of categories used to produce standings - either 4 or 5, while <mmdd> is the month and day the stats are applied to or "CURR" for the version that doesn't recalc the stats but does display the current roster lineups.)

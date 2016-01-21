# Checks valid codes in columns.

require 'Datavyu_API.rb'

begin
   #$debug=true

   # Format is "variable name", "output file name", "argument name", ["valid input 1", "valid input 2", ...], "argument name", ["valid input 1", "valid input 2"] ...
   check_valid_codes("id", "", "study", ["locaps"], "tdate", ["06/12/12", "06/13/12"])
   check_valid_codes("trial", "", "sfr", ["s", "f", "r"], "reachhand", ["l", "r", "b", "n"])
end

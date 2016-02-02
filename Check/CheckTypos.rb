# Checks valid codes in columns.

require 'Datavyu_API.rb'

begin

   # Format is "variable name", "output file name", "argument name", ["valid input 1", "valid input 2", ...], "argument name", ["valid input 1", "valid input 2"] ...
   checkValidCodes("id", "", "idnum", ["1", "2"], "testdate", ["06/12/12", "06/13/12"])
   checkValidCodes("trial", "", "trialnum", ["s", "f", "r"], "result_xyz", ["x", "y", "z", "."])
end

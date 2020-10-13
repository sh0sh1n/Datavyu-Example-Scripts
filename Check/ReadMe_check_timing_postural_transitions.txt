Run this script on your open datavyu spreadsheet to check that cells 
within specified columns meet certain timing conditions.

This script does various timing checks (by printing warning messages into the
scripting console for each violation) on cells of columns specified in
Parameters section of script.
It checks for continuity (cells account for every frame of video), checks to
make sure cells are always nested (temporally contained) within other cells, and
finally checks to make sure some cell always nests (temporally contains) other
cells.

If there are certain timing checks you want to do on certain columns, replace
those column lists in the Parameters section with your column names, or just
borrow from the commented chunks of code.

require 'Datavyu_API.rb'

def getCellFromTime(col, time)
  for cell in col.cells
    if cell.onset <= time and cell.offset >= time
      return cell
    end
  end
  return nil
end

def printCellArgs(cell)
  s = Array.new
  s << cell.ordinal.to_s
  s << cell.onset.to_s
  s << cell.offset.to_s
  for arg in cell.arglist
    s << cell.get_arg(arg)
  end
  return s
end

begin
   #$debug=true

   # Format is "variable name", "output file name", "argument name", ["valid input 1", "valid input 2", ...], "argument name", ["valid input 1", "valid input 2"] ...
   check_valid_codes("id", "", "study", ["locaps"], "tdate", ["06/12/12", "06/13/12"])
   check_valid_codes("trial", "", "sfr", ["s", "f", "r"], "reachhand", ["l", "r", "b", "n"])
end

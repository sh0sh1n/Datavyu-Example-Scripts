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

    # Check argument example
    # Format: "primary column", "reliability column", "variable that is the same in each cell (like a trial number)", the difference between primary times and rel times that is OK, output file (use "") for no output file
    # Time check is in milliseconds
    check_rel("trial", "rel.trial", "trialnum", 100, "/Users/motoruser/Desktop/Relcheck.txt")

end

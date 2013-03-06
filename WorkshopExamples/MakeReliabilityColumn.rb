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

    # Make rel example
    # Format: "rel column name", "variable to make rel from", "multiple to keep (2 is every other cell)", "carry over argument1", "carry over argument2", ...
    make_rel("rel.trial", "trial", 2, "onset", "offset", "trialnum")


end

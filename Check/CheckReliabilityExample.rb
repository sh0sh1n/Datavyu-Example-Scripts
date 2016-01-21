# Checks reliability on columns trial and rel_trial using code "trialnum" as matching key.

## Params
primary_column_name = 'trial'
reliability_column_name = 'rel_trial'
matching_code = 'trialnum'
leniency_ms = 100
output_file = '~/Desktop/Relcheck.txt'

## Methods
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

## Body
begin
  # Convert relative path and symbols to fully qualified path
  output_file = File.expand_path(output_file)

    # Check argument example
    # Format: "primary column", "reliability column", "variable that is the same in each cell (like a trial number)", the difference between primary times and rel times that is OK, output file (use "") for no output file
    # Time check is in milliseconds
    check_rel(primary_column_name, reliability_column_name, matching_code, leniency_ms, output_file)

end

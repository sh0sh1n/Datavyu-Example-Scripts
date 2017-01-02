# Create columns with cells of fixed intervals spanning cells of a reference column.
# Create columns with a fraction of the interval cells for reliability coding.

## Parameters
column_code_map = {
  'column1' => %w(code1 code2),
  'column2' => %w(code1 code2 code3 code4),
  'column3' => %w(code1 code2 code3 code4 code5 code6)
}
reference_column_name = 'my_reference_column' # change to name of column that spans coding region
interval_size = 10 * 1000 # duration of each interval cell

# Copies blank primary coder's cells at the specified interval; e.g. 4 to copy every fourth primary cell
reliability_interval = 4

# Specifies starting point of copying primary coder's cells. Values should be in range [0..reliability_interval-1]
# NOTE: formula for selection is: (primary_cell_ordinal) MOD (reliability_interval) =? reliability_start
# Use 1 to start selection at first cell.
reliability_start = 1

## Body
require 'Datavyu_API.rb'

ref_col = getVariable(reference_column_name)

columns = {}
column_code_map.each_pair do |cname, ccodes|
  columns[cname] = createNewColumn(cname, *ccodes)
end

ref_col.cells.each do |rc|
  columns.values.each do |col|
    onset = rc.onset
    offset = onset + interval_size
    while(onset < rc.offset)
      ncell = col.make_new_cell
      ncell.onset = onset
      ncell.offset = offset

      onset = offset
      offset = [onset + interval_size, rc.offset].min
    end
  end
end
columns.values.each{ |x| setVariable(x) }
columns.keys.each{ |x| columns[x] = getVariable(x) } # We need to pull the columns from Datavyu so that the ordinal numbers are updated

# Insert reliability columns and add cells based on reliability_interval
column_code_map.each_pair do |cname, ccodes|
  # Insert the new column
  rel_col = createNewColumn("#{cname}_rel", *ccodes)
  pri_col = columns[cname]
  cand_cells = pri_col.cells.select{ |x| x.ordinal % reliability_interval == reliability_start }

  # Insert cells for rel coding
  cand_cells.each do |cc|
    ncell = rel_col.make_new_cell
    ncell.onset = cc.onset
    ncell.offset = cc.offset
  end
  setVariable(rel_col)
end

puts "Finished!"

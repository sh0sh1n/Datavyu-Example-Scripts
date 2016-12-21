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
reliability_amount = 4 # choose rel cells based on this number e.g. every 4th


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

# Insert reliability columns and add cells based on reliability_amount
column_code_map.each_pair do |cname, ccodes|
  # Insert the new column
  rel_col = createNewColumn("#{cname}_rel", *ccodes)
  pri_col = columns[cname]
  cand_cells = pri_col.cells.select{ |x| x.ordinal % reliability_amount == 1 } # use (0 1 2 3) to choose which cell is the first one

  # Insert cells for rel coding
  cand_cells.each do |cc|
    ncell = rel_col.make_new_cell
    ncell.onset = cc.onset
    ncell.offset = cc.offset
  end
  setVariable(rel_col)
end

puts "Finished!"

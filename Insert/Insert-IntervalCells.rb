# Create columns with cells of fixed intervals spanning cells of a reference column.
# Create columns with a fraction of the interval cells for reliability coding.

## Parameters
column_code_map = {
  'column1' => %w(code1 code2)
}
reference_column_name = 'my_reference_column' # change to name of column that spans coding region
interval_size = 5 * 60 * 1000 # duration of each interval cell

## Body
require 'Datavyu_API.rb'

ref_col = get_column(reference_column_name)

columns = {}
column_code_map.each_pair do |cname, ccodes|
  columns[cname] = new_column(cname, *ccodes)
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
columns.values.each{ |x| set_column(x) }

puts "Finished!"

## Parameters
# add a new cell to momobject_close column every time a cell from mom_act_clean
# starts within this time range after the start of a babyobject_uniquetypes_clean cell
time_range = [0, 300]

## Body
require 'Datavyu_API.rb'

babyobject = get_column('babyobject_uniquetypes_clean')
momobject = get_column('mom_act_clean')

momobject_close = new_column('momobject_close', momobject.arglist)

babyobject.cells.each do |bcell|
  # get list of cells that start within time range relative to current
  # babyobject cell
  mom_cell = momobject.cells.select{ |c| c.onset >= bcell.onset +
    time_range.first && c.onset <= bcell.onset + time_range.last }
  unless mom_cell.empty?
    # take the first cell that satisfies condition and add it to new column
    momobject_close.new_cell(mom_cell.first)
  end
end

momobject_close.add_code('smlcl')
# update the spreadsheet to have new column 
set_column('momobject_close', momobject_close)

## Parameters
# Insert a new cell in ChildPrompted every time a cell in ParentActions starts
# within time_tolerance ms of a ChildActions cell
# name of new column
insert_col_name = 'ChildPrompted'
# list of codes for new column
insert_code_name = %w[child_prompt_ordinal yn]
# a ParentActions cell is a candidate for child-prompted if its onset occurs
# within this many ms of ChildActions cell
time_tolerance = 3000

## Body
require 'Datavyu_API.rb'

# fetch the columns
child_actions = get_column('ChildActions')
parent_actions = get_column('ParentActions')

# initialize new column
child_prompted = create_new_column(insert_col_name, *insert_code_name)

# loop through child actions cells
child_actions.cells.each do |c|
  # find candidcate cells
  candidate_cell = parent_actions.cells.select{ |p| p.onset >= c.onset &&
    p.onset <= c.offset+time_tolerance }
  # create cell in new column time-locked to first instance 
  unless candidate_cell.first.nil?
    ncell = child_prompted.new_cell()
    ncell.onset = candidate_cell.first.onset
    ncell.offset = candidate_cell.first.offset
    ncell.child_prompt_ordinal = c.ordinal
  end
end

set_column(insert_col_name, child_prompted)

## Parameters
insert_col_name = 'ParentPrompted'
insert_code_name = %w[parent_prompt_ordinal yn]
# a ChildActions cell is a candidate for parent-prompted if its onset occurs
# within this many ms of ParentActions cell
time_tolerance = 3000

## Body
require 'Datavyu_API.rb'

parent_actions = get_column('ParentActions')
child_actions = get_column('ChildActions')

parent_prompted = create_new_column(insert_col_name, *insert_code_name)

parent_actions.cells.each do |p|
  candidate_cell = child_actions.cells.select{ |c| c.onset >= p.onset &&
    c.onset <= p.offset+time_tolerance }
  unless candidate_cell.first.nil?
    ncell = parent_prompted.new_cell()
    ncell.onset = candidate_cell.first.onset
    ncell.offset = candidate_cell.first.offset
    ncell.parent_prompt_ordinal = p.ordinal
  end
end

set_column(insert_col_name, parent_prompted)

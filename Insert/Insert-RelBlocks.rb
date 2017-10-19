# Insert block columns nested within cells of another column to do reliability coding.

# In this example, we have a column called 'session' with cells designating portions of
# video to code on. This script will create a new column (rel_block_movement)
# and for each 'session' cell, insert a new cell into 'rel_block_movement' that is a
# fragment of the 'session' cell.
# Additionally, it will create blank columns with preset codes, if any are defined in
# the 'coding_columns' parameter.

## Parameters
session_column_name = 'session'
block_column_name = "rel_blocks_movement"
block_column_codes = %w(x) #todo: allow for meaningful codes in block col
fraction = 0.25	# fraction of the session cell to use for each block cell
coding_columns = {
	'movement_rel' => %w(locomotion steps)
}

## Body
require "Datavyu_API.rb"
sesion_column = get_column(session_column_name)
if sesion_column.nil?
	raise "Error : no column named #{session_column_name}"
end

session_cells = sesion_column.cells
# Check to make sure we have a reference cell
if session_cells.size == 0
	raise "No valid reference cell!"
end


block_column = new_column(block_column_name, *block_column_codes)

session_cells.each do |session_cell|
	new_cell = block_column.new_cell
	new_cell_duration = (fraction*session_cell.duration).round
	new_cell.onset = rand(session_cell.duration - new_cell_duration)+session_cell.onset
	new_cell.offset = new_cell.onset+new_cell_duration
end

set_column(block_column)

# Add coding columns
coding_columns.each_pair do |colname, codes|
	set_column(new_column(colname, *codes))
end

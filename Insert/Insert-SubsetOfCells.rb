# Look through the cells of a given column and copy certain cells to another column.
# Selection criteria is specified in a lambda parameter.

## Parameters
# Name of existing column in spreadsheet.
existing_column_name = 'MyFirstCodingPass'

# Name for the new column this script will create.
new_column_name = 'MySecondCodingPass'

# List of codes whose values will be copied over from the existing column to the newly created column.
# Note that for this to happen, the new column will have each of these codes in their list of codes,
# with the exception of onset and offset since they are implicit codes.
codes_to_keep = %w(onset offset condition)

# List of additional codes to add to the new column. Can be left as an empty list.
additional_new_codes = %w(result_ab result_xy)

# You can change the order of the codes in the new column here.
new_column_codes = codes_to_keep + additional_new_codes

# Specify the selection condition to check on each cell in the existing column.
# This example condition selects cells, x, such that the condition code of cell x is equal to 'a'.
selection_condition = lambda{ |x| x.condition == 'a' }

## Body
require 'Datavyu_API.rb'

# Fetch existing column.
col = get_column(existing_column_name)

# Select subset of cells using selection function.
selected_cells = col.cells.select(&selection_condition)

# Sanitize the new column's code list of implicit codes.
new_column_codes -= %w(ordinal onset offset)

# Create the new column
new_col = new_column(new_column_name, *new_column_codes)

# Create a cell in the new column for each selected cell.
selected_cells.each do |sc|
  ncell = new_col.new_cell # make new cell

  # Copy over code values as necessary.
  codes_to_keep.each do |code|
    ncell.change_code(code, sc.get_code(code)) # copy over value from existing cell.
  end

end

# Save new column to spreadsheet.
set_column(new_col)

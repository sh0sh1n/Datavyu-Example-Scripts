# Look through the cells of a given column and copy certain cells to another column.
# Selection criteria is specified in a lambda parameter.

## Parameters
# Name of existing column in spreadsheet.
existing_column_name = 'transcribe'

# Name for the new column this script will create.
new_column_name = 'notable_utterances'

# List of codes whose values will be copied over from the existing column to the newly created column.
# Note that for this to happen, the new column will have each of these codes in their list of codes,
# with the exception of onset and offset since they are implicit codes.
codes_to_keep = %w(onset offset content)

# List of additional codes to add to the new column. Can be left as an empty list.
additional_new_codes = %w(type)

# You can change the order of the codes in the new column here.
new_column_codes = codes_to_keep + additional_new_codes

# Specify the selection condition to check on each cell in the existing column.
# This example condition selects cells such that the content code of cell contains
# any of the keywords in my_list.
# my_list = %w(mouth hand milk)
# selection_condition = lambda do |cell|
#   my_list.any?{ |keyword| cell.content.include?(keyword) }
# end

# This selection condition is similar to prior. However, this will only match
# whole words not part of words. It will remove non-word characters (e.g., punctuations)
# from the end of words in the transcript.
selection_condition = lambda do |cell|
  my_list.any? do |keyword|
    cell.content.split(' ').any?{ |x| x.gsub(/\W+$/, '') == keyword }
  end
end

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

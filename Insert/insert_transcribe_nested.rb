## This script will create two new columns based on the transcribe column
## and the 'nesting' column in which transcribe cells are occasionally temporally
## nested. It will separate the transcribe cells based on whether or not they
## are nested and copy them to either a 'nested' or 'outside' column.
## This way either of the new columns can be exported in the normal way to CLAN
## with nesting condition already built in.

## Parameters
# name of columnw with transcription cells
transcribe_col_name = 'transcribe'
# name of column in which transcription cells may be nested
nesting_col_name = 'bookbouts'

## Body
require 'Datavyu_API.rb'

# fetch columns from spreadsheet
transcribe_col = get_column(transcribe_col_name)
nesting_col = get_column(nesting_col_name)

# name of new column in which to insert nested cells
nested_col_name = transcribe_col_name + '_nested_' + nesting_col_name
# name of new column in which to insert lone (unnested) transcribe cells
outside_col_name = transcribe_col_name + '_outside_' + nesting_col_name
# initialize new columns with transcribe codes
nested_col = new_column(nested_col_name, transcribe_col.cells.first.arglist)
outside_col = new_column(outside_col_name, transcribe_col.cells.first.arglist)

# loop through transcribe cells and copy to appropriate columns
transcribe_col.cells.each do |c|
  # check if there exists a cell in nesting column in which current transcribe
  # cell is nested
  if nesting_col.cells.map{ |nc| nc.contains(c) }.any?
    # insert cell into appropriate column
    nested_col.new_cell(c)
  else
    outside_col.new_cell(c)
  end
end

# show columns in spreadsheet
puts "Inserting new column #{nested_col_name}..."
set_column(nested_col_name, nested_col)
puts "Inserting new column #{outside_col_name}..."
set_column(outside_col_name, outside_col)

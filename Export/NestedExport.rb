# Print data from all Datavyu files in a directory (same spreadhsheet layout).

## Params
input_folder = '~/Desktop/input' # '~' is shortcut for home directory; ~/Desktop will usually get your desktop folder
output_file = '~/Desktop/output.csv'
delimiter = ',' # separator between data
print_header = true

# Map from name of columns to list of codes to print
code_map = {
  'id'  => %w(id testdate),
  'condition' => %w(ordinal onset offset condition block),
  'trial' => %w(ordinal onset offset outcome_a outcome_b)
}
static_columns = %w(id) # columns with only one cell; repeat data for all rows in file
nested_columns = %w(condition trial) # order columns are nested temporally; columns later in the list are nested WITHIN columns earlier in the list



## Body
require '~/Desktop/datavyu_api.rb'

# Get list of opf files
infiles = get_datavyu_files_from(input_folder)

# Init an empty list to store lines of data
data = []

# Loop over all Datavyu files (files in directory that end with ".opf" )
for file in infiles
  puts "Opening " + file
  input_path = File.join(File.expand_path(input_folder), file)
  $db, $pj = loadDB(input_path)

  # Get the variables we want to print from the loaded file.
  # Create blank columns if file does not contain a specified column.
  columns = {}
  code_map.each_pair do |colname, codes|
    if get_column_list.include?(colname)
      columns[colname] = get_column(colname)
    else
      puts "Column #{colname} not found, using temporary blank column."
      columns[colname] = new_column(colname, *(codes - %w(ordinal onset offset)))
    end
  end

  if print_header
    header = (static_columns + nested_columns).map{ |x| code_map[x].map{ |y| "#{x}_#{y}" } }.flatten
    data << header.join(delimiter)
    print_header = false
  end

  # Get data for static columns
  static_data = static_columns.map do |colname|
    codes = code_map[colname]
    cell = columns[colname].cells.first
    (cell.nil?)? [''] * codes.size : cell.get_codes(code_map[colname])
  end
  static_data.flatten! # make sure array is 1-dimensional

  # Add a row of data by iterating over the cells of the most deeply nested column
  iter_col = columns[nested_columns.last]
  iter_codes = code_map[nested_columns.last]
  iter_col.cells.each do |iter_cell|
    # Find data from cells in columns up the nesting hierarchy
    outer_data = nested_columns[0..-2].map do |colname|
      col = columns[colname]
      codes = code_map[colname]

      cell = col.cells.find{ |x| x.contains(iter_cell) }
      (cell.nil?)? [''] * codes.size : cell.get_codes(codes)
    end
    row = static_data + outer_data.flatten + iter_cell.get_codes(iter_codes)
    data << row.join(delimiter)
  end
end

# Open the file we want to print the output to
output_file = File.new(File.expand_path(output_file), 'w')

# Write out data to file
puts "Writing to file..."
output_file.puts data
output_file.close

puts "FINISHED"

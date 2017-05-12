# Merge columns and export.

## Parameters
# Directory containing Datavyu files
datavyu_dir = "~/Desktop/infantlabdatavyu"

# Full path of output file
output_file = '~/Desktop/Data.csv'

# Separator string
delimiter = ','

# Print header in output file
print_header = true

# Columns that can't be merged because onset/offset not coded
columns_static = %w(id)

# Columns to merge and print
columns_to_merge = %w(condition speech gesture)

## Body
require 'Datavyu_API.rb'

datavyu_path = File.expand_path(datavyu_dir)

datavyufiles = get_datavyu_files_from(datavyu_path, true)

data = [] # cache for data
datavyufiles.each do |dvfile|

  # Load the file
  $db, $pj = load_db(File.join(datavyu_path, dvfile))
  next unless (columns_to_merge + columns_static - get_column_list).empty? # Skip files missing requisite columns

  puts "Working on #{dvfile}..."

  static_cols = columns_static.map{ |x| get_column(x) }
  merge_cols = columns_to_merge.map{ |x| get_column(x) }

  export_col = merge_columns('export', *merge_cols)

  # Add header to data array if flag set
  if print_header
    header = (static_cols.map(&:arglist).flatten + %w(onset offset) + export_col.arglist).join(',')
    data << header
    print_header = false
  end

  # Get data from static columns
  static_data = static_cols.map{ |col| col.cells.first.argvals }.flatten

  # Iterate over cells and add rows of data
  export_col.cells.each do |cell|
    row = static_data + [cell.onset, cell.offset] + cell.argvals
    data << row.join(delimiter)
  end

end

# Write data to file
puts "Writing data to file..."
output_path = File.expand_path(output_file)
outfile = File.open(output_path, 'w+')
outfile.puts data
outfile.close

puts "Finished."

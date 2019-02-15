# Batch print in long format.
# Option to specify static columns whose codes will get their own columns.
# Each code/value pair will be exported as a new row.
# Header will be {static column codes}, column name, code name, code value

## Parameters
input_folder = '~/Desktop/Datavyu'
output_file = '~/Desktop/DataLong.csv'
delimiter = ','
blank_value = ''
code_map = {
  'ID' => %w(onset offset a b c d),
  'CodingPass1' => %w(ordinal onset offset code01),
  'CodingPass2' => %w(ordinal onset offset code01 code02)
}

static_columns = %w() # these columns will have codes from first cell repeated for entire file
sequential_columns = %w(ID CodingPass1 CodingPass2) # cells from these columns will be exported as single rows for each code
print_header = true

## Body
require 'Datavyu_API.rb'

data = []

inpath = File.expand_path(input_folder)
infiles = get_datavyu_files_from(inpath)
infiles.each do |infile|
  puts "Working on #{infile}..."

  # Load the spreadsheet
  $db, $pj = load_db(File.join(inpath, infile))

  # Add header to the data if needed
  if print_header
    header = static_columns.map{ |x| code_map[x].map{ |y| "#{x}_#{y}"} } + %w(column code value)
    data << header.join(delimiter)
    print_header = false
  end

  # Fetch static data
  static_data = static_columns.map do |colname|
    col = get_column(colname)
    cell = col.cells.first
    values = cell.get_codes(code_map[colname])
  end.flatten

  sequential_columns.each do |colname|
    col = get_column(colname)
    codes = code_map[colname]
    col.cells.each do |cell|
      codes.each do |code|
        value = cell.get_code(code)
        row = static_data + [colname, code, value]
        data << row.join(delimiter)
      end
    end
  end
end

# Write output to file.
puts "Writing to file..."
outpath = File.expand_path(output_file)
outfile = File.open(outpath, 'w+')
outfile.puts data
outfile.close

puts "Finished."

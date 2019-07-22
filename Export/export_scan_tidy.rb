# frozen_string_literal: true

## Parameters
input_folder = '~/Desktop/Datavyu' # folder containing .opf files
output_file = '~/Desktop/Data.csv' # file to write the data to

# This is a listing of all columns and the codes from those columns that should
# be exported.
code_map = {
  'id' => %w[
    study participant testdate birthdate agegroup sex
    visit timerecstart english race ethnicity
  ],
  'babyobject_uniquetypes' => %w[
    ordinal onset offset smhouse childhouse
    lghouse food toy
  ],
  'mom_prox' => %w[ordinal onset offset proximal],
  'mom_lang_clean' => %w[ordinal onset offset eafsrd yn],
  'transcribe' => %w[ordinal source content]
}

# Static columns are columns with a single cell. Code values from the first cell
# will be printed.
static_columns = %w[id]

# Columns to scan
scan_columns = %w[mom_lang_clean transcribe babyobject_uniquetypes mom_prox]

# Linked columns allows printing cells using a custom matching function.
linked_columns = %w[]

# Specify arbitrary links for linked columns.
# Each linked column must have a function that takes as input:
#   1) list of cells in current row of data
#   2) list of cells in the linked column
# and returns the cell from the linked column
# which should be printed for this row.
links = {}

delimiter = ','

## Body
require 'Datavyu_API.rb'
require 'csv'

# Header order is: static, bound, nested, sequential
all_columns = static_columns + scan_columns + linked_columns
# All columns must have codes defined in code_map
missing_columns = all_columns - code_map.keys
unless missing_columns.empty?
  puts 'Missing following columns from code_map parameter:'
  puts missing_columns
  raise
end

header = all_columns.map do |colname|
  code_map[colname].map { |codename| "#{colname}_#{codename}" }
end.flatten
data = CSV.new(String.new, write_headers: true, headers: header, col_sep: delimiter)

# Helper function to get convert cells to appropriate
# code values defined in code map.
# If the cell is nil, use blanks for values.
data_map = lambda do |mapping, columns, cells|
  columns.zip(cells).map do |(col, cell)|
    codes = mapping[col]
    cell.nil? ? [''] * codes.size : cell.get_codes(codes)
  end
end.curry[code_map]

input_path = File.expand_path(input_folder)
infiles = Dir.chdir(input_path) { Dir.glob('*.opf') }
infiles.each do |infile|
  $db, $pj = load_db(File.join(input_path, infile))
  puts "Printing #{infile}..."

  columns = {}
  code_map.keys.each { |x| columns[x] = get_column(x) }

  # Get cells from static columns
  static_cells = static_columns.map do |col|
    columns[col].cells.first
  end
  # static_data = static_cells.map do |cell|
  # cell.get_codes(code_map[cell.parent])
  # end.flatten
  # static_data = map_helper(static_columns, static_cells)
  static_data = data_map[static_columns][static_cells].flatten

  # Generate list of unique timestamps
  onsets = scan_columns.map do |col|
    columns[col].cells.map(&:onset)
  end.flatten.uniq.sort

  # Iterate over onset times
  onsets.each do |time|
    # Get row of cells from scan columns at this time
    scan_cells = scan_columns.map do |col|
      columns[col].cells.find { |x| x.spans(time) }
    end
    scan_data = data_map[scan_columns][scan_cells].flatten

    # Get data from bound/linked columns
    linked_cells = linked_columns.map do |lcol|
      rule = links[lcol]
      rule.call(static_cells + scan_cells.compact, columns[lcol].cells)
    end
    linked_data = data_map[linked_columns][linked_cells].flatten

    # Convert cells to codes
    row = static_data + scan_data + linked_data
    data << row
  end
end

puts 'Writing data to file...'
outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data.string
outfile.close

puts 'Finished.'

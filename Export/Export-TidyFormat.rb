# frozen_string_literal: true

# Flexible export script.
# Print single-cell columns "T" as repeated columns for file.
# Iterate over nested cells.
# For each nested cell "N", iterate over list of "sequential columns" and
# print rows of data for each cell "S" in that column nested inside "N".
# For example (Ci is the ith code in the cell):
# row1 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, S1C1, S1C2, <blank>, <blank>
# row2 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, S1C1, S1C2, <blank>, <blank>
# row3 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, <blank>, <blank>, S2C1, S2C2
# Also supports arbitrary printing of data from columns based on linking rules.

## Parameters
input_folder = '~/Desktop/Datavyu' # folder containing .opf files
output_file = '~/Desktop/Data.csv' # file to write the data to

# This is a listing of all columns and the codes from those columns that should
# be exported.
code_map = {
  'id' => %w[participant testdate birthdate agegroup sex],
  'transcribe' => %w[ordinal onset source content],
  'babyobject_uniquetypes_clean' => %w[ordinal onset offset smhouse childhouse
                                       lghouse food toy],
  'mom_lang_clean' => %w[ordinal eafsrd yn],
  'mom_prox' => %w[ordinal onset offset]
}

# Static columns are columns with a single cell. Code values from the first cell
# will be printed.
static_columns = %w[id]

# Nested columns lists, in order, the hierarchical nesting of columns.
# Cells in the second column will always be nested temporally within cells of
# the first column. Cells in the third column will always be nested temporally
# within cells of the second column. Etc...
# The last column is this list is the innermost nested column.
nested_columns = %w[babyobject_uniquetypes_clean transcribe]

# Sequential columns lists columms that should be printed on separate rows.
# If there is at least one nested_column specified, cells from the sequential
# columns will be printed only if they are nested inside the innermost nested cell.
sequential_columns = %w[mom_lang_clean]

# Linked columns allows printing cells using a custom matching function.
linked_columns = %w[mom_prox]

# Specify arbitrary links for linked columns.
# Each linked column must have a function that takes as input:
#   1) list of cells in current row of data
#   2) list of cells in the linked column
# and returns the cell from the linked column that should be printed for this row.
links = {
  'mom_prox' => lambda do |row_cells, col_cells|
    ref_cell = row_cells.find { |x| x.parent == 'mom_lang_clean' }
    ref_cell.nil? ? nil : col_cells.find { |x| x.overlaps_cell(ref_cell) }
  end
}

delimiter = ','

## Body
require 'Datavyu_API.rb'
require 'csv'

# all columns to print
all_cols = [static_columns, linked_columns,
            nested_columns, sequential_columns].flatten
# Sanity check parameters.
# Make sure all specified columns have entries in the code map
invalid_cols = all_cols - code_map.keys
unless invalid_cols.empty?
  raise 'Following columns do not have entries in code_map parameter: '\
        "#{invalid_cols.join(', ')}"
end

# Simple method to print nested columns.
# Returns a list of list where the inner list
# is a row of cells corresponding to a line of data to print out.
def nested_print(*columns)
  nested_print_helper(columns, [], [])
end

# Recursive method to add
def nested_print_helper(columns, row_cells, table)
  col = columns.first

  if col.nil?
    table << row_cells.dup
    return table
  end

  oc = row_cells.last
  cells = col.cells
  # select only nested cells if outer cell exists
  cells = cells.select { |x| oc.contains(x) } unless oc.nil?

  if cells.empty?
    table << row_cells.dup
    return table
  end

  cells.each do |cell|
    row_cells.push(cell)
    table = nested_print_helper(columns[1..-1], row_cells, table)
    row_cells.pop
  end

  table
end

# Function to get a table of sequential cells
# in a diagonal layout: each row has a single
# cell from a single column.
sequential_printer = lambda do |seq_cols, outer_cell|
  return [[]] if seq_cols.empty?

  table = []
  row = Array.new(seq_cols.size)
  seq_cols.each_with_index do |sc, idx|
    seq_cells = sc.cells
    seq_cells = seq_cells.select { |x| outer_cell.contains(x) } unless outer_cell.nil?

    seq_cells.each do |c|
      row[idx] = c
      table << row.dup
    end
    row[idx] = nil
  end
  table
end

# Helper function to get codes from list of cells
# using the column-code mapping.
# Returns a hashmap from column name to list of values
data_map = lambda do |mapping, columns, cells|
  # if no cells, all values are blanks
  cells ||= []
  columns.zip(cells).each_with_object({}) do |(col, cell), h|
    codes = mapping[col]
    h[col] = cell.nil? ? codes.map { '' } : cell.get_codes(codes)
  end
end.curry.call(code_map)

# Flattens out the values of the data map to generate a row of output
data_row = ->(cols, cells) { data_map.call(cols, cells).values.flatten }.curry
all_data = data_row.call(all_cols)

# Header order is: static, bound, nested, sequential
col_header = lambda do |map, col|
  map[col].map { |x| "#{col}_#{x}" }
end.curry.call(code_map)
header = all_cols.flat_map(&col_header)
data = [header.join(delimiter)]
data = CSV.new(String.new, write_headers: true, headers: header, col_sep: delimiter)

input_path = File.expand_path(input_folder)
infiles = Dir.chdir(input_path) { Dir.glob('*.opf') }
infiles.sort.each do |infile|
  $db, $pj = load_db(File.join(input_path, infile))
  puts "Printing #{infile}..."

  columns = code_map.keys.each_with_object({}) { |x, h| h[x] = get_column(x) }

  # Get cells from static columns
  static_cells = static_columns.map do |col|
    columns[col].cells.first
  end

  # map column names to actual columns
  cols = ->(xs) { xs.map { |x| columns[x] } }
  nest_cols = cols.call(nested_columns)
  seq_cols = cols.call(sequential_columns)

  # Get rows of cells for nested columns
  nested_table = nested_print(*nest_cols)

  # Iterate over the cell rows
  nested_table.each do |nested_cells|
    # The innermost cell is in the column at the end of the nested columns list
    innermost_cell = nested_cells.last

    seq_table = sequential_printer.call(seq_cols, innermost_cell)
    # if the table is empty, add a blank row so we can still print
    seq_table << [] if seq_table.empty?
    seq_table.each do |sequential_cells|
      # Get data from bound/linked columns
      linked_cells = linked_columns.each_with_object([]) do |lcol, arr|
        rule = links[lcol]
        lcell = rule.call(
          (static_cells + arr + nested_cells + sequential_cells).compact,
          columns[lcol].cells
        )

        arr << lcell
      end

      all_cells = static_cells + linked_cells + nested_cells + sequential_cells
      row = all_data.call(all_cells)
      data << row
    end
  end
end

puts 'Writing data to file...'
outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data.string
outfile.close

puts 'Finished.'

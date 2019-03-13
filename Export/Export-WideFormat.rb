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
output_file = '~/Desktop/Data.csv'  # file to write the data to

# This is a listing of all columns and the codes from those columns that should
# be exported.
code_map = {
  'id' => %w[study region agegrp id sex tdate bdate],
  'cond' => %w[ordinal onset offset task],
  'place' => %w[ordinal onset offset clothes leg],
  'motorbout' => %w[ordinal onset offset none tri sit belly hk_hf bumshuf stand cruise walk],
  'sitassess' => %w[ordinal onset offset sittype sitend],
  'linked_col1' => %w[ordinal onset offset]
}

# Static columns are columns with a single cell. Code values from the first cell
# will be printed.
static_columns = %w[id]

# Nested columns lists, in order, the hierarchical nesting of columns.
# Cells in the second column will always be nested temporally within cells of
# the first column. Cells in the third column will always be nested temporally
# within cells of the second column. Etc...
# The last column is this list is the innermost nested column.
nested_columns = %w[]

# Sequential columns lists columms that should be printed on separate rows.
# If there is at least one nested_column specified, cells from the sequential
# columns will be printed only if they are nested inside the innermost nested cell.
sequential_columns = %w[cond place motorbout sitassess]

# Linked columns allows printing cells using a custom matching function.
linked_columns = %w[linked_col1]

# Specify arbitrary links for linked columns.
# Each linked column must have a function that takes as input:
#   1) list of cells in current row of data
#   2) list of cells in the linked column
# and returns the cell from the linked column that should be printed for this row.
links = {
  'linked_col1' => lambda do |row_cells, col_cells|
    ref_cell = row_cells.find { |x| x.parent == 'motorbout' }
    return ref_cell.nil? ? nil : col_cells.find { |x| x.ordinal == ref_cell.ordinal }
  end
}
blank_value = '' # code to put in for missing cells
delimiter = ','

# Set to true to force a row to be printed for each innermost-nested cell.
# Default behavior is to skip nested cells that don't have any data for sequential cells.
ensure_rows_per_nested_cell = true

## Body
require 'Datavyu_API.rb'

# Simple method to print nested columns.
# Returns a list of list where the inner list is a row of cells corresponding to a line of data to print out.
def nested_print(*columns)
  columns.map!{ |x| get_column(x) if x.class == ''.class }

  return nested_print_helper(columns, [], [])
end

# Recursive method to add
def nested_print_helper(columns, row_cells, table)
  col = columns.first

  if col.nil?
    table << row_cells
    return table
  end

  cells = col.cells
  oc = row_cells.last
  cells = cells.select{ |x| oc.contains(x) } unless oc.nil?

  if cells.empty?
    table << row_cells
    return table
  end

  cells.each do |cell|
    table = nested_print_helper(columns[1..-1], row_cells + [cell], table)
  end

  return table
end

data = []
# Header order is: static, bound, nested, sequential
header = (static_columns + linked_columns + nested_columns + sequential_columns).map do |colname|
  code_map[colname].map { |codename| "#{colname}_#{codename}" }
end
header.flatten!
data << header.join(delimiter)

# Init arrays of default values.
default_data = {}
code_map.each_pair { |k, v| default_data[k] = [blank_value] * v.size }

input_path = File.expand_path(input_folder)
infiles = Dir.chdir(input_path) { Dir.glob('*.opf') }
infiles.each do |infile|
  $db, $pj = load_db(File.join(input_path, infile))
  puts "Printing #{infile}..."

  columns = {}
  code_map.keys.each { |x| columns[x] = get_column(x) }

  # Get static data from first cells.
  static_data = static_columns.map do |colname|
    col = columns[colname]
    cell = col.cells.first
    raise "Can't find cell in #{col}" if cell.nil? # static columns must contain cell
    cell.get_codes(code_map[colname])
  end
  static_data.flatten!

  # Iterate over cells of innermost-nested column.
  if nested_columns.empty?
    inner_data = []
    outer_data = []

    # Iterate over sequential columns.
    rows_added = 0
    sequential_columns.each do |scol|
      # Iterate over sequential cells.
      seq_cells = columns[scol].cells
      seq_cells.each do |scell|
        # Reset data hash so values are not carried over.
        seq_data = default_data.select { |k, _v| sequential_columns.include?(k) }
        linked_data = default_data.select { |k, _v| linked_columns.include?(k) }

        seq_data[scol] = scell.get_codes(code_map[scol])

        # Get data from bound/linked columns
        linked_columns.each do |bcol|
          rule = links[bcol]
          bcell = rule.call([scell], columns[bcol].cells)
          linked_data[bcol] = bcell.get_codes(code_map[bcol]) unless bcell.nil?
        end

        row = static_data + linked_data.values.flatten + outer_data + inner_data + seq_data.values.flatten
        data << row.join(delimiter)

        rows_added += 1
      end
    end
  else
    # Get rows of cells for nested columns
    nested_table = nested_print(*nested_columns)
    # Iterate over the cell rows
    nested_table.each do |nested_row|
      # Fill out nested data by fetching the code values from the cells in each row
      nested_data = nested_row.zip(nested_columns).map do |cell, colname|
        if cell.nil?
          default_data[colname]
        else
          cell.get_codes(code_map[colname])
        end
      end.flatten

      # The innermost cell is in the column at the end of the nested columns list
      innermost_cell = nested_row.last

      # Init blank data hash so that data for this column is placed properly.
      seq_data = default_data.select { |k, _v| sequential_columns.include?(k) }
      linked_data = default_data.select { |k, _v| linked_columns.include?(k) }

      # Iterate over sequential columns.
      rows_added = 0
      sequential_columns.each do |scol|
        # Iterate over sequential cells nested inside inner cell.
        seq_cells = columns[scol].cells.select { |x| innermost_cell.contains(x) }
        seq_cells.each do |scell|
          # Reset data hash so values are not carried over.
          seq_data = default_data.select { |k, _v| sequential_columns.include?(k) }
          linked_data = default_data.select { |k, _v| linked_columns.include?(k) }

          seq_data[scol] = scell.get_codes(code_map[scol])

          # Get data from bound/linked columns
          linked_columns.each do |bcol|
            rule = links[bcol]
            bcell = rule.call(outer_cells + [innermost_cell, scell], columns[bcol].cells)
            linked_data[bcol] = bcell.get_codes(code_map[bcol]) unless bcell.nil?
          end

          row = static_data + linked_data.values.flatten + nested_data+ seq_data.values.flatten
          data << row.join(delimiter)

          rows_added += 1
        end
      end

      # Edge case for no nested sequential cell(s).
      next unless rows_added == 0 && ensure_rows_per_nested_cell

      row = static_data + linked_data.values.flatten + nested_data + seq_data.values.flatten
      data << row.join(delimiter)

      rows_added += 1
    end
  end
end

puts 'Writing data to file...'
outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data
outfile.close

puts 'Finished.'

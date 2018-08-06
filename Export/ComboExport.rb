# Print single-cell columns "T" as repeated columns for file.
# Iterate over nested cells.
# For each nested cell "N", iterate over list of "sequential columns" and
# print rows of data for each cell "S" in that column nested inside "N".
# For example (Ci is the ith code in the cell):
# row1 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, S1C1, S1C2, <blank>, <blank>
# row2 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, S1C1, S1C2, <blank>, <blank>
# row3 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, <blank>, <blank>, S2C1, S2C2

## Parameters
input_folder = '~/Desktop/Datavyu'
output_file = '~/Desktop/Data.csv'
code_map = {
  'id' => %w[study region agegrp id sex tdate bdate],
  'cond' => %w[ordinal onset offset task],
  'place' => %w[ordinal onset offset clothes leg],
  'motorbout' => %w[ordinal onset offset none tri sit belly hk_hf bumshuf stand cruise walk],
  'sitassess' => %w[ordinal onset offset sittype sitend],
  'linked_col1' => %w[ordinal onset offset]
}
static_columns = %w[id]
nested_columns = %w[]
sequential_columns = %w[cond place motorbout sitassess]
linked_columns = %w[linked_col1 linked_col2]
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
      # Reset data hash so values are not carried over.
      seq_data = default_data.select { |k, _v| sequential_columns.include?(k) }
      linked_data = default_data.select { |k, _v| linked_columns.include?(k) }

      # Iterate over sequential cells.
      seq_cells = columns[scol].cells
      seq_cells.each do |scell|
        seq_data[scol] = scell.get_codes(code_map[scol])

        row = static_data + linked_data.values.flatten + outer_data + inner_data + seq_data.values.flatten
        data << row.join(',')

        rows_added += 1
      end
    end
  else

    inner_col = nested_columns.last
    outer_cols = nested_columns[0..-2]
    columns[inner_col].cells.each do |icell|
      inner_data = icell.get_codes(code_map[inner_col])

      outer_cells = outer_cols.map do |ocol|
        ocell = columns[ocol].cells.find { |x| x.contains(icell) }
        raise "Can't find nesting cell in column #{ocol} for cell #{icell.ordinal} in column #{inner_col}." if ocell.nil?
        ocell
      end
      outer_data = outer_cells.empty? ? [] : outer_cells.map { |x| x.get_codes(code_map[ocol]) }.flatten!

      # Init blank data hash so that data for this column is placed properly.
      seq_data = default_data.select { |k, _v| sequential_columns.include?(k) }
      linked_data = default_data.select { |k, _v| linked_columns.include?(k) }

      # Iterate over sequential columns.
      rows_added = 0
      sequential_columns.each do |scol|
        # Reset data hash so values are not carried over.
        seq_data = default_data.select { |k, _v| sequential_columns.include?(k) }
        linked_data = default_data.select { |k, _v| linked_columns.include?(k) }

        # Iterate over sequential cells nested inside inner cell.
        seq_cells = columns[scol].cells.select { |x| icell.contains(x) }
        seq_cells.each do |scell|
          seq_data[scol] = scell.get_codes(code_map[scol])

          # Get data from bound/linked columns
          linked_columns.each do |bcol|
            rule = links[bcol]
            bcell = rule.call(outer_cells + [icell, scell], columns[bcol].cells)
            linked_data[bcol] = bcell.get_codes(code_map[bcol]) unless bcell.nil?
          end

          row = static_data + linked_data.values.flatten + outer_data + inner_data + seq_data.values.flatten
          data << row.join(',')

          rows_added += 1
        end
      end

      # Edge case for no nested sequential cell(s).
      next unless rows_added == 0 && ensure_rows_per_nested_cell

      row = static_data + linked_data.values.flatten + outer_data + inner_data + seq_data.values.flatten
      data << row.join(',')

      rows_added += 1
    end
  end
end

puts 'Writing data to file...'
outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data
outfile.close

puts 'Finished.'

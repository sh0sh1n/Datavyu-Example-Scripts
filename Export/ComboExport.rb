# Print single-cell columns "T" as repeated columns for file.
# Iterate over nested cells.
# For each nested cell "N", iterate over list of "sequential columns" and
# print rows of data for each cell "S" in that column nested inside "N".
# For example:
# row1 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, S1C1, S1C2, <blank>, <blank>
# row2 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, S1C1, S1C2, <blank>, <blank>
# row3 : T1C1, T1C2, T2C1, N1C1, N2C1, N2C2, <blank>, <blank>, S2C1, S2C2

## Parameters
input_folder = '~/Desktop/TajikExport'
output_file = '~/Desktop/Culture-Tajik-IDCond.csv'
code_map = {
  'id' => %w(study region agegrp id sex tdate bdate),
  'cond' => %w(ordinal onset offset task),
  'place' => %w(ordinal onset offset  clothes leg torso arm feed rock fuss resist bottom top opaquetop segs seq),
  'motorbout' => %w(ordinal onset offset none tri sit belly hk_hf bumshuf stand cruise walk),
  'sitassess' => %w(ordinal onset offset sittype sitend)
}
static_columns = %w(id)
nested_columns = %w()
sequential_columns = %w(cond diaryrecode place motorbout sitassess)
blank_value = '' # code to put in for missing cells

# Set to true to force a row to be printed for each innermost-nested cell.
# Default behavior is to skip nested cells that don't have any data for sequential cells.
ensure_rows_per_nested_cell = true

## Body
require 'Datavyu_API.rb'

data = []
# Header order is: static, nested, sequential
header = (static_columns + nested_columns + sequential_columns).map do |colname|
  code_map[colname].map{ |codename| "#{colname}_#{codename}" }
end
header.flatten!
data << header.join(',')

# Init arrays of default values.
default_data = {}
code_map.each_pair{ |k, v| default_data[k] = [blank_value] * v.size }

input_path = File.expand_path(input_folder)
infiles = Dir.chdir(input_path){ Dir.glob('*.opf') }

infiles.each do |infile|
  $db, $pj = load_db(File.join(input_path, infile))

  puts "Printing #{infile}..."

  columns = {}
  code_map.keys.each{ |x| columns[x] = get_column(x) }

  # Get static data from first cells.
  static_data = static_columns.map do |colname|
    col = columns[colname]
    cell = col.cells.first
    raise "Can't find cell in #{col}" if cell.nil? # static columns must contain cell

    cell.get_codes(code_map[colname])
  end
  static_data.flatten!

  # Iterate over cells of innermost-nested column.
  if(nested_columns.empty?)
    inner_data = []
    outer_data = []

    # Iterate over sequential columns.
    rows_added = 0
    sequential_columns.each do |scol|
      # Reset data hash so values are not carried over.
      seq_data = default_data.select{ |k, v| sequential_columns.include?(k) }

      # Iterate over sequential cells nested inside inner cell.
      seq_cells = columns[scol].cells
      seq_cells.each do |scell|
        seq_data[scol] = scell.get_codes(code_map[scol])

        row = static_data + outer_data + inner_data + seq_data.values.flatten
        data << row.join(',')
        rows_added += 1
      end
    end
  else
    inner_col = nested_columns.last
    outer_cols = nested_columns[0..-2]
    columns[inner_col].cells.each do |icell|
      inner_data = icell.get_codes(code_map[inner_col])
      outer_data = outer_cols.map do |ocol|
        ocell = columns[ocol].cells.find{ |x| x.contains(icell) }
        raise "Can't find nesting cell in column #{ocol} for cell #{icell.ordinal} in column #{inner_col}." if ocell.nil?
        ocell.get_codes(code_map[ocol])
      end
      outer_data.flatten!

      # Init blank data hash so that data for this column is placed properly.
      seq_data = default_data.select{ |k, v| sequential_columns.include?(k) }

      # Iterate over sequential columns.
      rows_added = 0
      sequential_columns.each do |scol|
        # Reset data hash so values are not carried over.
        seq_data = default_data.select{ |k, v| sequential_columns.include?(k) }

        # Iterate over sequential cells nested inside inner cell.
        seq_cells = columns[scol].cells.select{ |x| icell.contains(x) }
        seq_cells.each do |scell|
          seq_data[scol] = scell.get_codes(code_map[scol])

          row = static_data + outer_data + inner_data + seq_data.values.flatten
          data << row.join(',')
          rows_added += 1
        end
      end

      # Edge case for no nested sequential cell(s).
      if(rows_added == 0 && ensure_rows_per_nested_cell)
        row = static_data + outer_data + inner_data + seq_data.values.flatten
        data << row.join(',')
        rows_added +=1
      end
    end
  end
end

puts "Writing data to file..."
outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data
outfile.close

puts "Finished."

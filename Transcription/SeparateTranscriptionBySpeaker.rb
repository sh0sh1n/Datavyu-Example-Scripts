# Add new coding columns.
# Create empty cells using cells from existing column.

## Parameters
# Define the names and associated codes of new columns to create.
language_codes = %w(content)
new_columns = {
  'parentlanguage' => language_codes,
  'childlanguage' => language_codes
}
# A nested associative array specifying how to copy
# information from an already coded cell to a new cell
# in one of the newly added columns.
# If this parameter is left empty, new columns will be empty.
# Nesting order:
#   source_columns -> source_codes -> code_values -> destination_column -> source_to_destination_code_mapping
# NOTE: destination columns are enforced to be one of the newly created columns defined in new_columns parameter.
copy_rules = {
  'transcribe' => {                     # source column
    'source' => {                       # source code to check
      'm' => {                          # if souce code is this value
        'parentlanguage' => {           # add a cell to this column
          'onset' => 'onset',           # copy onset value
          'offset' => 'offset',         # copy offset value
          'content' => 'content'        # copy content value
        }
      },
      'c' => {
        'childlanguage' => {
          'onset' => 'onset',
          'offset' => 'offset',
          'content' => 'content'
        }
      }
    }
  }
}

# TODO: add post processing rules for newly added columns (e.g., change all onsets by -3000ms)
post_copy_rules = {

}

## Body
require 'Datavyu_API.rb'

# Create new columns and add them to a map
dst_cols = {}
new_columns.each_pair do |name, codes|
  dst_cols[name] = new_column(name, *codes)
end

# Parse copy rules.
copy_rules.each_pair do |source_col, source_codes|
  src_col = get_column(source_col)

  # Iterate over codes.
  source_codes.each_pair do |source_code, source_values|
    # Iterate over values of each code.
    source_values.each_pair do |source_value, dest_cols|
      src_cells = src_col.cells.select{ |x| x.get_code(source_code) == source_value }

      # Iterate over destination columns
      dest_cols.each_pair do |dest_col, code_map|
        dst_col = dst_cols[dest_col]

        # Create a new cell for each source cell.
        src_cells.each do |src_cell|
          ncell = dst_col.new_cell()

          # Iterate over code mappings.
          code_map.each_pair do |s, d|
            ncell.change_code(d, src_cell.get_code(s))
          end
        end
      end
    end
  end
end

# Save new columns to spreadsheet.
dst_cols.values.each{ |x| set_column(x) }

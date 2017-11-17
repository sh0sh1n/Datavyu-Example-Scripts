# Check valid codes in multiple columns.
# Use check_valid_codes3.
# Also does additional checks on timestamps.

## Params
output_file = '~/Desktop/check.txt'
date_format = /\A\d{2}\/\d{2}\/\d{4}\Z/ # dates must be formatted: ##/##/####
integer_format = /\A\d+\Z/ # one or more digits
float_format = /\A\d+\.\d+\Z/ # 1+ digits, a decimal point, 1+ digits

# Associative mapping from column names to mappings from code names to valid values
map = {
  'id' => { # for column id, check following codes
    'testdate' => date_format, # code 'testdate' must conform to the date_format defined above
    'idnum' => /\A\d{3}\Z/, # id number must be exactly 3 digits
    'gender' => %w(m f .), # gender can be one of 3 values
    'birthdate' => date_format,
    'birthweight' => float_format
  }, # end of codes for column 'id'
  'condition' => { # for column 'condition'
    'cond_ab' => %w(a b) # condition can be either 'a' or 'b'
  },
  'trial' => { # for column 'trial'
    'trialnum' => integer_format,
    'result_xyz' => %w(x y z) # result must be one of 3 values
  }
}
## Body
require 'Datavyu_API.rb'
check_valid_codes3(map, output_file)

# Check to make sure cells are nested
# Returns a list of messages for each cell not nested by a higher-order column.
def check_cell_nesting(*columns)
  ret = []
  cols = columns.map{ |x| get_column(x) }
  inner_col = cols.pop
  until cols.empty?
    outer_col = cols.pop
    inner_col.cells.each do |ic|
      unless outer_col.cells.any?{ |oc| oc.contains(ic) }
        ret << "#{inner_col.name} cell #{ic.ordinal} not contained by cell in #{outer_col.name}"
      end
    end
    inner_col = outer_col
  end
  return ret
end

errors = []
errors += check_cell_nesting('id', 'condition', 'trial')
puts errors

unless output_file.nil? || output_file == ''
  outpath = File.expand_path(output_file)
  outfile = File.open(outpath, 'a+')
  outfile.puts errors
end

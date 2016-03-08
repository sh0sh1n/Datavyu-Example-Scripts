# Import data from plaintext file.

## Params
input_file = '~/Desktop/data.csv'
delimiter = ','
start_row = 1 # Row to start reading data from; first line is row 1

# Denote how columns from the input file will be represented in the datavyu spreadsheet
# This is a nested associative array.
# The outer key is the name of column.
# The inner keys are names of codes, and the values for the inner keys are the indices of input
# columns containing the values for the code. The first column of the input is column 1.
code_map = {
  'id' => { # id data starts at column 5
    'onset' => 5,
    'offset' => 6,
    'study' => 7,
    'trialdate' => 8,
    'subjectnum' => 9,
    'birthdate' => 10,
    'gender' => 11
  },
  'condition' => { # condition data is in column 12
    'ordinal' => 12,
    'onset' => 13,
    'offset' => 14,
    'cond' => 15
  },
  'trial' => {  # trial data starts at column 16
    'ordinal' => 16,
    'onset' => 17,
    'offset' => 18,
    'trialnum' => 19,
    'outcome' => 20
  }
}

## Body
require 'Datavyu_API.rb'
begin
  # Open input file for read
  infile = File.open(File.expand_path(input_file), 'r')

  # Set up spreadsheet with columns from code_map
  columns = {}
  code_map.each_pair do |column_name, pairs|
    codes = pairs.keys
    columns[column_name] = createVariable(column_name, *(codes - ['ordinal', 'onset', 'offset']))
  end

  # Init struct to keep track of data
  prev_data = {}
  code_map.keys.each{ |x| prev_data[x] = nil }

  # Read lines from the input file and add data
  infile.readlines.each_with_index do |line, idx|
    tokens = line.split(delimiter)

    # Group data by column
    current_data = {}
    code_map.each_pair do |column_name, pairs|
      values = pairs.values.map{ |i| tokens[i-1] }
      current_data[column_name] = values

      # Make new cell if current data does not match previous data
      if values != prev_data[column_name]
        ncell = columns[column_name].make_new_cell
        pairs.each_pair{ |c, i| ncell.change_arg(c, tokens[i-1]) }
      end
    end

    prev_data = current_data
  end

  columns.values.each{ |x| setVariable(x) }
end

# Import data from plaintext file.

## Params
input_file = '~/Desktop/data.csv'
delimiter = ','
start_row = 2 # Row to start reading data from; first line is row 1

# Denote how columns from the input file will be represented in the datavyu spreadsheet
# This is a nested associative array.
# The outer key is the name of column.
# The inner keys are names of codes, and the values for the inner keys are the indices of input
# columns containing the values for the code. The first column of the input is column 1.
code_map{
  'id' => {
    'study' => 5, # id data starts at column 5
    'trialdate' => 6,
    'subjectnum' => 7,
    'birthdate' => 8,
    'gender' => 9
  },
  'condition' => {
    'cond' => 12 # condition data is in column 12
  },
  'trial' => {
    'trialnum' => 15, # trial data starts at column 16
    'outcome' => 16
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
    columns[column_name] = new_column(column_name, *codes)
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

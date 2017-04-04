# Check valid codes in multiple columns.
# Use check_valid_codes2 since it supports regular expressions.

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
    'gender' => ['m', 'f', '.'], # gender can be one of 3 values
    'birthdate' => date_format,
    'birthweight' => float_format
  }, # end of codes for column 'id'
  'condition' => { # for column 'condition'
    'cond_ab' => ['a', 'b'] # condition can be either 'a' or 'b'
  },
  'trial' => { # for column 'trial'
    'trialnum' => integer_format
    'result_xyz' => ['x', 'y', 'z'] # result must be one of 3 values
  }
}
## Body
require 'Datavyu_API.rb'
check_valid_codes2(map, output_file)

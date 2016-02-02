# Check valid codes in multiple columns.
# Use checkValidCodes2 since it supports regular expressions.

## Params
date_format = /\A\d{2}\/\d{2}\/\d{4}\Z/ # dates must be formatted: ##/##/##
# Associative mapping from column names to mappings from code names to valid values
map = {
  'id' => {
    'testdate' => date_format,
    'idnum' => /\A\d{3}\Z/, # id number must be exactly 3 digits
    'gender' => ['m', 'f', '.'], # gender can be one of 3 values
    'birthdate' => date_format
  },
  'condition' => {
    'cond_ab' => ['a', 'b'] # condition can be either 'a' or 'b'
  },
  'trial' => {
    'trialnum' => /\A\d+\Z/, # trial number must be one or more digits
    'result_xyz' => ['x', 'y', 'z'] # result must be one of 3 values
  }
}
## Body
checkValidCodes2(map, '~/Desktop/Feb1/check.txt')

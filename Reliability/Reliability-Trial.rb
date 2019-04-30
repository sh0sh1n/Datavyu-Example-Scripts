# Checks reliability on columns trial and rel_trial using code "trialnum" as matching key.

## Params
primary_column_name = 'trial'
reliability_column_name = 'rel_trial'
matching_code = 'trialnum'
tolerance_ms = 100
output_file = '~/Desktop/Relcheck.txt'

## Methods
require 'Datavyu_API.rb'

## Body
begin
  # Convert relative path and symbols to fully qualified path
  output_file = File.expand_path(output_file)

  # Check argument example
  # Parameters: 
  #   - primary column: name of primary coder's column
  #   - reliability column: name of reliability coder's column
  #   - matching_code: code to pair up observations (cells) between the two columns, e.g., "onset" time
  #   - tolerance_ms: maximum difference between primary times and rel times that is OK, in milliseconds
  #   - output file: file to write disagreements to; use "" for no output file
  check_reliability(primary_column_name, reliability_column_name, matching_code, tolerance_ms, output_file)

end

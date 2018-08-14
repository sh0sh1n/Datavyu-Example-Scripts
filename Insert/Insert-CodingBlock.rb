# Insert coding block(s)

## Parameters
block_col_name = 'my_new_coding_block'
block_col_codes = %w[first_code second_code]
start_time = 0
duration = 60 * 1000

## Body
require 'Datavyu_API.rb'

ncol = new_column(block_col_name, *block_col_codes)
ncell = ncol.new_cell
ncell.onset = start_time
ncell.offset = ncell.onset + duration

set_column(ncol)

# Driver script for transfer_columns function.

## Parameters
source_file = '~/Desktop/Datavyu/file1.opf' # set to '' to transfer FROM currently open spreadsheet
destination_file = '~/Desktop/Datavyu/file2.opf' # set to '' to transfer TO currently open spreadsheet
columns_to_copy = %w(column1 column2 column3) # list of columns to copy
delete_transferred_columns = false # if true, deletes the columns in source file

## Body
require 'Datavyu_API.rb'
transfer_columns(source_file, destination_file, false, columns_to_copy)

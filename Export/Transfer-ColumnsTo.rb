# Script to move columns from open spreadsheet to another.
# Search for matching file using filename.

## Parameters
datavyu_folder = '~/Desktop/Datavyu' # folder with datavyu files
columns_to_transfer = %w(column1 column2 column3)

## Body
require 'Datavyu_API.rb'

# Find the matching datavyu file for this spreadsheet.
curr_file = $db.getName()

datavyu_path = File.expand_path(datavyu_folder)
datavyu_files = get_datavyu_files_from(datavyu_path)
match_file = datavyu_files.find{ |x| x == curr_file }

raise "No matching file found!" if match_file.nil?
puts "Found matching file: #{match_file}"
puts
puts "Transferring columns: #{columns_to_transfer.join(',')}"
transfer_columns('', File.join(datavyu_path, match_file), false, *columns_to_transfer)

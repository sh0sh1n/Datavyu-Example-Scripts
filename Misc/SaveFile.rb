# Save this file.
# Use this as a workaround for bug introduced in Datavyu 1.3.6 which causes
# Datavyu to not save files properly.

## Parameters
output_folder = '~/Desktop'

## Body
require 'Datavyu_API.rb'

name = $db.getName()

outpath = File.join(File.expand_path(output_folder), name.gsub('.opf', '_saved_by_script.opf'))
save_db(outpath)
puts "File saved as #{outpath}."

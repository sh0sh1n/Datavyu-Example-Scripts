# Import columns from another Datavyu file.
# Find the other file by matching filename prefix.
# e.g. StudyXParticipantY_Coder1 matches StudyXParticipantY_Coder2

## Parameters
input_folder = '~/Desktop/Datavyu'
columns_to_import = %w(col1 col2 col3)

# Use this to find paired file.
# Files are matches if everything before the last underscore match.
# Use this to find paired file.
# Files are matches if everything before the last underscore match.
# match_function = lambda{ |x, y| x.split('_')[0..-2].join() == y.split('_')[0..-2].join() } # matches AAA_BBB_CCC.opf with AAA_BBB_DDD.opf
match_function = lambda{ |x, y| x.gsub('.opf', '') == y.split('_')[0..-2].join('_') } # matches AAA_BBB.opf with AAA_BBB_CCC.opf

## Body
require 'Datavyu_API.rb'

current_filename = $db.getName()

# Get names of Datavyu files in the input folder.
inpath = File.expand_path(input_folder)
infiles = get_datavyu_files_from(inpath)

# Remove open spreadsheet from list (so we don't match with ourself)
infiles.reject!{ |x| x == current_filename }

match_filename = infiles.find{ |x| match_function.call(current_filename, x) }

if match_filename.nil?
  puts "Could not find matching file for #{current_filename}. Exiting."
  return
end

transfer_columns(File.join(inpath, match_filename), '', false, *columns_to_import)

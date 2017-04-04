# Print codes from cells in Trial column with durations of each cell.

## Parameters
input_dir = '~/Desktop/Datavyu' # Folder containing Datavyu files to print
output_file = '~/Desktop/TrialDurations.csv' # Location of output file

## Body
require 'Datavyu_API.rb'

data = []
# Add header as first row of data
header = %w(ordinal duration condition result)
data << header.join(',')

# Get list of Datavyu files to print
inpath = File.expand_path(input_dir)
infiles = get_datavyu_files_from(inpath)

# Iterate over each Datavyu file
infiles.each do |infile|
  load_db(File.join(inpath, infile)) # load the file

  trial_col = get_column('Trial') # get trial column
  trial_cells = trial_col.cells # get trial cells

  # Iterate over trial cells
  trial_cells.each do |tc|
    row = [tc.ordinal tc.duration tc.condition tc.result] # get values for row of data
    data << row.join(',') # add row of data
  end
end

# Output to file.
outpath = File.expand_path(output_file)
outfile = File.open(outpath, 'w+')
outfile.puts data
outfile.close

## This script is designed to export all values for a single code of a single
## column. In this case, we coded the onset of each frame when a sensor was
## tapped (producing a spike in the signal). By additionally labelling the
## signal spike times, you can synchronize sensor times with video times by
## running a linear regression on corresponding timepoints and using that linear
## model to convert between the two.

## Parameters
# name of column whose code you want to export
col_export_name = 'taps_01793'
# strip sensor name from column name
sensor_name = col_export_name.split('_')[1]
# name of code within column whose arguments you want to export
code_export_name = 'onset'
# name of exported file and where you want to write it
outfile = '~/Desktop/' + 'taptimes_' + sensor_name + '.csv'

## Body
require 'Datavyu_API.rb'
require 'csv'

# fetch the column
col_export = get_column(col_export_name)
# initialize header as colname_codename (e.g. tap_onset)
header = [col_export_name + '_' + code_export_name]
# initialize array to store code values in
data = []
# append header to data
data << header.to_csv

# loop through each cell in column and append the code value
col_export.cells.each do |c|
  data << [c.onset].to_csv
end

# write the file to CSV
outfile = File.open(File.expand_path(outfile),'w+')
outfile.puts data
outfile.close

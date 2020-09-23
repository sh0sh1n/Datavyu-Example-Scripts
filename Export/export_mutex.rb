# writes a CSV file with a column for each code from the two columns being
# mutexed plus the onset and offset of each mutex cell.
# see https://databrary.github.io/datavyu-docs/top-level-namespace.html#create_mutually_exclusive-instance_method
# for definition of what a mutexed column is
# rows are instances of each cell in mutex column.
# very useful if you are interested in analyzing co-occurrences or individual
# occurrences of events from two columns
# does this for every file in a folder and also includes the filename
# associated with each row (from which subject ID can be derived)

## Parameters

# folder with datavyu files you want to export
input_folder = '~/Desktop/Datavyu'
# names of columns from which to create a mutex column
colname1 = 'trial'
colname2 = 'lookingtime2'
# name csv of file to write to desktop
output_folder = '~/Desktop/mutex.csv'

## Body
require 'Datavyu_API.rb'

# name the mutex column after the two columns from which it was created
mutexname = 'mutex_' + colname1 + '_' + colname2

# initialize data for export
data = []

# get list of all opf files in datavyu folder
input_path = File.expand_path(input_folder)
infiles = Dir.chdir(input_path) { Dir.glob('*.opf') }

# loop over sorted files
infiles.sort.each_with_index do |infile, i|
  # load current database
  $db, $pj = load_db(File.join(input_path,infile))
  puts "Exporting #{infile}..."
  # create the mutex column
  mutex = create_mutually_exclusive(mutexname,colname1,colname2)
  # if it's the first file, create the header
  if i == 0
    # initialize header to include filename, all mutex codes + onset/offset of each mutex cell
    header = ['filename', mutex.cells.first.arglist, 'onset', 'offset'].flatten!
    # add header to data
    data << header.join(',')
  end
  # loop through mutex cells and write a line of data for each
  mutex.cells.each do |c|
    # write filename + all the code values for current + onset/offset
    line = [infile, c.arglist.map{ |a| c.get_code(a) }, c.onset, c.offset].flatten!
    # add line to data
    data << line.join(',')
  end
end

# write data to file
outpath = File.expand_path(output_folder)
outfile = File.open(outpath, "w+")
outfile.puts data
outfile.close

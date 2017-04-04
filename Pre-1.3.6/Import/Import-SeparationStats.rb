# params
verbose = 1
input_folder = '~/Desktop/Data'
sepstats_filename_suffix = '_sepstats.csv'
sepstats_column_name = 'mb_separation_stats'
sepstats_codes = %w(overall_lt50 overall_lt100 overall_min overall_max overall_mean
  measured_lt50 measured_lt100 measured_min measured_max measured_mean
  estimated_lt50 estimated_lt100 estimated_min estimated_max estimated_mean)

# Import exported data from Matlab into Natural Locomotion Datavyu files.
require 'Datavyu_API.rb'

begin
  # Do nothing unless file has digitizing columns
  if (get_column_list() & ['digiframesBL', 'digiframesBR']).empty?
    puts "No digitizing columns found. Exiting."
    return
  end

  # Generate the matching csv filename for this spreadsheet.
  myName = $db.getName()
  csvName = myName.gsub('.opf',sepstats_filename_suffix)

  # Load file for reading from input directory
  # puts "Opening file #{csvName}" if verbose > 0
  input_folder = File.expand_path(input_folder)
  sep_filename = Dir.chdir(input_folder) do |dir|
    Dir.glob(File.join('**', '*' + sepstats_filename_suffix)).find do |fn|
      File.basename(fn) == csvName
    end
  end

  raise "No matching CSV file found." if sep_filename.nil?

  puts "Opening file #{sep_filename}" if verbose > 0
  sepfile = File.open(File.join(input_folder,sep_filename), 'r')
  data = sepfile.readlines.first.split(',')

  col_sepstats = createVariable(sepstats_column_name, *sepstats_codes)
  ncell = col_sepstats.make_new_cell
  ncell.argvals = data #cheating
  task_cells = getVariable('task').cells.select{ |x| x.task == 'p'}
  ncell.onset = task_cells.map(&:onset).sort.first
  ncell.offset = task_cells.map(&:offset).sort.last

  setVariable(col_sepstats)
end

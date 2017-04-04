# params
verbose = 1
input_folder = '~/Desktop/Data'

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
  csvName = myName.gsub('.opf','_boutmetrics.csv')

  # Load file for reading from input directory
  puts "Opening file #{csvName}" if verbose > 0
  input_folder = File.expand_path(input_folder)
  mFileName = Dir.chdir(input_folder) do |dir|
    Dir.glob(File.join('**','*_boutmetrics.csv')).find do |fn|
      File.basename(fn) == csvName
    end
  end
  mfile = File.open(File.join(input_folder,mFileName),'r')

  boutMetricColumn = createVariable('bout_metrics', 'distance', 'displacement',
                                    'explored', 'cumul_explored', 'duration', 'curvature', 'sepdistend')
  subjMetricColumn = createVariable('subject_metrics', 'distance', 'displacement',
                                    'explored', 'duration')
  moveColumn = getVariable('stepsDigiB')
  moveCells = moveColumn.cells

  subj_onset = 1e9;
  subj_offset = 0;
  # Go through file row by row
  for line in mfile
    puts line if verbose > 2
    # The following names should match up with the matrix constructed by PathExportAllMetrics2.m
    ordinal, dist, displacement, coverage, explored, duration, curv, sepdistend,
      sum_dist, sum_disp, sum_cov, total_explored, sum_duration = line.split(',')

    # fetch the cell from moveColumn with matching ordinal
    move_cell = moveCells.find{ |x| x.ordinal == ordinal.to_i }

    newcell = boutMetricColumn.make_new_cell()
    newcell.onset = move_cell.onset
    newcell.offset = move_cell.offset
    newcell.change_code('distance', dist)
    newcell.change_code('displacement', displacement)
    newcell.change_code('explored', coverage)
    newcell.change_code('cumul_explored', explored)
    newcell.change_code('duration', duration)
    newcell.change_code('curvature', curv)
    newcell.change_code('sepdistend', sepdistend)

    # gather onset and offset for the subject-level metrics cell
    if newcell.onset<subj_onset
      subj_onset = newcell.onset
    end
    if newcell.offset>subj_offset
      subj_offset = newcell.offset
    end
  end

  # Create a cell for the subject level metrics
  newcell = subjMetricColumn.make_new_cell()
  newcell.onset = subj_onset
  newcell.offset = subj_offset

  newcell.change_code('distance', sum_dist)
  newcell.change_code('displacement', sum_disp)
  newcell.change_code('explored', total_explored)
  newcell.change_code('duration', sum_duration)

  # Save the columns
  puts "Saving columns to spreadsheet" if verbose > 0
  setVariable(boutMetricColumn)
  setVariable(subjMetricColumn)
rescue StandardError => e
  puts e.message
  puts e.backtrace
end

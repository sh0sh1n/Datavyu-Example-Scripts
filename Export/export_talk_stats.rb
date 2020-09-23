## This script will export a csv file with statistics (e.g. total duration)
## computed between every question interval for each talker. There is a
## parameter to determine how

## Parameters

# name of csv file to write data to
output_file = '~/Desktop/talk_stats.csv'
# if set to true, cells that overlap sections of task_timing will contribute
# only for the duration that they last within that section.
# if set to false, cells will contribute entire duration to section as long as
# they start within that section
chop_cell = false

# talk_transcribe columns code name (must be same for both)
code_name = 'code01'

## Body
require 'Datavyu_API.rb'
require 'csv'

# get column with task timing
task_timing = get_column('task_timing')
# get columns with transcriptions for each talker
talk_transcribe_wall = get_column('talk_transcribe_wall')
talk_transcribe_glass = get_column('talk_transcribe_glass')

# get list of task_timing cells' onsets
task_timing_onset = task_timing.cells.map { |c| c.onset }
# get offset for each talker cell
wall_offset = talk_transcribe_wall.cells.map { |c| c.offset }
glass_offset = talk_transcribe_glass.cells.map { |c| c.offset }
# get list of all offsets
talk_offset = [wall_offset, glass_offset].flatten.sort
# get the experiment offset by taking the max value
exp_offset = talk_offset.last

# make task_bounds column
task_bounds = new_column('task_bounds', %w[question_range])

# populate task_bounds with timing info and question range
count = 0
task_timing_onset.each do |x|
  lower_bound = x
  lower_question = task_timing.cells.select{ |c| c.onset==x }.first.question
  # upper bound is next onset unless last cell in which case it's end of exp.
  upper_bound = task_timing_onset.select { |y| y > x }.first
  if upper_bound.nil?
    upper_bound = exp_offset + 1
    upper_question = 'end'
  else
    upper_question = task_timing.cells.select{ |c|
      c.onset==upper_bound }.first.question
  end
  # make cell in task_bounds column
  ncell = task_bounds.new_cell()
  ncell.onset = lower_bound
  ncell.offset = upper_bound - 1
  ncell.question_range = lower_question + ', ' + upper_question
end
set_column('task_bounds', task_bounds)

# initialize header for csv data output
header = %w[question_range task_onset task_offset wall_dur_ms glass_dur_ms
  wall_numword glass_numword]

delimiter = ','
data = CSV.new(String.new, write_headers: true, headers: header,
  col_sep: delimiter)

# create mutexes for chopping cells
mutex_wall = create_mutually_exclusive('mutex_wall', 'task_bounds',
  'talk_transcribe_wall')
mutex_glass = create_mutually_exclusive('mutex_glass', 'task_bounds',
  'talk_transcribe_glass')

# loop through task_bounds cells and export stats
task_bounds.cells.each do |tcell|
  # get the time range defined by questions
  range = [tcell.onset, tcell.offset]
  # initialize variables for section
  if chop_cell
    # chop them by selecting the mutex cells where their arguments are not empty
    wall_cells = mutex_wall.cells.select { |x|
      tcell.contains(x) unless x.get_code('talk_transcribe_wall_ordinal').empty? }
    glass_cells = mutex_glass.cells.select{ |x|
      tcell.contains(x) unless x.get_code('talk_transcribe_glass_ordinal').empty? }
    # fetch transcriptions in each cell
    wall_transcribe = wall_cells.map{ |x|
      x.get_code('talk_transcribe_wall_' + code_name) }
    glass_transcribe = glass_cells.map{ |x|
      x.get_code('talk_transcribe_glass_' + code_name) }
  else
    # choose cells with any overlap whatsoever that started within bounds
    wall_cells = talk_transcribe_wall.cells.select { |x|
      x.overlaps_range(range) && x.onset >= tcell.onset }
    glass_cells = talk_transcribe_glass.cells.select { |x|
      x.overlaps_range(range) && x.onset >= tcell.onset  }
    # fetch transcriptions in each cell
    wall_transcribe = wall_cells.map{ |c| c.get_code(code_name) }
    glass_transcribe = glass_cells.map{ |c| c.get_code(code_name) }
  end

  # sum up durations of cells to get total duration within bounds
  wall_dur_ms = wall_cells.map{ |x| x.duration }.reduce(:+)
  glass_dur_ms = glass_cells.map{ |x| x.duration }.reduce(:+)

  

  # sum up number of words in each cell to get total number within bounds
  # for now assume number of spaces = number of words
  wall_numword = wall_transcribe.map{ |t| t.split(' ').length }.reduce(:+)
  glass_numword = glass_transcribe.map{ |t| t.split(' ').length }.reduce(:+)

  row = [tcell.question_range, tcell.onset, tcell.offset, wall_dur_ms,
    glass_dur_ms, wall_numword, glass_numword]

  data << row

end

puts 'Writing data to file...'
outfile = File.open(File.expand_path(output_file), 'w+')
outfile.puts data.string
outfile.close

puts 'Finished.'

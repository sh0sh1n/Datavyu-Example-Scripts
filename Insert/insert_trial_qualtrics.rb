## Parameters
# Runs on open DV spreadsheet and populates trial column with qualtrics csv data
# for the current subject
# folder with master qualtrics csv file
qualtrics_folder = '~/Desktop/Qualtrics'

# map names to sex
targetsex_map = { 'g' => 'f', 'w' => 'f', 'b' => 'm', 'm' => 'm' }

# map pictures to stereotypical sex
stereotype_map = { %w[construction cars football superhero firefighter tools
  worms trucks] => 'm',
  %w[makeup laundry princess flowers ballet baby dolls nails] => 'f'
}

## Body
require 'Datavyu_API.rb'
require 'csv'

qualtrics_path = File.expand_path(qualtrics_folder)
# assumes there is just one master csv file in folder (takes first)
qfile = Dir.chdir(qualtrics_path) { Dir.glob('*.csv') }.first

# get the name of currently open dv file
dv_filename = $db.getName()
# assumes id is all the characters before first underscore of filename
id = dv_filename.split('_')[0]

# fetch the task column
task = get_column('task')

# initialize trial column for storing qualtrics events and times
trial = new_column('trial', %w[trial targetsex_mfn stereotype_sex])

# read qualtrics table from csv file
qtable = CSV.read(File.join(qualtrics_path, qfile))
# extract the header and data from the table
header = qtable[0]
# loop over rows of data skipping the header
for line in qtable[1..-1]
  # store data from row if it corresponds to current id
  if line[header.index('ID')] == id
    data = line
  end
end

# get onset of task in seconds for qualtrics data
qt0 = data[header.index('intro_onset')].to_i

# get onset of task in milliseconds for datavyu spreadsheet
dt0 = task.cells.select{ |c| c.task == 'p' }.first.onset.to_i

# get picture entries from header
header_trial = header.select{ |x| x.include?('onset') || x.include?('offset') }
# reject intro and end
header_trial.reject!{ |x| x.include?('intro') || x.include?('end') }

# strip header entry to get the name of the picuture
trial_code = header_trial.map{ |x| x.split('_')[0] }
# just take unique values to avoid repeats for onset/offset
trial_code = trial_code.uniq

# loop through trial pictures
trial_code.each do |tc|

  # get onset and offset of trial
  trial_onset = header_trial.select{ |x| x.include?(tc) && x.include?('onset') }
  trial_offset = header_trial.select{ |x| x.include?(tc) && x.include?('offset') }

  # reject blank entries
  trial_onset.reject!{ |x| data[header.index(x)].nil? }
  trial_offset.reject!{ |x| data[header.index(x)].nil? }

  # create cell in column trial for each picture
  trial_onset.each_with_index{ |x,i|

    # get onset and offset relative to task start
    dq_onset = data[header.index(x)].to_i - qt0
    dq_offset = data[header.index(trial_offset[i])].to_i - qt0

    # create cell and store onset/offset in milliseconds
    ncell = trial.new_cell()
    ncell.onset = dt0 + dq_onset*1000
    ncell.offset = dt0 + dq_offset*1000 - 1

    # store targetsex and stereotype sex of picture
    ncell.trial = tc
    ncell.targetsex_mfn = targetsex_map[trial_onset.first.split('_')[1]]
    ncell.stereotype_sex = stereotype_map[stereotype_map.keys.select{
      |k| k.include?(tc) }.first] }
end

# update spreadsheet with new trial column
set_column('trial', trial)

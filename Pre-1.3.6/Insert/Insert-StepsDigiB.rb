###################################################################################
# Script to add coding columns for selecting digitizing frames from SOM.
# Creates three new columns.
#  stepsDigiB - cloned cells from babymovement (babys movement)
#  digiframesBL - coding column for infant left foot
#  digiframesBR - coding column for infant right foot
# Works on open spreadsheet (batchable).
# #################################################################################
require 'Datavyu_API.rb'

begin
  # Parameters
  valid_locomotion_codes = ['w','c','h','b']
  step_threshold = 1

  columns = getVariableList()
  # Check for existing 'digiframesB' column.  If it exists rename to 'digiframesBL'
  puts("Creating digiframesBL...")
  if columns.include?('digiframesB')
    setVariable('digiframesBL', getVariable('digiframesB'))
    deleteVariable('digiframesB')
  elsif columns.include?('digiframesBL') # Don't overwrite existing digiframesBL column
    puts "WARNING: Refusing to overwrite existing digiframesBL column."
  else  # Create new digiframesBL column
    setVariable(createNewVariable('digiframesBL', 'on'))
  end

  # Create the digiframesBR column unless it already exists
  puts "Creating digiframesBR..."
  if columns.include?('digiframesBR')
    puts "WARNING: Refusing to overwrite existing digiframesBR column."
  else
    setVariable(createNewVariable('digiframesBR', 'on'))
  end

  stepsDigiB = createNewVariable("stepsDigiB",'locomotion','steps')
  movcol = getVariable('babymovement')

  # Merge movement cells based on bmvord2

  # Loop over cells and create cells to code on
  puts("Creating stepsDigiB cells...")
  movcol.cells.group_by{ |x| x.ordinal}.each_pair do |ord, cells|
    locomotion = cells.first.locomotion
    steps = cells.map{ |x| x.steps.to_i }.reduce(:+)
    next if not (valid_locomotion_codes.include?(locomotion) && steps >= step_threshold)
  	ncell = stepsDigiB.make_new_cell()
  	ncell.onset = cells.first.onset
  	ncell.offset = cells.last.offset
  	ncell.steps = steps
  	ncell.locomotion = locomotion
  end

  setVariable("stepsDigiB",stepsDigiB)

  puts("Done.\n\n")

rescue StandardError => e
    puts e.message
    puts e.stacktrace
end

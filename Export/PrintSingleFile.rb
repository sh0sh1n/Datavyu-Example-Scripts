# Print data from currently open spreadsheet to file.

## Params
output_file = '~/Desktop/output.csv'
delimiter = ',' # separator between data
print_header = true

# Set up the arguments that we want to print for each variable.
# These must be exactly the argument names from Datavyu but with all
# punctuation removed and made into all lowercase.
# So Reach.Hand becomes reachhand
# Test.date becomes testdate
# Make a list for each column.
id_order = ["study", "name", "tdate", "bdate", "sex", "sess", "ttrials"]
cond_order = ["onset", "offset", "condition"]
trial_order = ["trialnum", "onset", "offset", "unit", "turndir", "raisinreachhand", "raisinmissreach", "raisinclutchhand", "raisingrasphand", "raisinmissgrasp", "toyreachhand", "toymissreach", "toyclutchhand", "toygrasphand", "toymissgrasp"]

## Body
raise "This script requires Datavyu version 1.3.5 or higher." unless checkDatavyuVersion('v:1.3.5')

begin
  # Init an empty list to store lines of data
  data = []

  # Put the header together and add as first item to our data.
  if(print_header)
    header = id_order + cond_order + trial_order
    data << header.join(delimiter)
  end

  # Get the variables we want to print from the loaded file
  id = getVariable("id")
  cond = getVariable("cond")
  trial = getVariable("trial")

  # Loop over the cells in ID
  for idcell in id.cells
    # Get id codes frome this id cell
    idCodes = idcell.getArgs(*id_order)

    # Loop over the cells in condition which are contained by this idcell
    for condcell in cond.cells.select{ |condcell| idcell.contains(condcell) }
      # Get condition codes from this condition cell
      condCodes = condcell.getArgs(*cond_order)

      # Loop over the trial cells contained by this condcell
      for tcell in trial.cells.select{ |trialcell| condcell.contains(trialcell) }
        # Get trial codes from this trial cell
        trialCodes = tcell.getArgs(*trial_order)

        # Combine codes from each column into one list
        row = idCodes + condCodes + trialCodes

        # Join the list together using delimiter and add into data
        data << row.join(delimiter)
      end
    end
  end

  # Open the file we want to print the output to
  # ~ is a shortcut for the current user's home directory, ~/Desktop/ will put it
  # on your desktop
  output_file = File.new(File.expand_path(output_file), 'w')

  # Write out data to file
  puts "Writing to file..."
  output_file.puts data
  output_file.close

  puts "FINISHED"
end

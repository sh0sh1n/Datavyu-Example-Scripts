# Print data from all Datavyu files in a directory (same spreadhsheet layout).

## Params
# Which directory do we want to load files from?
input_folder = "~/Desktop/input"
output_file = "~/Desktop/output.txt"

# Set up the arguments that we want to print for each variable.
# These must be exactly the argument names from Datavyu but with all
# punctuation removed and made into all lowercase.
# So Reach.Hand becomes reachhand
# Test.date becomes testdate
# etc
# Make a list for each column.
id_order = ["study", "name", "tdate", "bdate", "sex", "sess", "ttrials"]
cond_order = ["onset", "offset", "condition"]
trial_order = ["trialnum", "onset", "offset", "unit", "turndir", "raisinreachhand", "raisinmissreach", "raisinclutchhand", "raisingrasphand", "raisinmissgrasp", "toyreachhand", "toymissreach", "toyclutchhand", "toygrasphand", "toymissgrasp"]

## Body
require 'Datavyu_API.rb'

begin
  #$debug=true

  # Obtain a listing of files in the directory
  static_dir = Dir.new(File.expand_path(input_folder))

  # Open the file we want to print the output to
  # ~ is a shortcut for the current user's home directory, ~/Desktop/ will put it
  # on your desktop
  output_file = File.new(File.expand_path(output_file), 'w')

  # Put the header together.
  header = id_order + cond_order + trial_order
  for h in header
    output_file.write(h + "\t")
  end
  output_file.write("\n")


  # Loop over all Datavyu files (files in directory that end with ".opf" )
  for file in static_dir.select{ |file| file.end_with?('.opf') }
    puts "Opening " + file
    $db, $pj = loadDB(File.join(static_dir, file))

    # Get the variables we want to print from the loaded file
    id = getVariable("id")
    cond = getVariable("cond")
    trial = getVariable("trial")

    # Loop over the cells in ID
    for idcell in id.cells
      # Loop over the cells in condition which are contained by this idcell
      for condcell in cond.cells.select{ |condcell| idcell.contains(condcell) }
        # Loop over the trial cells contained by this condcell
        for tcell in trial.cells.select{ |trialcell| condcell.contains(trialcell) }
          # Print this ID's information
          print_args(idcell, output_file, id_order)
          # Print this Condition cell's information
          print_args(condcell, output_file, cond_order)
          # Print this Trial's information
          print_args(tcell, output_file, trial_order)
          # And write a newline to the output file so the next cell
          # is on its own line
          output_file.write("\n")
        end
      end
    end
  end

  puts "FINISHED"
end

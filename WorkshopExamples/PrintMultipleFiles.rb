require 'Datavyu_API.rb'

def getCellFromTime(col, time)
  for cell in col.cells
    if cell.onset <= time and cell.offset >= time
      return cell
    end
  end
  return nil
end

def printCellArgs(cell)
  s = Array.new
  s << cell.ordinal.to_s
  s << cell.onset.to_s
  s << cell.offset.to_s
  for arg in cell.arglist
    s << cell.get_arg(arg)
  end
  return s
end

begin
    #$debug=true

    # Which directory do we want to load files from?
    file_directory = "/Volumes/LABDOCS/StudiesCurrent/DynamicReach-Monkey/OpenSHAPA/static/"

    # Obtain a listing of files in the directory
    static_dir = Dir.new(file_directory)

    # Set up the arguments that we want to print for each variable.
    # These must be exactly the argument names from openshapa but with all
    # punctuation removed and made into all lowercase.
    # So Reach.Hand becomes reachhand
    # Test.date becomes testdate
    # etc
    # This is done by variable.
    id_order = ["study","name","tdate", "bdate", "sex", "sess", "ttrials"]
    cond_order = ["onset", "offset"]
    trial_order = ["trialnum", "onset", "offset", "unit", "turndir", "raisinreachhand", "raisinmissreach", "raisinclutchhand", "raisingrasphand", "raisinmissgrasp", "toyreachhand", "toymissreach", "toyclutchhand", "toygrasphand", "toymissgrasp"]

    # Open the file we want to print the output to
    # ~ is a shortcut for the current user's home directory, ~/Desktop/ will put it
    # on your desktop
    output_file = File.new(File.expand_path("~/Desktop/MB_Static_Output.txt"), 'w')

    # Put the header together.
    header = id_order + cond_order + trial_order
    for h in header
        output_file.write(h + "\t")
    end
    output_file.write("\n")


    # Finally, loop through all of the files and print everything
    for file in static_dir
        if file.include?(".opf")


            # Load the OpenSHAPA file into Ruby
            puts "Opening", file
            $db, $pj = load_db(d + file)
            $pj = nil

            # Get the variables we want to print from the loaded file
            id = getVariable("id")
            cond = getVariable("cond")
            trial = getVariable("trial")

            # Loop over the cells in ID
            for idcell in id.cells
                # Loop over the cells in condition
                for condcell in cond.cells
                    # Make sure that the condition cell is INSIDE OF the ID cell
                    if idcell.onset <= condcell.onset and idcell.offset >= condcell.offset
                        # Loop over the trial cells
                        for tcell in trial.cells
                            # Make sure that the trial cell is INSIDE OF the condition cell
                            if condcell.onset < tcell.onset and condcell.offset >= tcell.offset
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
            end

        end


    end

    puts "FINISHED"



end

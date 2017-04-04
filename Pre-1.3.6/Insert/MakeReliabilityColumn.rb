require 'Datavyu_API.rb'

begin

    # Make rel example
    # Format: "rel column name", "variable to make rel from", "multiple to keep (2 is every other cell)", "carry over argument1", "carry over argument2", ...
    make_rel("rel_trial", "trial", 2, "onset", "offset", "trialnum")

end

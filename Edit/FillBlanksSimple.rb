## Fill in code values for empty codes using other codes' values.
# As a best practice, it is better to have coders fill in values and then use
# a check script to identify impossible combinations of code values and then
# have them review that cell.

require 'Datavyu_API.rb'

# Get trial column
trial_col = get_column('trial')

# Fill in 'outcome' code if 'trialnum' is '.'
trial_col.cells.each do |cell|
  if cell.trialnum == '.'
    cell.outcome = 'x'
  end
end

# Fill in 'outcome' code if 'attention' code is less than 5
trial_col.cells.each do |cell|
  if cell.attention.to_i < 5 # the to_i is needed to convert code value to a number
    cell.outcome = 'x'
  end
end

# Save changes to trial column
set_column(trial_col)

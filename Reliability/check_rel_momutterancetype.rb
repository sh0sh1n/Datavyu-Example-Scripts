## This script matches reliability cells to primary cells based on matching onset
## criterion. Prints the number of reliability cells where all codes did not
## match out of total number of opportunities for agreement as well as % agreement.

## Parameters
# name of primary coder's column
colname_pri = 'momutterancetype'
# name of reliability coder's column
colname_rel = 'momutterancetype_rel'
# name of column to insert with cells for each disagreement between pri & rel
colname_disagree = 'momutterancetype_disagree'
# make a clean copy of primary coder's column
colname_clean = 'momutterancetype_clean'

## Body
require 'Datavyu_API.rb'

# fetch columns from spreadsheet
col_pri = get_column(colname_pri)
col_rel = get_column(colname_rel)
# make clean copy of pri column
col_clean = set_column(colname_clean,get_column(colname_pri))
# initialize disagreement column 
col_disagree = new_column(colname_disagree,'comment')

# initialize counter for number of cells reliability coder has coded
num_rel_code = 0
# initialize counter for number of agreements
num_agree = 0
# loop through primary coder's cells and evaluate agreement based on args of
# reliability cell that matches in onset
col_pri.cells.each do |cp|
  cr = col_rel.cells.select{ |c| c.onset == cp.onset }.first
  # skip if no matching reliability cell found
  next if cr.nil?
  # get list of all code arguments for primary and reliability coders
  pri_args = cp.get_codes(cp.arglist)
  rel_args = cr.get_codes(cr.arglist)
  # skip if reliability coder has not coded this cell yet
  unless rel_args.map{ |a| a.empty? }.all?
    # increment number of agreements if all arguments match
    if pri_args == rel_args
      num_agree += 1
    else
      # otherwise make a disagreement cell
      ncell = col_disagree.new_cell()
      # time-lock disagreement cell to primary coder's cell
      ncell.onset = cp.onset
      ncell.offset = cp.offset
    end
    # increment total number of opportunities for agreement
    num_rel_code += 1
  end
end

# update disagreements in spreadsheet
set_column(colname_disagree,col_disagree)
# print percent agreement rounded to 2 decimal places
perc_agree = 100.0*(num_agree.to_f/num_rel_code.to_f).round(2)
puts "Agreement: #{num_agree}/#{num_rel_code}"
puts "#{perc_agree}%"

# Import reliability coder's column from matching file and check reliability.
# Files are matched using the prefix of the filename; assumes files
# are named with coder's name at end separated from rest of file name by underscore.
# Rest of file name should match between coders.

## Parameters
datavyu_folder = '~/Desktop/Desktop'
pri_column_name = 'trial'
rel_column_name = 'trial'
disagreement_column_name = 'trial_disagreements'
clean_column_name = 'trial_clean'
match_code = 'ordinal'
time_threshold = 100 # leeway in milliseconds to allow for onset/offset

## Body
require '~/scriptrepo/datavyu_api.rb'

# Find the matching datavyu file for this spreadsheet.
curr_file = $db.getName()

datavyu_path = File.expand_path(datavyu_folder)
datavyu_files = get_datavyu_files_from(datavyu_path)
match_file = datavyu_files.reject{ |x| x == curr_file }.find{ |x| x.split('_')[0..-2].join() == curr_file.split('_')[0..-2].join() }

# Get the primary column before it is overwritten
pri_col = get_column(pri_column_name)

# Transfer column from matching file. Load it as the rel column.
backup_db, backup_pj = $db, $pj
$db, $pj = load_db(File.join(datavyu_path, match_file))
# transfer_columns(File.join(datavyu_path, match_file), '', false, pri_column_name)
rel_col = get_column(pri_column_name)
$db, $pj = backup_db, backup_pj

# Save columns with respective names
set_column(pri_column_name, pri_col)
set_column(rel_column_name, rel_col)

# Run check function from API.
check_reliability(pri_col, rel_col, match_code, time_threshold)

# Merge the columns together (to visualize differences)
merge_col = merge_columns(disagreement_column_name, pri_column_name, rel_column_name)

# Remove agreements from merged column. Remove onset/offset disagreements under time_threshold
merge_col.cells.reject! do |cell|
  p_codes = pri_col.arglist.map{ |x| cell.get_code(pri_column_name + '_' + x) }
  r_codes = rel_col.arglist.map{ |x| cell.get_code(rel_column_name + '_' + x) }
  all_agree = pri_col.arglist.all? do |code|
    p_code = cell.get_code(pri_column_name + '_' + code)
    r_code = cell.get_code(rel_column_name + '_' + code)
    p_code == r_code
  end
  uncoded = cell.get_code("#{pri_column_name}_ordinal") == '' || cell.get_code("#{rel_column_name}_ordinal") == ''
  exclude = uncoded && cell.duration < time_threshold
  all_agree || exclude
end

merge_col.add_code('comment')
set_column(merge_col)
set_column(clean_column_name, pri_col)

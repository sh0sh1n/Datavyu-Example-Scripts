## This script does various timing checks including checking for continuity of
## cells (cells account for every frame of video), checking to make sure cells
## are always nested (temporally contained) within other cells, and finally checking
## to make sure some cell always nests (temporally contains) other cells.

##Parameters
cont_col_list = %w[transition transition_clean] #Check to make sure these columns are continuous
nesting_col_name = 'task'
#check to make sure  these columns are nested in task
nested_col_list = %w[transition transition_rel transition_clean location
  location_rel location_clean mhelp mhelp_rel mhelp_clean detailed_posture
  detailed_posture_rel detailed_posture_clean]
#Check the same column for duration
duration_col_list = %w[transition transition_rel transition_clean location
  location_rel location_clean detailed_posture detailed_posture_rel
  detailed_posture_clean]
#check for minimal time in cells
min_time_ms = 500
#mhelp columns
mhelp_col_list = %w[mhelp mhelp_rel mhelp_clean]
mhelp_code = %w(x)
#detailed_posture columns
d_posture_col_list = %w[detailed_posture detailed_posture_rel detailed_posture_clean]
d_posture_code = %w(s k c)

##Body
require 'Datavyu_API.rb'

#First check continuity
puts "Checking for Continuity..."
cont_col_list.each do |col_name|
  col = get_column(col_name)
  col.cells.each do |c|
    next_ordinal = c.ordinal + 1
    c_next = col.cells.select{ |cn| cn.ordinal==next_ordinal }.first
    ##debugging code
    ##p col_name
    ##p c_next.ordinal
    unless c_next.nil? || (c.offset + 1 == c_next.onset)
      puts "Discontinuity at cell #{c.ordinal} in column #{col_name}"
    end
  end
end
puts

#Second check nesting
puts "Checking for Nesting..."
nesting_col = get_column(nesting_col_name)
nesting_cells = nesting_col.cells
nested_col_list.each do |col_name|
  col = get_column(col_name)
  col.cells.each do |c|
    nesting_cell = nesting_cells.select{ |nc| nc.contains(c) }
    if nesting_cell.empty?
      puts "Cell #{c.ordinal} outside of #{nesting_col_name} in column #{col_name}"
    end
  end
end
puts

#Third check duration
puts "Checking for Duration..."
duration_col_list.each do |col_name|
  col = get_column(col_name)
  col.cells.each do |c|
    unless (c.duration >= min_time_ms) || (col_name.include?("transition") && c.posture == "f")
      puts "Cell #{c.ordinal} is less than #{min_time_ms} ms in column #{col_name}"
    end
  end
end
puts

#Fourth mhelp nested within 'x'
puts "Checking for mhelp nesting..."
transition_clean_col = get_column('transition_clean')
transition_clean_cells = transition_clean_col.cells
mhelp_col_list.each do |col_name|
  col = get_column(col_name)
  col.cells.each do |c|
    x = transition_clean_cells.select{ |tc| tc.contains(c) && tc.posture == 'x' }.first
    if x.nil?
      puts "Cell #{c.ordinal} in column #{col_name} is not within an 'x' from transition_clean"
    end
  end
end
puts

#Fifth 'x' nests some cell
mhelp_col = get_column('mhelp')
mhelp_cells = mhelp_col.cells
puts "Checking for transition_clean 'x' cells containing some mhelp cell..."
transition_clean_cells.each do |c|
  next unless c.posture == 'x'
  contains_mhelp = mhelp_cells.map{ |mc| c.contains(mc) }.any?
  unless contains_mhelp
    puts "Cell #{c.ordinal} in column transition_clean has no nested mhelp cell(s)"
  end
end
puts

#Sixth detailed_posture nested within 'c' 's' or 'k'
puts "Checking for detailed_posture nesting..."
transition_clean_col = get_column('transition_clean')
transition_clean_cells = transition_clean_col.cells
d_posture_col_list.each do |col_name|
  col = get_column(col_name)
  col.cells.each do |c|
    x = transition_clean_cells.select{ |tc| tc.contains(c) && %w[s k c].include?(tc.posture)  }.first
    if x.nil?
      puts "Cell #{c.ordinal} in column #{col_name} is not within an 's' 'k' or 'c' from transition_clean"
    end
  end
end
puts

#Seventh 'x' nests some cell
d_posture_col = get_column('detailed_posture')
d_posture_cells = d_posture_col.cells
puts "Checking for transition_clean 's' 'k' 'c' cells containing some detailed_posture cell..."
transition_clean_cells.each do |c|
  next unless %w[s k c].include?(c.posture)
  contains_d_posture = d_posture_cells.map{ |dc| c.contains(dc) }.any?
  unless contains_d_posture
    puts "Cell #{c.ordinal} in column transition_clean has no nested detailed_posture cell(s)"
  end
end
puts

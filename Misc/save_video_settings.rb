# Save video metadata from Controller to spreadsheet column
# Additionally, if any of the videos start before the zero time
# on the Controller, adjust all the videos by the appropriate
# amount to have all videos start within the Controller bounds.
# Update timestamps in the spreadsheet as necessary.

require 'Datavyu_API.rb'
#require '~/scripts/2018_KeenShoes/Datavyu_API.rb'

# Add a constant to all cell timestamps in the spreadsheet.
# Add a constant to the offset off all tracks.
def shift_time(amt)
  get_column_list.each do |colname|
    col = get_column(colname)
    col.cells.each do |c|
      c.onset += amt
      c.offset += amt
    end
    set_column(col)
  end

  RVideoController.videos.each do |v|
    v.set_offset(v.get_offset + amt)
  end

end


vid_col = videos_to_column
errors = 0
min_time = 0
vid_col.cells.each do |v|
  if v.onset < 0 || v.offset < 0
    errors += 1
    puts "#{File.basename(v.file)} has negative timestamp"
  end
  min_time = [min_time, v.onset].min
end
puts "Found #{errors} errors."

# Adjust by the minimum time if it is less than 0
if min_time < 0
  puts "Adjusting video position and cell timestamps by #{-min_time} millis..."
  raise "failed to shift" unless shift_time(-min_time)
  vid_col = videos_to_column # we need to get the new times
end

puts "Done."

set_column(vid_col)

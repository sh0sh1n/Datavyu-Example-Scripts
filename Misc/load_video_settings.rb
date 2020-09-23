# Load videos using settings saved in spreadsheet column

require 'Datavyu_API.rb'

if defined?('column_to_videos')
  column_to_videos(clean:true)
else
  api_locations = %w[
    ~/scriptrepo/2018_KeenShoes/Datavyu_API.rb
    ~/scripts/2018_KeenShoes/Datavyu_API.rb
    ~/Desktop/Datavyu_API.rb
  ]
  api_locations.each do |loc|
    pp = File.expand_path(loc)
    puts pp
    if File.exist?(File.expand_path(loc))
      puts "loading library from #{loc}"
      require loc
      break
    end
  end

  until RVideoController.videos.empty?
    RVideoController.video_controller.shutdown(RVideoController.videos.first.get_identifier)
  end
  # RVideoController.videos.each do |vid|
  #   RVideoController.video_controller.shutdown(vid.get_identifier)
  # end

  column_to_videos()
end

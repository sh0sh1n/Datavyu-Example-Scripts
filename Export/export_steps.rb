## Body
require 'Datavyu_API.rb'
require 'csv'

steps = get_column('steps')
data = CSV.new(String.new)

steps.cells.each do |c|
  data << [c.onset, c.offset]
end

outfile = File.open(File.expand_path('~/Desktop/steptimes.csv'),'w+')
outfile.puts data.string
outfile.close

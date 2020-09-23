##Typos-
##transition (<posture>) (pri/rel/clean) should only contain (b), (p), (l), (c), (s), (k), (n), (q), (z), (u), (i), (f), (x)
##location (<location>) (pri/rel/clean) should only contain (sl), (st), (b), (e), (e1), (e2)
##mhelp (<mhelp>) (pri/rel/clean) should only contain (f), (g), (s), (w), (h)
##detailed_posture (<posture>) (pri/rel/clean) should only contain (within c => (h), (k), (f), (d)) (within s => (w), (e), (l), (s), (m), (r), (t)) (within k => (y), (a))

##Parameters
#create hash from columns -> code -> allowed arg
allowed_args_map = {'transition' => { 'posture' => %w[b p l c s k n q z u i f x] },
  'location' => { 'location' => %w[sl st b e e1 e2] },
  'mhelp' => { 'mhelp' => %w[f g s w h] },
  'detailed_posture' => { 'posture' => %w[h k f d w e l s m r t y a] }}

##Body
require 'Datavyu_API.rb'

#Check typo
#Loop over column names
col_list = allowed_args_map.keys
col_list.each do |col_name|
  #Return a hash from list of codes to allowed arguments for current column
  code_map = allowed_args_map[col_name]
  #Get list of all the codes within that current column
  code_list = code_map.keys
  #Get column from spreadsheet
  col = get_column(col_name)
  #Loop over codes, check for typo
  code_list.each do |code_name|
    #Return the list of allowed arguments for the current code
    allowed_args = code_map[code_name]
    #Check each cell for allowed arguments for the current code
    col.cells.each do |c|
      #Get argument for current cell and make sure it's in the allowed arguments
      unless allowed_args.include?( c.get_code(code_name) )
        #Print out error message
        puts "#{col_name} contains a typo at cell #{c.ordinal} for code <#{code_name}>"
        # print line of space
        puts
      end
    end
  end
end

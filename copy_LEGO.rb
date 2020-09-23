## Parameters
# create reduced versions (only certain columns) of a bunch of opf files
# saves with '_reduced' appended to filenames

# folder to original LEGO files
input_folder = '~/Desktop/LEGO'

# save reduced files here
output_folder = '~/Desktop/ObjectPlay'

# list of columns to keep
cols_to_keep = %w[id babyobject babyobject_rel babyobject_clean
  babyobject_uniquetypes babyobject_uniquetypes_rel babyobject_uniquetypes_clean
  listobjects reliability_blocks]

# do it for these ids
# expects files to have S#XXX in their names , e.g. S#024 or S#003
id_list = %w[2 4 5 7 8 9 10 11 12 14 15 16 17 18 20 21 22 24 25 26 28 29 30 31
  32 33 34 35 36 38 41 42 43 45 46 47 48 50 51 52]

## Body
require 'Datavyu_API.rb'

input_path = File.expand_path(input_folder)
output_path = File.expand_path(output_folder)
unless Dir.exist?(output_path)
  Dir.mkdir(output_path)
end

infiles = Dir.chdir(input_path) { Dir.glob('*.opf') }

id_list.each do |id|
  # format the id string as it appears in the filenames
  format_id = 'S#' + '%03d' % id
  # select the corresponding file (will grab 2, 1 for each visit)
  infile = infiles.select{ |x| x.include?(format_id) }

  infile.each do |f|
    puts "Copying reduced version of #{f}..."
    $db, $pj = load_db(File.join(input_path, f))
    # loop through columns and remove unless want to keep
    get_column_list.each do |x|
      unless cols_to_keep.include?(x)
        delete_column(x)
      end
    end
    p f
    f_parts =  f.split('.')

    # save the reduced version in output folder
    save_db(File.join(output_path, f_parts[0]+'_objpass'+'.opf'))
  end
end

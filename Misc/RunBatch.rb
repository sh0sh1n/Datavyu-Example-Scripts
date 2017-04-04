# Run a ruby script on a directory of Datavyu files.
# Ask the user for script file path and a folder containing Datavyu files.

## Params
verbose = 1
recurse = false

## Body
require 'Datavyu_API.rb'
java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter
begin
	# Prompt user for script file.
	rbFilter = FileNameExtensionFilter.new('Ruby script','rb')
	jfc = JFileChooser.new()
	jfc.setAcceptAllFileFilterUsed(false)
	jfc.setFileFilter(rbFilter)
	jfc.setMultiSelectionEnabled(false)
	jfc.setDialogTitle('Select Ruby script file.')

	ret = jfc.showOpenDialog(javax.swing.JPanel.new())

	if ret != JFileChooser::APPROVE_OPTION
		raise "Invalid selection. Aborting."
	end

	script = ''
	scriptFile = jfc.getSelectedFile()
	fn = scriptFile.getName()

	# Make it illegal to open self.
	if fn=='RunBatch.rb' # for some reason __FILE__ doesn't work...this isn't a great solution but it'll have to do until I figure out a more robust implementation
		raise "Illegal to open self. Aborting."
	end

	script = scriptFile.getAbsolutePath()

	puts script if verbose > 1

	# Prompt for user to select directory containing Datavyu files
	jfc.resetChoosableFileFilters()
	jfc.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
	jfc.setDialogTitle('Select folder containing Datavyu files.')

	ret = jfc.showOpenDialog(javax.swing.JPanel.new())

	if ret =! JFileChooser::APPROVE_OPTION
		raise "Invalid selection. Aborting."
	end

	dv_dir = jfc.getSelectedFile().getAbsolutePath()
	puts dv_dir if verbose > 1
	dv_files = []
	filter = (recurse)? File.join('**','*.opf') : '*.opf'
	dv_files = get_datavyu_files_from(dv_dir, recurse)

	puts dv_files if verbose > 1

	backupDB = $db
	backupProj = $pj
	for file in dv_files
		puts "\n"
		puts "=" * 10
		puts "Working on #{file}" if verbose > 0
		begin
			$db,$pj = load_db(File.join(dv_dir,file))
			load(script)
			save_db(File.join(dv_dir,file))
		rescue StandardError => e
			puts "Script failed on file #{file}"
			puts e.message
			puts e.backtrace
			next
		end
	end
	$db = backupDB
	$pj = backupProj
rescue StandardError => e
	puts e.message
	puts e.backtrace
ensure
	$db = backupDB unless backupDB.nil?
	$pj = backupProj unless backupProj.nil?
end

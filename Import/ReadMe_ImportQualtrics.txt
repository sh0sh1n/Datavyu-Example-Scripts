Populates trial column in batch of datavyu files with a cell for each event in CSV file produced by qualtrics. Cells have one code <trial> which labels the trial type.

NOTES
1) For some reason, Ruby can't read the csv files unless I open them and resave them explicitly as CSV files (I did this using Numbers on my mac). If you're getting an error about reading the CSV file, consider opening them and re-saving them explicitly as a CSV file (using excel or Numbers) then replacing the file 
2) I am occasionally getting a 'bad file descriptor' error when reading the CSV files, still. Really frustrating and I can't figure it out. But whenever I get this, I just run the script again and it works. 


STEPS TO RUN:
1) Make a folder on your desktop called ‘Datavyu’ with all the datavyu files in which you want to insert a trial column
	- Assumes each file has a column called ‘task’ with *one* code (reads this code name a	automatically because it seems to differ across files, e.g. ‘task’ versus ‘task_cp’)
	- Will print a warning if above condition is not met and automatically set the task onset to 1000	 ms.
	- Assumes all the text preceding the first underscore is the name of the subject as it appears in 	the ID column of the qualtrics CSV file
2) Make a folder on desktop called ‘Qualtrics’ with master CSV file
	- Any element in header with  text ‘onset’ or ‘offset’ is considered a trial (except for intro_onset 	and end_onset)
	- Populates a cell for each trial with label from header in code <trial> and timing information 	from CSV file reflected in onset/offset
	- For some entries in header, there is onset timing information, but not offset. In this case, it 	makes a point cell and sets offset=onset
3) Open a blank datavyu spreadsheet and run the script. It will modify all the datavyu files in your Datayu folder to have
the new column

   

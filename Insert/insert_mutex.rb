## Parameters
# inserts mutex column from two specified columns into currently open spreadsheet
# use RunBatch.rb to modify every file in a folder
# see https://databrary.github.io/datavyu-docs/top-level-namespace.html#create_mutually_exclusive-instance_method
# for definition of what a mutexed column is

# names of columns from which to create a mutex column
colname1 = 'trial'
colname2 = 'lookingtime2'

## Body
require 'Datavyu_API.rb'

# name the mutex column after the two columns from which it was created
mutexname = 'mutex_' + colname1 + '_' + colname2
# create the mutex column
mutex = create_mutually_exclusive(mutexname,colname1,colname2)
# visualize in spreadsheet
set_column(mutexname,mutex)

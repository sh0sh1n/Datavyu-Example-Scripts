# Copy a column to another column.

## Parameters
source_column = 'ColumnA'
destination_column = 'ColumnB'

## Body
require 'Datavyu_API.rb'
set_column(destination_column, get_column(source_column))

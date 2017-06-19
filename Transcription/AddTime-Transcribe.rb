## Add a fixed number of miliseconds to the offset time of point cells.## Parameterscolumn_name = 'transcribe'time = 500## Bodyrequire 'Datavyu_API.rb'
begin   trans = get_column(column_name)
   for cell in trans.cells      if cell.onset == cell.offset        cell.change_code("offset", cell.onset+time)      end   end
set_column(trans)
end
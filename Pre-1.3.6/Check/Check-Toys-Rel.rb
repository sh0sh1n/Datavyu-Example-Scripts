require 'Datavyu_API.rb'

# params
valid_toys_codes = ['y','n']
verbose = 1
begin
  @errors = []
  # Fetch columns
  puts "Getting columns..." if verbose > 0
  colToys = getVariable("rel_toys")


  toysCells = colToys.cells

  # Check all cells for the following:
  # 1. Offset is greater than onset
  # 2. toys code is a valid code.

  puts "Checking cell times and codes..." if verbose > 0
  for tcell in toysCells
    if (tcell.onset>=tcell.offset)
      @errors << "Cell #{tcell.ordinal} onset or offset invalid."
    end

    if (not valid_toys_codes.include?(tcell.broom))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.broom}) not valid."
    end

    if (not valid_toys_codes.include?(tcell.redball))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.redball}) not valid."
    end

    if (not valid_toys_codes.include?(tcell.stroller))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.stroller}) not valid."
    end

    if (not valid_toys_codes.include?(tcell.popper))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.popper}) not valid."
    end

    if (not valid_toys_codes.include?(tcell.tub))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.tub}) not valid."
    end

    if (not valid_toys_codes.include?(tcell.littleball))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.littleball}) not valid."
    end

    if (not valid_toys_codes.include?(tcell.doll))
      @errors << "Cell #{tcell.ordinal} toys code (#{tcell.doll}) not valid."
    end
  end

  # Write out errors
	puts "Finished." if verbose > 0
  if @errors.size > 0
    puts "\nTYPOS:"
    puts @errors
  else
    puts "No errors found! Nice."
  end
rescue StandardError => e
  puts e.message
  puts e.backtrace
end

# Compute frequencies and durations of code values in a column

## Parameters
column_name = 'babymovement'

## Body
require 'Datavyu_API.rb'

# Aggregate frequencies and durations of code values in the given column
def freqs_durs(column)
    col = get_column(column) if column.class == String

    freqs = Hash.new { |h, k| h[k] = Hash.new(0) }
    durs = Hash.new { |h, k| h[k] = Hash.new(0) }

    col.cells.each do |cell|
        col.arglist.each do |code|
            val = cell.get_code(code)
            freqs[code][val] += 1
            durs[code][val] += cell.duration
        end
    end

    [freqs, durs]
end


fs, ds = freqs_durs(column_name)

fmt = "%12s\t%12s\t%12s\n"
fs.keys.each do |code|
    puts code
    printf(fmt, 'Value', 'Frequency', 'Duration')
    fs[code].keys.sort.each do |value|
        printf(fmt, value, fs[code][value], ds[code][value])
    end
    puts
end


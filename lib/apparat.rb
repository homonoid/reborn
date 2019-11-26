require_relative 'apparat/syntax/scan'
require 'readline'

while line = Readline.readline('~ ', true)
  begin
    Apparat::Scanner.new(line).scan.each do |token|
      puts "#{token.type}\t#{token.value}"
    end
  rescue Apparat::ApparatError => e
    puts "=== SORRY! ===\n #{e}"
  end
end
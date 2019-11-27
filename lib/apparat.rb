# BE AWARE:
# Current revision of this file is DEBUG and DEBUG only.

require_relative 'apparat/syntax/scan'

def scan(source)
  begin
    Apparat::Scanner.new(source).scan.each do |token|
      puts "#{token.type}\t#{token.value}"
    end
  rescue Apparat::ApparatError => e
    puts "=== SORRY! ===\n #{e}"
  end
end

def repl
  require 'readline'

  while line = Readline.readline('~ ', true)
    scan(line)
  end
end

def file(name)
  source = open(name, 'r').read
  scan(source)
end

def main(args)
  if args.empty?
    repl
  else
    sources = args.map do |filename| 
      begin
        open(filename, 'r').read
      rescue Errno::ENOENT
        puts "=== SORRY! ===\n File '#{filename}' does not exist"
        exit(1)
      end
    end

    sources.each { |source| scan(source) }
  end
end

main(ARGV)

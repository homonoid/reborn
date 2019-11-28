# BE AWARE:
# Current revision of this file is DEBUG and DEBUG only. 
# Use with caution and read with understanding of stated.

require_relative 'apparat/syntax/scan'
require_relative 'apparat/syntax/parse'

JUST_SCAN = false

def scan(source)
  Apparat::Scanner.new(source).scan
end

def parse(tokens)
  Apparat::Parser.new(tokens).parse
end

def process(source)
  tokens = scan(source)
  if JUST_SCAN
    tokens.each {|token| puts "#{token.type}\t#{token.value}"}
  else
    parse(tokens).each do |instruction|
      puts "#{instruction.name}\t#{instruction.argument}"
    end
  end
end

def repl
  require 'readline'

  while line = Readline.readline('~ ', true)
    begin
      process(line)
    rescue Apparat::Error => e
      puts "=== SORRY! ===\n #{e}"
    end
  end
end

def main(args)
  if args.empty?
    repl
  else
    sources = args.map do |filename| 
      begin
        open(filename, 'r')
      rescue Errno::ENOENT
        puts "=== SORRY! ===\n File '#{filename}' does not exist"
        exit(1)
      end
    end

    name = nil

    begin
      sources.each do |source|
        name = source.path
        process(source.read)
      end
    rescue Apparat::Error => e
      puts "=== SORRY! ===\n #{e} (<#{name}>)"
      exit(1) 
    end
  end
end

main(ARGV)

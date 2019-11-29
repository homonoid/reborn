# BE AWARE:
# Current revision of this file is DEBUG and DEBUG only. 
# It is written in bad and hurting Ruby.
# Use with caution and (do not) read with understanding of stated.

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
    program = parse(tokens)

    puts "--- INSTRUCTIONS ---\n\n"

    program[:actions].each do |instr|
      puts "@ L: #{instr.line}, C: #{instr.column} \t| #{instr.name}\t#{instr.argument}"
    end

    puts "\n--- DATA ---\n\n"

    program[:data].each_with_index do |element, idx|
      puts "offset #{idx} | <#{element}>"
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

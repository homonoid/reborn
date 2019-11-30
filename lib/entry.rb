# UPD: This is a new, semi-official entry for Apparat.

require_relative "apparat/syntax/scan"
require_relative "apparat/syntax/parse"
require_relative "apparat/error"

$just_scan = false

def error(message, do_quit = false)
  puts "=== SORRY! ===\n #{message}"
  exit(1) if do_quit
end

def offset(data, item)
  if data.include?(item)
    data.index(item)
  else
    data << item
    data.size - 1
  end
end

def disasm(assembly)
  instrs = []
  data = []
  meta = []

  assembly.make.each do |instr|
    meta << [instr.line, instr.col]
    instrs << [instr.name, offset(data, instr.arg)]
  end

  puts "--- META ---"
  meta.each_with_index do |pos, idx|
    puts "@#{idx}\t| line #{pos[0]}, column #{pos[1]}"
  end

  puts "\n--- ACTIONS ---"
  instrs.each_with_index do |instruction, idx|
    out = "@#{idx}\t| #{instruction[0]}"
    out += "\t$#{instruction[1]}" if instruction.size > 1
    puts out
  end

  puts "\n--- DATA ---"
  data.each_with_index do |point, idx|
    puts "$#{idx}\t| <#{point}>"
  end
end

def process(filename, source, do_quit = false)
  begin
    tokens = Apparat::Scanner.new(source).scan
    if $just_scan
      tokens.each do |token|
        puts "#{token.type}\t#{token.value}"
      end
    else
      assembly = Apparat::Parser.new(filename, tokens).parse
      disasm(assembly)
    end
  rescue Apparat::Error => e
    error("#{e} of '#{filename}'", do_quit)
  end
end

def files(paths)
  paths.each do |f|
    if not File.exists?(f)
      error("Got '#{f}', but it does not exist", true)
    elsif File.directory?(f)
      error("Got '#{f}', but it is a directory", true)
    else
      source = open(f, 'r').read
      process(f, source, true)
    end
  end
end

def repl
  require 'readline'

  begin
    while line = Readline.readline('~ ', true)
      process("stdin", line, false) # `false` means do not quit
    end
  rescue Interrupt
    exit
  end
end

def main(args)
  # Process the flags.
  args = args.filter do |arg| 
    if arg == "-scan"
      $just_scan = true
      false
    else
      true
    end
  end

  # Transfer the control.
  if args.empty?
    repl
  else
    files(args)
  end
end

main(ARGV)
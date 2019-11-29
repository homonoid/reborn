require_relative '../error'

module Apparat
  Instruction = Struct.new(:name, :argument, :line, :column)

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @actions = []
      @data = []
      @position = 0
    end

    private def peek
      @tokens[@position]
    end

    private def consume
      @position += 1; @tokens[@position - 1]
    end

    private def match(type)
      peek.type == type ? (@position += 1; true) : false
    end

    private def syntaxError
      found = (peek.type == :EOF ? "EOF" : "'#{peek.value}'")
      raise Apparat::Error.new("Invalid syntax: #{found}", peek.line, peek.column)
    end

    private def expect(type)
      peek.type == type ? consume : syntaxError
    end

    # Store the value and calculate its offset.
    private def store(value)
      @data.include?(value) ? @data.index(value) : (@data << value; @data.size - 1)
    end

    # num ::= FLOAT | SCI | HEX | OCT | BIN | ASCII | UNI
    private def num
      if [:FLOAT, :HEX, :OCT, :BIN, :ASCII, :UNI, :SCI].include?(peek.type)
        type = peek.type.downcase
        offset = store(consume.value)
        [type, offset]
      else
        false
      end
    end

    # text ::= " (TCHAR | { atomar })* " 
    # TODO: change atomar to expr.
    private def text
      if match(:'"')
        line, column = peek.line, peek.column
        buffer = ''
        depth = 0

        loop do
          buffer += consume.value while peek.type == :TCHAR

          unless buffer.empty?
            @actions << Instruction.new(:PUSH_CHAIN, store(buffer), line, column)
            depth += 1
          end

          if match(:'{') 
            buffer = ''; depth += 1
            atomar; expect(:'}')
          else
            expect(:'"'); break
          end
        end

        @actions << Instruction.new(:TEXT, depth, line, column - 1)
        true
      else
        false
      end
    end

    # list ::= [ atomar* ]
    private def list
      if match(:'[')
        line, column = peek.line, peek.column - 1
        length = 0; length += 1 while atomar; expect(:']')
        @actions << Instruction.new(:LIST, length, line, column); true
      else
        false
      end
    end
    
    # atomar ::= id | list | num | text
    private def atomar
      line, column = peek.line, peek.column

      if peek.type == :ID
        offset = store(consume.value)
        @actions << Instruction.new(:REQ, offset, line, column)
      elsif number = num
        type, offset = number
        instructions = {
          float:  :PUSH_FLOAT,  hex: :PUSH_HEX,
          oct:    :PUSH_OCTAL,  bin: :PUSH_BIN,
          ascii:  :PUSH_ASCII,  uni: :PUSH_UNI,
          sci:    :PUSH_SCI
        }
        @actions << Instruction.new(instructions[type], offset, line, column)
      elsif text
        true
      elsif list
        true
      else
        false
      end
    end

    def parse
      atomar; expect(:EOF) # entry ::= atomar EOF
      { actions: @actions, data: @data }
    end
  end
end
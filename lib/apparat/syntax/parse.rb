require_relative '../error'

module Apparat
  Instruction = Struct.new(:name, :argument)

  class Parser
    def initialize(tokens)
      @tokens = tokens
      @program = []
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

    private def atomar
      if peek.type == :ID
        @program << Instruction.new(:REQ, consume.value)
      elsif match(:'[')
        next while atomar; expect(:']') # list ::= [ atomar* ]
        @program << Instruction.new(:LIST)
      else
        false
      end
    end

    def parse
      atomar; expect(:EOF) # entry ::= atomar EOF
      @program
    end
  end
end
require_relative '../error'
require_relative '../bytegen'

module Apparat
  class Parser
    def initialize(filename, tokens)
      @tokens = tokens
      @filename = filename
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

    # num ::= FLOAT | SCI | HEX | OCT | BIN | ASCII | UNI
    private def num
      if [:FLOAT, :HEX, :OCT, :BIN, :ASCII, :UNI, :SCI].include?(peek.type)
        Apparat::Byte::Number.new(peek.type, peek.value, peek.line, consume.column)
      else
        false
      end
    end

    # text ::= " (TCHAR | { atomar })* " 
    # TODO: change atomar to expr.
    private def text
      if match(:'"')
        line, col = peek.line, peek.column
        fragments = []

        loop do
          buffer = ''
          buffer += consume.value while peek.type == :TCHAR

          unless buffer.empty?
            fragments << Apparat::Byte::Chain.new(buffer, line, col)
            buffer = ''
          end

          if match(:'{') 
            fragments << atomar
            expect(:'}')
          else
            expect(:'"')
            return Apparat::Byte::Text.new(fragments, line, col - 1)
          end
        end
      end
    end

    # list ::= [ atomar* ]
    private def list
      if match(:'[')
        line, col = peek.line, peek.column - 1
        items = []

        while item = atomar
          items << item
        end
        
        expect(:']')

        Apparat::Byte::List.new(items, line, col)
      end
    end
    
    # atomar ::= ID | list | num | text
    private def atomar
      line, col = peek.line, peek.column

      if peek.type == :ID
        Apparat::Byte::Request.new(consume.value, line, col)
      elsif node = list or node = num or node = text
        node
      end
    end

    # entry ::= atomar EOF
    def parse
      body = [atomar]; expect(:EOF)
      Apparat::Byte::Root.new(@filename, body)
    end
  end
end
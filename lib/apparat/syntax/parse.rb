require_relative '../error'
require_relative '../bytegen'

module Apparat
  # Apply some rules to an array of `Token`s and return corresponding
  # bytecode generators.
  class Parser
    def initialize(filename, tokens)
      @tokens = tokens
      @filename = filename
      @position = 0
    end

    private

    def peek
      @tokens[@position]
    end

    def consume
      @position += 1
      @tokens[@position - 1]
    end

    def match(type)
      if peek.type == type
        @position += 1
        true
      else
        false
      end
    end

    def syntax_error
      found = (peek.type == :EOF ? 'EOF' : "'#{peek.value}'")
      raise Apparat::Error.new(
        "Invalid syntax: #{found}",
        peek.line,
        peek.column
      )
    end

    def expect(type)
      peek.type == type ? consume : syntax_error
    end

    # num ::= FLOAT | SCI | HEX | OCT | BIN | ASCII | UNI
    def num
      if %i[FLOAT HEX OCT BIN ASCII UNI SCI].include?(peek.type)
        Apparat::Byte::Number.new(peek.type, peek.value, peek.line, consume.column)
      else
        false
      end
    end

    # text ::= " (TCHAR | { atomar })* "
    # TODO: change atomar to expr.
    def text
      return unless match(:'"')

      line = peek.line
      col = peek.column
      fragments = []

      loop do
        buffer = ''
        buffer += consume.value while peek.type == :TCHAR

        unless buffer.empty?
          fragments << Apparat::Byte::Chain.new(buffer, line, col)
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

    # list ::= [ atomar* ]
    def list
      return unless match(:'[')

      line = peek.line
      col = peek.column - 1
      items = []

      while (item = atomar)
        items << item
      end

      expect(:']')

      Apparat::Byte::List.new(items, line, col)
    end

    # atomar ::= ID | list | num | text
    def atomar
      line = peek.line
      col = peek.column

      if peek.type == :ID
        Apparat::Byte::Request.new(consume.value, line, col)
      elsif (node = list) || (node = num) || (node = text)
        node
      end
    end

    public

    # entry ::= atomar EOF
    def parse
      body = [atomar]
      expect(:EOF)
      Apparat::Byte::Root.new(@filename, body)
    end
  end
end

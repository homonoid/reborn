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
      @optable = {
        'or' => [10, 'left'],
        'and' => [10, 'left'],

        'is' => [20, 'left'],
        'is not' => [20, 'left'],
        'in' => [20, 'left'],
        'not in' => [20, 'left'],

        '<' => [30, 'left'],
        '>' => [30, 'left'],
        '<=' => [30, 'left'],
        '>=' => [30, 'left'],

        '+' => [40, 'left'],
        '-' => [40, 'left'],

        '*' => [50, 'left'],
        '/' => [50, 'left'],
        'mod' => [50, 'left'],

        '^' => [60, 'right'],
        'to' => [70, 'right']
      }
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

    # text ::= " (TCHAR | { expr })* "
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
          fragments << (expr || syntax_error)
          expect(:'}')
        else
          expect(:'"')
          return Apparat::Byte::Text.new(fragments, line, col - 1)
        end
      end
    end

    # list ::= [ expr* ]
    def list
      line = peek.line
      col = peek.column

      return unless match(:'[')

      items = []

      while (item = expr)
        items << item
      end

      expect(:']')

      Apparat::Byte::List.new(items, line, col)
    end

    # atomar ::= ID | list | num | text
    def atomar
      line = peek.line
      col = peek.column

      if peek.type == :OP && %(+ -).include?(peek.value)
        Apparat::Byte::Unary.new([consume.value, atomar || syntax_error], line, col)
      elsif match(:NOT)
        Apparat::Byte::Unary.new(['not', atomar || syntax_error], line, col)
      elsif peek.type == :ID
        Apparat::Byte::Request.new(consume.value, line, col)
      elsif (node = list) || (node = num) || (node = text)
        node
      elsif match(:'(')
        inner = expr || syntax_error
        expect(:')')
        inner
      end
    end

    # Check if the peeked token is an infix.
    # NOTE: does not modify/consume anything.
    def infix
      infixes = %w[to and or + - * / ^ mod <= >= < > is in] +
                ['not in', 'is not']

      infixes.include?(peek.value)
    end

    # expr ::= atomar infix expr
    # NOTE: precedence table (@optable) is in `initialize`.
    def expr(min_prec = 5, step = 10)
      left = atomar

      loop do
        if !left || !infix || @optable[peek.value][0] < min_prec
          return left
        else
          op = consume
          line = op.line
          col = op.column
          prec, assoc = @optable[op.value]
          next_prec = prec || (prec + step if assoc == 'left')
          right = expr(next_prec) || syntax_error
          left = Apparat::Byte::Binary.new([op.value, left, right], line, col)
        end
      end
    end

    public

    # entry ::= atomar EOF
    def parse
      body = [expr]
      expect(:EOF)
      Apparat::Byte::Root.new(@filename, body)
    end
  end
end

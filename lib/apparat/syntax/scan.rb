require_relative '../error'

module Apparat
  # A list of keywords and their associated types (NOTE: keys are strings).
  KEYWORDS = {
    'else' => :ELSE,
    'and' => :AND,
    'or' => :OR,
    'is' => :IS,
    'in' => :IN,
    'not' => :NOT,
    'mod' => :MOD,
    'to' => :TO
  }.freeze

  Token = Struct.new(:type, :value, :line, :column, :length)

  # Split the source into an array of `Token`s.
  class Scanner
    def initialize(source)
      @source = source
      @line = 1
      @column = 1
      @pos = 0
      @string = false
      @interpolation = false
    end

    private

    def make_token(type, value, length = value.size)
      Token.new(type, value, @line, @column, length)
    end

    def identify(chunk)
      if @string
        case chunk
        when /\A([^\n"\\\{]|\\[ntvr"])/
          make_token(:TCHAR, $1)
        when /\A\{/
          @string = false
          @interpolation = true
          make_token(:'{', '{')
        when /\A"/
          @string = false
          make_token(:'"', '"')
        else
          raise Apparat::Error.new(
            "Invalid lexeme: '#{chunk[0]}' in text literal",
            @line,
            @column
          )
        end
      else
        case chunk
        when /\A[\n]+/
          @line += $&.size # skip multiple newlines a time
          @column = 1
          make_token(:IGNORE, nil, $&.size)
        when /\A[ \t\r]+/
          @column += $&.size
          make_token(:IGNORE, nil, $&.size)
        when /\A--[^\n]*/
          make_token(:IGNORE, nil, $&.size)
        when /\A'((?!['\n\t\r\\])[\x00-\x7F]|\\[\\nrtv'])'/
          make_token(:ASCII, $1, $&.size)
        when /\A(;|=>?|<=|>=|\+=|\-=|\*=|\^=|,|\.|[\(\{\[\]\)\]\|])/
          make_token($1.to_sym, $1)
        when /\A\}/
          if @interpolation
            @string = true
            @interpolation = false
          end
          make_token(:'}', '}')
        when /\A([\+\-\*\/\^\>\<])/
          make_token(:OP, $1)
        when /\A([a-zA-Z_][a-zA-Z0-9_]+|[a-zA-Z])/
          make_token(Apparat::KEYWORDS[$1] || :ID, $1)
        when /\A0(b)([01]+)/, /\A0(x|u)([0-9A-Fa-f]+)/, /\A0(o)([0-7]+)/
          type = { 'b' => :BIN, 'x' => :HEX, 'o' => :OCT, 'u' => :UNI }[$1]
          # Value has no 0[boux], but length does, so use the whole match ($&):
          make_token(type, $2, $&.size)
        when /\A([0-9]+\.[0-9]+)(e\-?[0-9]+)?/, /\A([1-9][0-9]*|0)/
          $2 ? make_token(:SCI, $&) : make_token(:FLOAT, $1)
        when /\A"/
          @string = true
          make_token(:'"', '"')
        else
          raise Apparat::Error.new(
            "Invalid lexeme: '#{chunk[0]}'",
            @line,
            @column
          )
        end
      end
    end

    public

    def scan
      tokens = []
      met_is = false
      met_not = false

      while @pos < @source.size
        token = identify(@source[@pos..])

        @pos += token.length

        if met_not && token.type == :IN
          met_not = false
          not_tok = tokens.pop
          tokens << Token.new(:NOTIN, 'not in', not_tok.line, not_tok.column, 5)
          @column += tokens.last.length
          next
        elsif met_is && token.type == :NOT
          met_is = false
          is_tok = tokens.pop
          tokens << Token.new(:ISNOT, 'is not', is_tok.line, is_tok.column, 5)
          @column += tokens.last.length
          next
        elsif token.type == :NOT
          met_not = true
        elsif token.type == :IS
          met_is = true
        elsif token.type == :IGNORE
          next
        else
          met_not = false
          met_is = false
        end

        @column += token.length
        tokens << token
      end

      tokens.push make_token(:EOF, '') # return the tokens plus the EOF marker
    end
  end
end

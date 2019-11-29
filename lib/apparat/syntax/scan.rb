require_relative '../error'

module Apparat
  # A list of keywords and their associated types (NOTE: keys are strings).
  KEYWORDS = {
    'else' => :ELSE,   'and' => :AND,
    'or'   => :OR,     'is'  => :IS,
    'not'  => :NOT,    'mod' => :MOD,
    'to'   => :TO,
  }

  Token = Struct.new(:type, :value, :line, :column, :length)

  class Scanner
    def initialize(source)
      @source = source
      @line, @column = 1, 1 # line and column are for humans, so start with 1
      @pos = 0
      @string, @interpolation = false, false
    end

    private def makeToken(type, value, length = value.size)
      Token.new(type, value, @line, @column, length)
    end

    private def identify(chunk)
      if @string
        case chunk
        when /\A([^\n"\\\{]|\\[ntvr"])/
          makeToken(:TCHAR, $1)
        when /\A\{/
          @string = false
          @interpolation = true
          makeToken(:'{', '{')
        when /\A"/
          @string = false
          makeToken(:'"', '"')
        else
          raise Apparat::Error.new("Invalid lexeme: '#{chunk[0]}' in text literal", @line, @column)
        end
      else
        case chunk
        when /\A--[^\n]*/
          makeToken(:IGNORE, nil, $&.size)
        when /\A'((?!['\n\t\r\\])[\x00-\x7F]|\\[\\nrtv'])'/
          makeToken(:ASCII, $1, $&.size)
        when /\A(;|=>?|<=|>=|\+=|\-=|\*=|\^=|,|\.|[\(\{\[\]\)\]\|])/
          makeToken($1.to_sym, $1)
        when /\A\}/
          (@string, @interpolation = true, false) if @interpolation
          makeToken(:'}', '}')
        when /\A([\+\-\*\/\^><])/
          makeToken(:OP, $1)
        when /\A([a-zA-Z_][a-zA-Z0-9_]+|[a-zA-Z])/
          makeToken(Apparat::KEYWORDS[$1] || :ID, $1)
        when /\A0(b)([01]+)/, /\A0(x|u)([0-9A-Fa-f]+)/, /0(o)([0-7]+)/
          type = {'b' => :BIN, 'x' => :HEX, 'o' => :OCT, 'u' => :UNI}[$1]
          makeToken(type, $2, $&.size) # value has no 0[boux], but length does, so use the whole match
        when /\A([0-9]+\.[0-9]+)(e\-?[0-9]+)?/, /\A([1-9][0-9]*|0)/
          $2 ? makeToken(:SCI, $&) : makeToken(:FLOAT, $1)
        when /\A[\n]+/
          @line += $&.size # skip multiple newlines a time
          @column = 1
          makeToken(:IGNORE, nil, $&.size)
        when /\A[ \t\r]+/
          makeToken(:IGNORE, nil, $&.size)
        when /\A"/
          @string = true
          makeToken(:'"', '"')
        else
          raise Apparat::Error.new("Invalid lexeme: '#{chunk[0]}'", @line, @column)
        end
      end
    end

    def scan
      tokens = []

      while @pos < @source.size
        token = identify(@source[@pos..])
        @pos += token.length
        @column += token.length
        tokens << token if token.type != :IGNORE
      end

      tokens.push makeToken(:EOF, '') # return the tokens plus the EOF marker
    end
  end
end
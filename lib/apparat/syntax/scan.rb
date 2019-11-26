require_relative '../error'

module Apparat
  Token = Struct.new(:type, :value, :line, :column, :length)

  class Scanner
    # A list of keywords and their associated types (NOTE: keys are strings).
    @@KEYWORDS = {
      'else' => :ELSE,   'and' => :AND,
      'or'   => :OR,     'is'  => :IS,
      'not'  => :NOT,    'mod' => :MOD,
      'to'   => :TO,
    }

    def initialize(source)
      @source = source
      @line, @column = 1, 1 # line and column are for humans, so start with 1
      @pos = 0
    end

    private def makeToken(type, value, length = value.size)
      Token.new(type, value, @line, @column, length)
    end

    private def consume(chunk)
      case chunk
      when /\A(;|=>?|<=|>=|\+=|\-=|\*=|\^=|,|\.)/
        makeToken($1.to_sym, $1)
      when /\A([\(\{\[\]\)\}\]\|])/
        makeToken($1.to_sym, $1)
      when /\A([\+\-\*\/\^><])/
        makeToken(:OP, $1)
      when /\A([a-zA-Z_][a-zA-Z0-9_]+|[a-zA-Z])/
        makeToken(@@KEYWORDS[$1] || :ID, $1)
      when /\A0(b)([01]+)/, /\A0(x|u)([0-9A-fa-f]+)/, /0(o)([0-7]+)/
        type = {'b' => :BIN, 'x' => :HEX, 'o' => :OCT, 'u' => :UNI}[$1]
        makeToken(type, $2, $&.size)
      when /\A([0-9]+\.[0-9])(e\-?[0-9]+)?/
        $2 ? makeToken(:SCI, $&) : makeToken(:FLOAT, $1)
      when /\A([1-9][0-9]*|0)/
        makeToken(:DECIMAL, $1)
      when /\A[\n]+/
        @line += $&.size
        @column = 1
        makeToken(:IGNORE, nil, $&.size)
      when /\A[ \t\r]+/
        makeToken(:IGNORE, nil, $&.size)
      else
        raise ApparatError.new("panic because of '#{chunk[0]}'", @line, @column)
      end
    end

    def scan
      tokens = []

      while @pos < @source.size
        token = consume(@source[@pos..])
        @pos += token.length
        @column += token.length
        tokens << token if token.type != :IGNORE
      end

      tokens.push makeToken(:EOF, '') # return the tokens plus the EOF marker
    end
  end
end

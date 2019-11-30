module Apparat
  # A uniform Reborn error.
  class Error < StandardError
    def initialize(message, line, column)
      @message = message
      @line = line
      @column = column
    end

    def to_s
      "#{@message} at line #{@line}, column #{@column}"
    end
  end
end

module Apparat
  class ApparatError < StandardError
    def initialize(message, line, column)
      @message = message
      @line = line
      @column = column
    end

    def to_s
      "#{@message.capitalize} at line #{@line}, column #{@column}"
    end
  end
end
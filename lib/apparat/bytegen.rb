module Apparat
  module Byte
    Instruction = Struct.new(:name, :arg, :line, :col)

    # The parent of some bytenodes to simplify their implementations.
    class Node
      def initialize(arg, line, col)
        @arg = arg
        @line = line
        @col = col
      end

      def make
        raise "Make not implemented for Node at #{@line}, #{@col}"
      end
    end

    # The bytenode for generating number PUSHes.
    class Number < Node
      def initialize(type, val, *tail)
        @type = type
        @val = val
        super(nil, *tail)
      end

      def make
        [Instruction.new("PUSH_#{@type}".upcase.to_sym, @val, @line, @col)]
      end
    end

    # The bytenode for generating REQ instruction.
    class Request < Node
      def make
        [Instruction.new(:REQ, @arg, @line, @col)]
      end
    end

    # The bytenode for generating LIST instruction.
    class List < Node
      def make
        [@arg.flatten.map(&:make),
         Instruction.new(:LIST, @arg.size.to_s, @line, @col)]
      end
    end

    # The bytenode for generating PUSH_CHAIN instruction.
    class Chain < Node
      def make
        [Instruction.new(:PUSH_CHAIN, @arg, @line, @col)]
      end
    end

    # The bytenode for generating TEXT instruction.
    class Text < Node
      def make
        [@arg.flatten.map(&:make),
         Instruction.new(:TEXT, @arg.size.to_s, @line, @col)]
      end
    end

    # The root bytenode for making a flat list of instructions.
    class Root
      def initialize(filename, nodes)
        @filename = filename
        @nodes = nodes
      end

      def make
        @nodes.map(&:make).flatten
      end
    end
  end
end

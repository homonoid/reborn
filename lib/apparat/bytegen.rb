module Apparat
  module Byte
    Instruction = Struct.new(:name, :arg, :line, :col, :provide_offset)

    # A parent for some uniform bytenodes.
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

    # The bytenode to issue various number PUSHes.
    class Number < Node
      def initialize(type, val, *tail)
        @type = type
        @val = val
        super(nil, *tail)
      end

      def make
        [Instruction.new("PUSH_#{@type}".upcase.to_sym, @val, @line, @col, 1)]
      end
    end

    # The bytenode to issue a REQ instruction.
    class Request < Node
      def make
        [Instruction.new(:REQ, @arg, @line, @col, 1)]
      end
    end

    # The bytenode to issue a LIST instruction.
    class List < Node
      def make
        [@arg.flatten.map(&:make),
         Instruction.new(:LIST, @arg.size, @line, @col, 0)]
      end
    end

    # The bytenode to issue a PUSH_CHAIN instruction.
    class Chain < Node
      def make
        [Instruction.new(:PUSH_CHAIN, @arg, @line, @col, 1)]
      end
    end

    # The bytenode to issue a TEXT instruction.
    class Text < Node
      def make
        [@arg.flatten.map(&:make),
         Instruction.new(:TEXT, @arg.size, @line, @col, 0)]
      end
    end

    # The bytenode to issue an instruction for +, - and ! (`not`) prefixes.
    class Unary < Node
      def make
        operand_instr = @arg[1].make
        prefix_instr = { '+' => :POS, '-' => :NEG, '!' => :INV }[@arg[0]]
        [operand_instr, Instruction.new(prefix_instr, nil, @line, @col, 0)]
      end
    end

    # The bytenode to issue a uniform binary instruction (with two operands)
    # TODO: evaluate some literals at compile-time for optimization?
    class Binary < Node
      private

      def opcode(infix)
        {
          'and' => :CONJ,
          'or' => :DISJ,

          'is' => :EQ,
          'is not' => :NEQ,
          'in' => :ISIN,
          'not in' => :NOTIN,

          '<' => :LT,
          '>' => :GT,
          '<=' => :LE,
          '>=' => :GE,

          '+' => :ADD,
          '-' => :SUB,
          '*' => :MUL,
          '/' => :DIV,
          'mod' => :MOD,

          '^' => :POW,
          'to' => :RANGE
        }[infix]
      end

      public

      def make
        left = @arg[1].make
        right = @arg[2].make
        [left, right, Instruction.new(opcode(@arg[0]), nil, @line, @col, 0)]
      end
    end

    # The root bytenode to issue a flat list of instructions.
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

# Reborn

Reborn is a work-in-progress implementation of the Apparat programming language in Ruby.

### Source

I am trying to keep the source compact but readable, thence balancing on an edge and trying not to fail the second.

### Usage

1. Trying the project does not require any additional stuff except the repository itself, and ruby (it has to support `..` slicing).
2. To run Reborn, invoke `bin/art`. You will observe its glorious REPL.
3. Type and see the bytecode of things that are currently available to be parsed/translated (see below), or errors and panics of things that are not, or, much worse, some bugs.
4. You can try making one or more filenames arguments of `bin/art`. It will do the same work as REPL, but for these files.
6. If you want to see the tokens instead of the bytecode listing, provide `bin/art` with `-scan` flag.

### Progress

- [x] Scan numbers (float, decimal hex, binary, octal, unicode).
- [x] Scan identifiers and keywords.
- [x] Scan operators, symbols and parentheses.
- [x] Scan ASCIIs.
- [x] Scan texts.
- [x] Scan comments.

**Scanner seems to work**

- [x] Parser utilities.
- [x] Able to parse identifiers.
- [x] Able to parse lists.
- [x] Able to parse numbers (decimal, float, hex, octal, binary, unicode, ascii, scientific, ...).
- [x] Able to parse texts and perceive interpolation as concatenation.
- [x] Able to parse prefixes (`not` and `+` and `-`)
- [x] Able to parse infixes (`+`, `-`, `*`, `/`, `mod`, `^`, `is`, `to`, etc.) with what
seems a correct precedence.
- [x] Able to generate bytecode for things above. It seems valid, 
yet until the actual VM set and working I can't say so for sure.
# Reborn

Reborn is a work-in-progress implementation of the Apparat programming language in Ruby.

# Source

I am trying to keep the source compact but readable, thence balancing on the edge and trying not to fail the second.

# Usage

1. Trying the project does not require any additional stuff except the repository itself.
2. General (and sole) debug entry for Reborn is `lib/apparat.rb`. It is... But it works!
3. Run it with `ruby lib/apparat.rb`, and observe the glorious repl. 
4. Type and see the bytecode of things that are currently available to be parsed (see below), or
errors and panics of things that are not.
5. You can try appending one or more filenames to the previous command (3), so `ruby lib/apparat.rb examples/hello.art` does the same work (4) but for the chosen file.
6. Scanner is completely working. If you want to see the tokens instead of the underdeveloped
bytecode, change the `JUST_SCAN` constant in `lib/apparat.rb` from `false` to `true`.

# Progress

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
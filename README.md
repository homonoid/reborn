# Reborn

Reborn is a work-in-progress implementation of the Apparat programming language in Ruby.

### Source

I am trying to keep the source compact but readable, thence balancing on the edge and trying not to fail the second.

**UPD**: May contain some unaesthetical / unreadable code, and I know it does. 
Yet I try really hard to make this unreadable code readable :) Try pronouncing it outloud -- for me that works.

### Usage

1. Trying the project does not require any additional stuff except the repository itself (and ruby, of course).
2. General (and sole) debug entry for Reborn is `lib/apparat.rb`. It is... But it works!
3. Run it with `ruby lib/apparat.rb`, and observe the glorious repl. 
4. Type and see the bytecode of things that are currently available to be parsed/translated (see below), or
errors and panics of things that are not, or, much worse, some bugs.
5. You can try appending one or more filenames to the previous command (3), so `ruby lib/apparat.rb examples/hello.art` does the same work (4) but for the chosen file.
6. Scanner is completely working. If you want to see the tokens instead of the underdeveloped
bytecode, change the `JUST_SCAN` constant in `lib/apparat.rb` from `false` to `true`.

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
- [x] Able to generate bytecode for things above. It seems valid, 
yet until the actual VM set and working I can't say so for sure.
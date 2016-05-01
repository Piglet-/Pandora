all: Lexer.hs
	ghc Pandora.hs 
	rm -v *.o *.hi

Lexer.hs: Lexer.x
	alex Lexer.x

clean:
	rm -v Pandora Lexer.hs *.o *.hi
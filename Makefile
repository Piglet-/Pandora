all: Lexer.hs 
	happy Parser.y
	ghc Pandora.hs 
	rm -v *.o *.hi

Lexer.hs: Lexer.x
	alex Lexer.x
	happy Parser.y


clean:
	rm -v Pandora Lexer.hs *.o *.hi
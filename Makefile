all:
	bison -d grammar.y
	flex flex.l
	gcc grammar.tab.c lex.yy.c -lfl -lm -o run
clean:
	rm grammar.tab.c lex.yy.c grammar.tab.h
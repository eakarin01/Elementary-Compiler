all:
	bison -d grammar.y
	flex flex.l
	gcc grammar.tab.c lex.yy.c -lfl -lm -o run
asm:
	nasm -felf64 test.asm
	ld test.o -o a.out
clean:
	rm grammar.tab.c lex.yy.c grammar.tab.h
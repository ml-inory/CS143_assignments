calc : y.tab.o lex.yy.o
	gcc -o calc y.tab.o lex.yy.o -ly -ll

lex.yy.c : calc.l y.tab.c
	flex calc.l

y.tab.c : calc.y
	bison -vdty calc.y

clean :
	rm -vf *.o
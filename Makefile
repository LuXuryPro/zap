CFLAGS=-g -O3

all: edge

edge: main.o edge.o
	cc ${CFLAGS} -o $@ $^

main.o: main.c
	cc ${CFLAGS} -g -c $^

edge.o: edge.s
	nasm -f elf64 $^

clear:
	rm *.o edge

.PHONY: all clear

CFLAGS=-g -O3

all: edge

edge: main.o canny.o
	cc ${CFLAGS} -o $@ $^

main.o: main.c
	cc ${CFLAGS} -g -c $^

canny.o: canny.s
	nasm -f elf64 $^

clear:
	rm *.o edge

.PHONY: all clear

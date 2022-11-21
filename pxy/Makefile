CC = gcc
CFLAGS = -O2 -g -Wall -std=c99

all: file_generator

file_generator: file_generator.c
	$(CC) $(CFLAGS) -o file_generator file_generator.c

clean:
	rm -f *~ *.pyc
	rm -rf response_files logs
	rm -rf source_files/random
	rm -rf get_files

superclean: clean
	rm -f file_generator

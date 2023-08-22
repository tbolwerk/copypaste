CC=gcc
CFLAGS=-framework ApplicationServices -framework Cocoa
SOURCES=copypaste.m
EXECUTABLE=copypaste

all: $(SOURCES)
	$(CC) $(SOURCES) $(CFLAGS) -o $(EXECUTABLE)

clean:
	rm $(EXECUTABLE)

CC=gcc
CFLAGS=-framework ApplicationServices -framework Carbon
SOURCES=copypaste.c
EXECUTABLE=copypaste

all: $(SOURCES)
	$(CC) $(SOURCES) $(CFLAGS) -o $(EXECUTABLE)

clean:
	rm $(EXECUTABLE)

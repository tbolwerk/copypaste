UNAME_S := $(shell uname -s)

CC = gcc
EXECUTABLE = copypaste

ifeq ($(UNAME_S), Darwin)
    CFLAGS = -framework ApplicationServices -framework Cocoa
    SOURCES = copypaste.m
else ifeq ($(UNAME_S), Linux)
    CFLAGS = -lX11 -lXi
    SOURCES = copypaste.c
endif

all:
ifeq ($(UNAME_S), Darwin)
	$(CC) $(SOURCES) $(CFLAGS) -o $(EXECUTABLE)
else
	$(CC) $(SOURCES) $(CFLAGS) -o $(EXECUTABLE)
endif

clean:
	rm -f $(EXECUTABLE)

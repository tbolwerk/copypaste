#define STACK_IMPL
#include "stack.h"
#define DYNAMIC_STRING_IMPL
#include "dynamic_string.h"
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>
#include <stdbool.h>

void get_clipboard_entry_filename(dynamic_string* ds, int timestamp);
void remove_clipboard_entry(int timestamp);
int extract_timestamp_from_filename(char* filename);
void add_clipboard_entry(Stack* stack, int timestamp);
void update_clipboard_entries(Stack* stack);
int get_index(int keyCode);
void copyToClipboard(const char *text);
char* readFile(const char *filename);
int copyToDisk();
void handle_key_event(bool cmd, bool shift, int keyCode);

#ifdef CORE_IMPL
bool isInFront = false;
char* content = NULL;
Stack stack = {};

void handle_key_event(bool cmd, bool shift, int keyCode)
{
    printf("%d,%d,%d\n",cmd, shift, keyCode);
    if(cmd && keyCode == 'C'){ // CMD + C (cmd && keyCode == kVK_ANSI_C) {
        printf("Copy to clipboard\n");
        copyToDisk();
    }
    
    initialize(&stack);
    update_clipboard_entries(&stack);

    if(cmd && shift && keyCode == 'V'){ // CMD + shift + V
 	    printf("open menu for selecting copied content");
    }

    if(cmd && isInFront){
        int index = get_index(keyCode) - 1;
        if(index >= 0 && index <= stack.top) {
            int timestamp = stack.data[stack.top - index];
            dynamic_string ds = {};
            get_clipboard_entry_filename(&ds, timestamp);
            content = readFile(ds.s);
            if(content != NULL){
               copyToClipboard(content);
            }
        }
    }
}

void get_clipboard_entry_filename(dynamic_string* ds, int timestamp)
{
    create_dynamic_string(ds, "copy_");
    int length = snprintf( NULL, 0, "%d", timestamp);
    char* str = malloc( length + 1 );
    snprintf( str, length + 1, "%d", timestamp);
    concat(str, ds);
    free(str);
    concat(".txt", ds);
}

void remove_clipboard_entry(int timestamp)
{
    dynamic_string ds = {};
    get_clipboard_entry_filename(&ds, timestamp);
    print_dynamic_string(&ds);
    remove(ds.s);
    free_dynamic_string(&ds);
}

int extract_timestamp_from_filename(char* filename)
{
    dynamic_string ds = {};
    create_dynamic_string(&ds, filename);
    drop(ds, &ds, 5);
    take(ds, &ds, ds.length - 4);
    int result;
    sscanf(ds.s,"%d", &result);
    free_dynamic_string(&ds);
    return result;
}

void add_clipboard_entry(Stack* stack, int timestamp){
    if(isFull(stack)){
        remove_clipboard_entry(stack->data[STACK_SIZE-1]);
    }
    push(stack, timestamp);
}

void update_clipboard_entries(Stack* stack)
{
    DIR *d;
    struct dirent *dir;
    d = opendir(".");

    if (d) {
        while ((dir = readdir(d)) != NULL) {
            if (strncmp(dir->d_name, "copy_", 5) == 0 && strstr(dir->d_name, ".txt")) {
                int timestamp = extract_timestamp_from_filename(dir->d_name);
                add_clipboard_entry(stack, timestamp);
            }
        }
        closedir(d);
    } else {
        perror("Error opening directory");
    }
}

int get_index(int keyCode)
{
    switch(keyCode){
        case 18:  return 1;
        case 19:  return 2;
        case 20:  return 3;
        case 21:  return 4;
        case 23:  return 5;
        case 22:  return 6;
        case 26:  return 7;
        case 28:  return 8;
        case 25:  return 9;
        case 29:  return 0;
    }
    return -1;
}

void copyToClipboard(const char *text)
{
    FILE *pipe = popen("pbcopy", "w");
    if (pipe == NULL) {
        perror("popen");
        return;
    }

    fprintf(pipe, "%s", text);
    pclose(pipe);
}

char* readFile(const char *filename)
{
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("fopen");
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *buffer = malloc(length + 1);
    if (buffer == NULL) {
        perror("malloc");
        fclose(file);
        return NULL;
    }

    fread(buffer, 1, length, file);
    buffer[length] = '\0';

    fclose(file);
    return buffer;
}

int copyToDisk()
{
    FILE *pb = popen("pbpaste", "r");

    char paste[MAX_SIZE] = {};
    if(pb == NULL){
        printf("Failed to run pbpaste");
        exit(1);
    }

    while(fgets(paste, sizeof(paste), pb) != NULL) {
        char filename[40] = {};
        struct tm *timenow = {0};

        time_t now = time(NULL);

        //strftime(filename, sizeof(filename), "copy_%Y-%m-%d_%H:%M:%S.txt", timenow);
        sprintf(filename, "copy_%ld.txt", now);
        FILE *history = fopen(filename, "a+");
        fputs(paste, history);
        fputs("\n", history);
        fclose(history);
    }
    pclose(pb);

	return 0;
}
#endif
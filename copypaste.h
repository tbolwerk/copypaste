#ifndef __COPY_PASTE_H__
#define __COPY_PASTE_H__

#define MAX_SIZE 100000
#include "stdio.h"
#include "stdlib.h"
#include <time.h>
#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <sys/types.h>
#include <unistd.h>
int update(void);
int eventTap(void);
CGEventRef CGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
int prev = -1;
CGEventFlags lastFlags = 0;
#endif



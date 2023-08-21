
#define STACK_SIZE 5
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int data[STACK_SIZE];
    int top;
} Stack;

void initialize(Stack* stack);
int isEmpty(Stack* stack);
int isFull(Stack* stack);
int exists(Stack* stack, int item);
void push(Stack* stack, int item);
void display(Stack* stack);

#ifdef STACK_IMPL
// Initialize the stack
void initialize(Stack* stack) {
    stack->top = -1;
}

// Check if the stack is empty
int isEmpty(Stack* stack) {
    return stack->top == -1;
}

// Check if the stack is full
int isFull(Stack* stack) {
    return stack->top == STACK_SIZE - 1;
}

// Check if an item exists in the stack
int exists(Stack* stack, int item) {
    for (int i = 0; i <= stack->top; ++i) {
        if (stack->data[i] == item) {
            return 1;
        }
    }
    return 0;
}

// Push an element onto the stack
void push(Stack* stack, int item) {
    if (exists(stack, item)) {
        printf("Item %d already exists.\n", item);
        return;
    }
    if (isFull(stack)) {
        // Remove the bottom element when the stack is full
        for (int i = 0; i < stack->top; ++i) {
            stack->data[i] = stack->data[i + 1];
        }
        stack->top--;
    }
    stack->data[++stack->top] = item;
}

// Display the stack
void display(Stack* stack) {
    if (isEmpty(stack)) {
        printf("Stack is empty.\n");
        return;
    }
    for (int i = 0; i <= stack->top; ++i) {
        printf("%d ", stack->data[i]);
    }
    printf("\n");
}
#endif
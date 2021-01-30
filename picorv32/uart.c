#include "uart.h"

static volatile char *uart_tx = (char*)0x20000000;

void print_char(char c) {
    while (*uart_tx != 1);
    *uart_tx = c;
}

void puts(const char *s) {
    for (int i = 0; s[i] != '\0'; i++) print_char(s[i]);
    print_char('\n');
}

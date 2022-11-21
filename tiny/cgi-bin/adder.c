/*
 * adder.c - a minimal CGI program that adds two numbers together
 */
/* $begin adder */
#include "csapp.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *buf, *p;
    char content[MAXLINE];
    int n1=0, n2=0;

    /* Extract the two arguments */
    if ((buf = getenv("QUERY_STRING")) != NULL) {
        p = strchr(buf, '&');
        if (p != NULL) {
            *p = '\0';
            n1 = atoi(buf);
            n2 = atoi(p+1);
        }
    }

    /* Make the response body */
    snprintf(content, sizeof(content),
        "Welcome to add.com: "
        "THE Internet addition portal.\r\n<p>"
        "The answer is: %d + %d = %d\r\n<p>"
        "Thanks for visiting!\r\n",
        n1, n2, n1 + n2);

    /* Generate the HTTP response */
    printf("Connection: close\r\n");
    printf("Content-length: %zu\r\n", strlen(content));
    printf("Content-type: text/html\r\n");
    printf("\r\n");
    printf("%s", content);
    fflush(stdout);

    exit(0);
}
/* $end adder */

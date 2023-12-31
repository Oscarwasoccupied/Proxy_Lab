/* A concurrent web proxy with cache. It accepts connections from clients,
 * and parse request from client and send it to the server.
 * It can create different threads to handle requests, and will store
 * request response pair in cache, based on LRU.
 *
 * Author: Xianwei Zou
 * Andrew ID: xianweiz
 *
 * Reference: CSAPP Chapter 10-12
 */
/* Some useful includes to help you get started */
#include "cache.h"
#include "csapp.h"
#include "http_parser.h"
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <netdb.h>
#include <netinet/in.h>
#include <pthread.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
/*
 * Debug macros, which can be enabled by adding -DDEBUG in the Makefile
 * Use these if you find them useful, or delete them if not
 */
#ifdef DEBUG
#define dbg_assert(...) assert(__VA_ARGS__)
#define dbg_printf(...) fprintf(stderr, __VA_ARGS__)
#else
#define dbg_assert(...)
#define dbg_printf(...)
#endif
/*
 * String to use for the User-Agent header.
 * Don't forget to terminate with \r\n
 */
static const char *header_user_agent = "Mozilla/5.0"
                                       " (X11; Linux x86_64; rv:3.10.0)"
                                       " Gecko/20191101 Firefox/63.0.1";
static const char *CONNECT_HEADER = "Connection: close\r\n";
static const char *PROXY_HEADER = "Proxy-Connection: close\r\n";
static const char *HOST_HEADER = "Host: %s:%s\r\n";
static const char *REQUESTLINE_HEADER = "GET %s HTTP/1.0\r\n";
static const char *END_OF_LINE = "\r\n";
#define HOSTLEN 256
#define SERVLEN 8
/* Typedef for convenience */
typedef struct sockaddr SA;
/* Function Declaration */
void doit(int fd);
void clienterror(int fd, char *cause, char *errnum, char *shortmsg,
                 char *longmsg);
void forward_header(char *http_header, char *host, char *path, char *port,
                    rio_t client_rio);
/**
 * @brief Display the error message for the client.
 * Reference from CSAPP Figure 11.31
 */
void clienterror(int fd, char *cause, char *errnum, char *shortmsg,
                 char *longmsg) {
    char buf[MAXLINE], body[MAXBUF];
    /* Build the HTTP response body */
    sprintf(body, "<html><title>Tiny Error</title>");
    sprintf(body,
            "%s<body bgcolor="
            "ffffff"
            ">\r\n",
            body);
    sprintf(body, "%s%s: %s\r\n", body, errnum, shortmsg);
    sprintf(body, "%s<p>%s: %s\r\n", body, longmsg, cause);
    sprintf(body, "%s<hr><em>The Tiny Web server</em>\r\n", body);
    /* Print the HTTP response */
    sprintf(buf, "HTTP/1.0 %s %s\r\n", errnum, shortmsg);
    rio_writen(fd, buf, strlen(buf));
    sprintf(buf, "Content-type: text/html\r\n");
    rio_writen(fd, buf, strlen(buf));
    sprintf(buf, "Content-length: %d\r\n\r\n", (int)strlen(body));
    rio_writen(fd, buf, strlen(buf));
    rio_writen(fd, body, strlen(body));
}
/**
 * @brief Forward header from the client to the server
 *
 */
void forward_header(char *http_header, char *host, char *path, char *port,
                    rio_t client_rio) {
    char request_header[MAXLINE], host_header[MAXLINE], user_header[MAXLINE],
        other_header[MAXLINE], buf[MAXLINE];
    sprintf(request_header, REQUESTLINE_HEADER, path);
    while (rio_readlineb(&client_rio, buf, MAXLINE) > 0) {
        int not_end = strcmp(buf, END_OF_LINE);
        if (not_end) {
            if (strstr(buf, "Host")) {
            } else if (strstr(buf, "Connection")) {
            } else if (strstr(buf, "User-Agent")) {
            } else if (strstr(buf, "Proxy-Connection")) {
            } else {
                strcat(other_header, buf);
            }
        } else {
            sprintf(host_header, HOST_HEADER, host, port);
            sprintf(user_header, "User-Agent: %s\r\n", header_user_agent);
            sprintf(http_header, "%s%s%s%s%s%s%s", request_header, host_header,
                    user_header, CONNECT_HEADER, PROXY_HEADER, other_header,
                    END_OF_LINE);
            return;
        }
    }
}
/**
 * @brief Core part of the proxy
 * Reference CSAPP Figure 11.0
 *
 */
void doit(int fd) {
    char buf[MAXLINE], method[MAXLINE], uri[MAXLINE], version[MAXLINE],
        cachebuf[MAX_OBJECT_SIZE];
    rio_t client_rio, server_rio;
    int clientfd;
    char *server_hostname;
    char *server_path;
    char *server_port;
    char http_header[MAXLINE];
    /* Read request line and headers */
    rio_readinitb(&client_rio, fd);
    rio_readlineb(&client_rio, buf, MAXLINE);
    if (sscanf(buf, "%s %s %s", method, uri, version) < 3) {
        clienterror(fd, method, "400", "Bad Request", "Error parsing request");
        return;
    };
    if (strcasecmp(method, "GET")) {
        clienterror(fd, method, "501", "Not implemented",
                    "Proxy does not implement this method");
        return;
    }
    // if the the content of uri is already in the cache
    // send the body directly to clients, otherwise, cache
    if (cache_check(fd, uri)) {
        return;
    }
    /* Parse request from URI */
    parser_t *parser;
    parser = parser_new();
    parser_parse_line(parser, buf);
    parser_retrieve(parser, HOST, (const char **)&server_hostname);
    parser_retrieve(parser, PATH, (const char **)&server_path);
    parser_retrieve(parser, PORT, (const char **)&server_port);
    clientfd = open_clientfd(server_hostname, server_port);
    if (clientfd < 0) {
        return;
    }
    rio_readinitb(&server_rio, clientfd);
    forward_header(http_header, server_hostname, server_path, server_port,
                   client_rio);
    rio_writen(clientfd, http_header, strlen(http_header));
    size_t n;
    size_t totalsize_cache = 0;
    while ((n = rio_readnb(&server_rio, buf, MAXLINE)) != 0) {
        rio_writen(fd, buf, n);
        if (totalsize_cache + n <= MAX_OBJECT_SIZE) {
            memcpy(cachebuf + totalsize_cache, buf, n);
        }
        totalsize_cache += n;
    }
    /* cache */
    if (totalsize_cache <= MAX_OBJECT_SIZE) {
        cache_insert(uri, cachebuf, totalsize_cache);
    }
    close(clientfd);
    parser_free(parser);
}
/**
 * @brief Ignore SIGPIPE signal
 *
 */
void sigpipt_handler(int sig) {
    return;
}
/**
 * @brief Define a single thread.
 *
 */
void *thread(void *vargp) {
    pthread_detach(pthread_self());
    int connfd = *(int *)vargp;
    doit(connfd);
    close(connfd);
    return NULL;
}
/**
 * @brief main function
 * (Structrue reference from CSAPP Figure 11.29)
 */
int main(int argc, char **argv) {
    int listenfd, connfd;
    char hostname[MAXLINE], port[MAXLINE];
    socklen_t clientlen;
    struct sockaddr_storage clientaddr;
    pthread_t tid;
    /* Although the default action for a process
     * that receives SIGPIPE is to terminate,
     * your proxy should not terminate due to that signal. */
    Signal(SIGPIPE, sigpipt_handler);
    /* Check command-line args */
    if (argc != 2) {
        fprintf(stderr, "usage: %s <port>\n", argv[0]);
        exit(1);
    }
    listenfd = open_listenfd(argv[1]);
    // initial cache
    cache_init();
    while (1) {
        clientlen = sizeof(clientaddr);
        connfd = accept(listenfd, (SA *)&clientaddr, &clientlen);
        int *fdpointer = malloc(sizeof(connfd));
        *fdpointer = connfd;
        getnameinfo((SA *)&clientaddr, clientlen, hostname, MAXLINE, port,
                    MAXLINE, 0);
        sio_printf("Accepted connection from (%s, %s)\n", hostname, port);
        pthread_create(&tid, NULL, thread, fdpointer);
    }
    return 0;
}

/*
 * tiny-static.c - A simple, iterative HTTP/1.0 Web server that uses the
 *     GET method to serve the same static content regardless of the request.
 *
 * Updated 04/2017 - Stanley Zhang <szz@andrew.cmu.edu>
 * Fixed some style issues, stop using csapp functions where not appropriate
 */

#include "csapp.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <netdb.h>

#define HOSTLEN 256
#define SERVLEN 8

/* Typedef for convenience */
typedef struct sockaddr SA;

/* Information about a connected client. */
typedef struct {
    struct sockaddr_in addr;    // Socket address
    socklen_t addrlen;          // Socket address length
    int connfd;                 // Client connection file descriptor
    char host[HOSTLEN];         // Client host
    char serv[SERVLEN];         // Client service (port)
} client_info;

/* URI parsing results. */
typedef enum {
    PARSE_ERROR,
    PARSE_STATIC,
    PARSE_DYNAMIC
} parse_result;

/*
 * read_requesthdrs - read HTTP request headers
 * Returns true if an error occurred, or false otherwise.
 */
bool read_requesthdrs(rio_t *rp) {
    char buf[MAXLINE];

    do {
        if (rio_readlineb(rp, buf, MAXLINE) <= 0) {
            return true;
        }

        printf("%s", buf);
    } while(strncmp(buf, "\r\n", sizeof("\r\n")));

    return false;
}


/*
 * parse_uri - parse URI into filename and CGI args
 *
 * uri - The buffer containing URI. Must contain a NUL-terminated string.
 * filename - The buffer into which the filename will be placed.
 * cgiargs - The buffer into which the CGI args will be placed.
 * NOTE: All buffers must hold MAXLINE bytes, and will contain NUL-terminated
 * strings after parsing.
 *
 * Returns the appropriate parse result for the type of request.
 */
parse_result parse_uri(char *uri, char *filename, char *cgiargs) {
    /* Check if the URI contains "cgi-bin" */
    if (strstr(uri, "cgi-bin")) { /* Dynamic content */
        char *args = strchr(uri, '?');  /* Find the CGI args */
        if (!args) {
            *cgiargs = '\0';    /* No CGI args */
        } else {
            /* Format the CGI args */
            if (snprintf(cgiargs, MAXLINE, "%s", args + 1) >= MAXLINE) {
                return PARSE_ERROR; // Overflow!
            }

            *args = '\0';   /* Remove the args from the URI string */
        }

        /* Format the filename */
        if (snprintf(filename, MAXLINE, ".%s", uri) >= MAXLINE) {
            return PARSE_ERROR; // Overflow!
        }

        return PARSE_DYNAMIC;
    }

    /* Static content */
    /* No CGI args */
    *cgiargs = '\0';

    /* Check if the client is requesting a directory */
    bool is_dir = uri[strnlen(uri, MAXLINE) - 1] == '/';

    /* Format the filename; if requesting a directory, use the home file */
    if (snprintf(filename, MAXLINE, ".%s%s",
                uri, is_dir ? "home.html" : "") >= MAXLINE) {
        return PARSE_ERROR; // Overflow!
    }

    return PARSE_STATIC;
}

/*
 * get_filetype - derive file type from file name
 *
 * filename - The file name. Must be a NUL-terminated string.
 * filetype - The buffer in which the file type will be storaged. Must be at
 * least MAXLINE bytes. Will be a NUL-terminated string.
 */
void get_filetype(char *filename, char *filetype) {
    if (strstr(filename, ".html")) {
        strcpy(filetype, "text/html");
    } else if (strstr(filename, ".gif")) {
        strcpy(filetype, "image/gif");
    } else if (strstr(filename, ".png")) {
        strcpy(filetype, "image/png");
    } else if (strstr(filename, ".jpg")) {
        strcpy(filetype, "image/jpeg");
    } else {
        strcpy(filetype, "text/plain");
    }
}


/*
 * serve_static - copy a file back to the client
 */
void serve_static(int fd, char *filename, int filesize) {
    int srcfd;
    char *srcp;
    char filetype[MAXLINE];
    char buf[MAXBUF];
    size_t buflen;

    get_filetype(filename, filetype);

    /* Send response headers to client */
    buflen = snprintf(buf, MAXBUF,
            "HTTP/1.0 200 OK\r\n" \
            "Server: Tiny Web Server\r\n" \
            "Connection: close\r\n" \
            "Content-Length: %d\r\n" \
            "Content-Type: %s\r\n\r\n", \
            filesize, filetype);
    if (buflen >= MAXBUF) {
        return; // Overflow!
    }

    printf("Response headers:\n%s", buf);

    if (rio_writen(fd, buf, buflen) < 0) {
        fprintf(stderr, "Error writing static response headers to client\n");
    }


    /* Send response body to client */
    srcfd = open(filename, O_RDONLY, 0);
    if (srcfd < 0) {
        perror(filename);
        return;
    }

    srcp = mmap(0, filesize, PROT_READ, MAP_PRIVATE, srcfd, 0);
    if (srcp == MAP_FAILED) {
        perror("mmap");
        close(srcfd);
        return;
    }
    close(srcfd);

    if (rio_writen(fd, srcp, filesize) < 0) {
        fprintf(stderr, "Error writing static file \"%s\" to client\n",
                filename);
        // Fall through to cleanup
    }

    if (munmap(srcp, filesize) < 0) {
        perror("munmap");
        return;
    }
}

/*
 * clienterror - returns an error message to the client
 */
void clienterror(int fd, char *cause, char *errnum,
        char *shortmsg, char *longmsg) {
    char buf[MAXLINE];
    char body[MAXBUF];
    size_t buflen;
    size_t bodylen;

    /* Build the HTTP response body */
    bodylen = snprintf(body, MAXBUF,
            "<!DOCTYPE html>\r\n" \
            "<html>\r\n" \
            "<head><title>Tiny Error</title></head>\r\n" \
            "<body bgcolor=\"ffffff\">\r\n" \
            "<h1>%s: %s</h1>\r\n" \
            "<p>%s: %s</p>\r\n" \
            "<hr /><em>The Tiny Web server</em>\r\n" \
            "</body></html>\r\n", \
            errnum, shortmsg, longmsg, cause);
    if (bodylen >= MAXBUF) {
        return; // Overflow!
    }

    /* Build the HTTP response headers */
    buflen = snprintf(buf, MAXLINE,
            "HTTP/1.0 %s %s\r\n" \
            "Content-Type: text/html\r\n" \
            "Content-Length: %zu\r\n\r\n", \
            errnum, shortmsg, bodylen);
    if (buflen >= MAXLINE) {
        return; // Overflow!
    }

    /* Write the headers */
    if (rio_writen(fd, buf, buflen) < 0) {
        fprintf(stderr, "Error writing error response headers to client\n");
        return;
    }

    /* Write the body */
    if (rio_writen(fd, body, bodylen) < 0) {
        fprintf(stderr, "Error writing error response body to client\n");
        return;
    }
}

/*
 * serve - handle one HTTP request/response transaction
 */
void serve(client_info *client) {
    // Get some extra info about the client (hostname/port)
    // This is optional, but it's nice to know who's connected
    int res = getnameinfo(
            (SA *) &client->addr, client->addrlen,
            client->host, sizeof(client->host),
            client->serv, sizeof(client->serv),
            0);
    if (res == 0) {
        printf("Accepted connection from %s:%s\n", client->host, client->serv);
    }
    else {
        fprintf(stderr, "getnameinfo failed: %s\n", gai_strerror(res));
    }

    rio_t rio;
    rio_readinitb(&rio, client->connfd);

    /* Read request line */
    char buf[MAXLINE];
    if (rio_readlineb(&rio, buf, MAXLINE) <= 0) {
        return;
    }

    printf("%s", buf);

    /* Parse the request line and check if it's well-formed */
    char method[MAXLINE];
    char uri[MAXLINE];
    char version;

    /* sscanf must parse exactly 3 things for request line to be well-formed */
    /* version must be either HTTP/1.0 or HTTP/1.1 */
    if (sscanf(buf, "%s %s HTTP/1.%c", method, uri, &version) != 3
            || (version != '0' && version != '1')) {
        clienterror(client->connfd, buf, "400", "Bad Request",
                "Tiny received a malformed request");
        return;
    }

    /* Check that the method is GET */
    if (strncmp(method, "GET", sizeof("GET"))) {
        clienterror(client->connfd, method, "501", "Not Implemented",
                "Tiny does not implement this method");
        return;
    }

    /* Check if reading request headers caused an error */
    if (read_requesthdrs(&rio)) {
        return;
    }

    /* Parse URI from GET request */
    char filename[MAXLINE], cgiargs[MAXLINE];
    parse_result result = parse_uri(uri, filename, cgiargs);
    if (result == PARSE_ERROR) {
        clienterror(client->connfd, uri, "400", "Bad Request",
                "Tiny could not parse the request URI");
        return;
    }


    /* Attempt to stat the file */
    struct stat sbuf;
    if (stat("home.html", &sbuf) < 0) {
        clienterror(client->connfd, "home.html", "404", "Not found",
                "Tiny couldn't find this file");
        return;
    }

    serve_static(client->connfd, "home.html", sbuf.st_size);
}

int main(int argc, char **argv) {
    int listenfd;

    /* Check command line args */
    if (argc != 2) {
        fprintf(stderr, "usage: %s <port>\n", argv[0]);
        exit(1);
    }

    listenfd = open_listenfd(argv[1]);
    if (listenfd < 0) {
        fprintf(stderr, "Failed to listen on port: %s\n", argv[1]);
        exit(1);
    }

    while (1) {
        /* Allocate space on the stack for client info */
        client_info client_data;
        client_info *client = &client_data;

        /* Initialize the length of the address */
        client->addrlen = sizeof(client->addr);

        /* accept() will block until a client connects to the port */
        client->connfd = accept(listenfd,
                (SA *) &client->addr, &client->addrlen);
        if (client->connfd < 0) {
            perror("accept");
            continue;
        }

        /* Connection is established; serve client */
        serve(client);
        close(client->connfd);
    }
}


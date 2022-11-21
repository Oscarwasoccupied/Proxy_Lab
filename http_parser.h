/**
 * @file http_parser.h
 * @brief Interface for HTTP parser
 *
 * This library is intended to be used to parse HTTP requests for CMU's 15-213
 * proxylab.
 *
 * When using the parser library, strings that are given to the parser by a
 * caller are still owned by the caller, and therefore should be cleaned up by
 * the caller. The values stored in the parser will still be vaild if the
 * strings given to the parser are freed or go out of scope. Strings either
 * returned by parser functions or given to a caller as an output parameter are
 * cleaned up by the parser when parser_free() is called, these strings should
 * not be modified by callers of parser functions.
 */

#ifndef __HTTP_PARSER_H__
#define __HTTP_PARSER_H__

#define MAXNAME 256
#define PARSER_MAXLINE 4096

typedef struct parser parser_t;

/**
 * @brief A struct to store a parsed HTTP header
 *
 * Note that the values in this struct are just a header's name and value, so
 * no colon is included. For example, if the header "Connection: close\r\n" was
 * parsed, this struct would store "Connection" and "close" as the name and
 * value fields respectively.
 *
 * When this struct is returned from a parser function, the fields should not be
 * modified by the user of the struct.
 */
typedef struct header {
    const char *name;  /**< the name of the header */
    const char *value; /**< the value of the header */
} header_t;

/**
 * @brief Different states the parse can be in
 *
 * After calling `parser_parse_line` the parser will return one of these states.
 */
typedef enum parser_state {
    REQUEST, /**< parsed request line */
    HEADER,  /**< parsed an HTTP header */
    ERROR    /**< an error occurred */
} parser_state;

/**
 * @brief Types of values the parser can store
 *
 * These can be passed to `parser_retrieve` in order to fetch a specific value
 * from the parser.
 */
typedef enum parser_value {
    METHOD,      /**< HTTP request method, e.g. GET or POST */
    HOST,        /**< a network host, e.g. cs.cmu.edu */
    SCHEME,      /**< scheme to connect over, e.g. http or https */
    URI,         /**< the entire URI */
    PORT,        /**< The port to connect on, by default 80 */
    PATH,        /**< The path to find a resource, e.g. index.html */
    HTTP_VERSION /**< The HTTP version without the HTTP/, e.g. 1.0 or 1.1 */
} parser_value_type;

/**
 * @brief Initialize a parser
 *
 * This must be called before using any parser functions
 *
 * @return The parser
 */
parser_t *parser_new(void);

/**
 * @brief Destroy a parser
 *
 * This must be called after finished using the parser to free its memory
 *
 * @param[in] p The parser to be destroyed
 */
void parser_free(parser_t *p);

/**
 * @brief Parse a line of an HTTP request
 *
 * The line given to this function should be one line from an HTTP request, i.e.
 * a request line or a header. It does not matter if the line ends with '\r\n'
 * or not, the parser will treat the line the same either way.
 *
 * After calling this function, the caller should ensure that the state the
 * parser returns is the one that is expected.
 *
 * @param[in] p The parser
 * @param[in] line The line to be parsed
 *
 * @pre Lines must be less than or equal to PARSER_MAXLINE
 *
 * @return The state of the parser
 */
parser_state parser_parse_line(parser_t *p, const char *line);

/**
 * @brief Retrieve a parsed field
 *
 * Use this function to get a value that has been parsed by the parser. The
 * values that can be obtained from this function are the same as the values
 * in the enum `parser_value_type`. This function should only be called after a
 * value has been parsed by the parser, in most cases this will be by parsing
 * the initial HTTP request line.
 *
 * The output parameter val is used to store a pointer to the parser owned
 * string that contains the value being requested. So in order to use this
 * function, the variable given for val should be a const char * pointer, likely
 * declared on the stack, and the address should be given to the function. For
 * example:
 *
 * const char *myval;
 * if (parser_retrieve(parser, METHOD, &myval) < 0) {
 *   // handle errors
 * }
 *
 * @param[in] p The parser
 * @param[in] type the value to retrieve
 * @param[out] val a pointer to the value that is retrieved
 *
 * @return 0 on success
 * @return -2 if the requested type has not been parsed
 * @return -1 any other error
 */
int parser_retrieve(parser_t *p, parser_value_type type, const char **val);

/**
 * @brief Retrieve a specific header
 *
 * Use this function to find the value of a specific header that has been parsed
 * by the parser.
 *
 * Note that this function has an O(n) cost (w.r.t. number of headers) as all
 * stored headers have to be searched.
 *
 * @param[in] p The parser
 * @param[in] name The name of the header being looked up
 *
 * @return NULL on error or if the header has not been stored
 * @return a pointer to a header_t struct otherwise
 */
header_t *parser_lookup_header(parser_t *p, const char *name);

/**
 * @brief Iterate over stored headers
 *
 * Use this function to iterate over all headers stored by the parser.
 *
 * Note that this function does not guarantee that the headers that are returned
 * in the same order that they are given to the parser.
 *
 * The iterator will not restart after reaching the end of the headers, but if
 * a new header is parsed after reaching the last stored header, it can be
 * retrieved using this function.
 *
 * @param[in] p The parser
 * @param[out] name A pointer to the header's name
 * @param[out] value A pointer to the header's value
 *
 * @return NULL if there are no more headers left or if there was an error
 * @return a pointer to a header_t struct otherwise
 */
header_t *parser_retrieve_next_header(parser_t *p);

#endif /* __HTTP_PARSER_H__ */


/**
 * @file cache.h
 * @author Xianwei Zou
 * @brief A cache keeps recently used Web objects in memory.
 * Proxy cache employ a least recently used (LRU) eviction policy
 */
#include "csapp.h"
#include "http_parser.h"
#include <assert.h>
#include <ctype.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
/*
 * Max cache and object sizes
 * You might want to move these to the file containing your cache implementation
 */
#define MAX_CACHE_SIZE (1024 * 1024)
#define MAX_OBJECT_SIZE (100 * 1024)
// Cache block structure for one url
typedef struct cache_block_t {
    char *url;                  // url: host + port + path
    char *body;                 // body of the web object
    size_t size;                // size of this block
    int LRU_cnt;                // timer used to find LRU, longer, bigger
    int thread_cnt;             // number of threads currently using this block
    struct cache_block_t *next; // pointer to next block
    struct cache_block_t *prev; // pointer to the prev block
} cache_block_t;
/**
 * @brief Inintialize the cache linked list
 */
void cache_init();
/**
 * @brief Free the cache linked list.
 * @param block
 */
void cache_block_free(cache_block_t *block);
/**
 * @brief Get the least recent use block.
 * The block that has the largest LRU_cnt value.
 */
cache_block_t *LRU_get();
/**
 * @brief Incease the timer for all blocks in the linked list.
 */
void increase_time();
/**
 * @brief Find if the url content is in the cache.
 * If not, return NULL. If in the cache, return the block.
 *
 * @param url
 */
cache_block_t *cache_block_find(char *url);
/**
 * @brief Inert a block into cache linked list
 *
 * @param block
 */
void insert_head(cache_block_t *block);
/**
 * @brief Insert a new data into cache.
 */
void cache_insert(char *url, char *body, size_t size);
/**
 * @brief Remove the block that content has not been used for the
 * longest time amoung all blocks.
 *
 * @param size
 */
void cache_block_evict(size_t size);
/**
 * @brief Sent data directly to client if it is in the cache.
 *
 * @return false if not found in cache
 */
bool cache_check(int fd, char *url);

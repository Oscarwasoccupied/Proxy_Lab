#include "cache.h"
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
static pthread_mutex_t cacheLock;
size_t total_cache_size;
cache_block_t *head;
/**
 * @brief Inintialize the cache linked list
 *
 */
void cache_init() {
    total_cache_size = 0;
    head = NULL;
    // Initialize the cache lock
    pthread_mutex_init(&cacheLock, NULL);
}
/**
 * @brief Free the cache linked list.
 *
 * @param block
 */
void cache_block_free(cache_block_t *block) {
    if (block == NULL) {
        return;
    } else {
        free(block->url);
        free(block->body);
        free(block);
    }
    return;
}
/**
 * @brief Inert a block into cache linked list
 *
 * @param block
 */
void insert_head(cache_block_t *block) {
    // Check empty
    if (head == NULL) {
        total_cache_size = total_cache_size + block->size;
        head = block;
        block->prev = NULL;
        block->next = NULL;
        return;
    }

    // insert to head
    cache_block_t *tmp = head;
    head = block;
    block->next = tmp;
    block->prev = NULL;
    total_cache_size = total_cache_size + block->size;
    return;
}
/**
 * @brief Insert a new data into cache.
 */
void cache_insert(char *url, char *body, size_t size) {
    pthread_mutex_lock(&cacheLock);
    increase_time();
    if (cache_block_find(url) != NULL) {
        pthread_mutex_unlock(&cacheLock);
        return;
    }
    cache_block_t *new_block = (cache_block_t *)malloc(sizeof(cache_block_t));
    char *bodycpy = (char *)malloc(size);
    memcpy(bodycpy, body, size); // copy body
    new_block->body = bodycpy;
    char *urlcpy = (char *)malloc(strlen(url) + 1);
    strcpy(urlcpy, url); // copy url
    new_block->url = urlcpy;
    new_block->LRU_cnt = 0;
    new_block->thread_cnt = 1;
    new_block->size = size;
    new_block->next = NULL;
    new_block->prev = NULL;
    // Check full
    // Cache is full, need to remove block
    if (total_cache_size + new_block->size > MAX_CACHE_SIZE) {
        cache_block_evict(new_block->size);
    }
    insert_head(new_block); // cache the body into block
    pthread_mutex_unlock(&cacheLock);
}
/**
 * @brief Remove the block that content has not been used for the
 * longest time amoung all blocks.
 *
 * @param size
 */
void cache_block_evict(size_t size) {
    while (true) {
        if (total_cache_size + size <= MAX_CACHE_SIZE) {
            break;
        }
        cache_block_t *LRU_block = LRU_get();
        cache_block_t *prev_block = NULL;
        // find the previous web obejct of LRU_block
        cache_block_t *tmp;
        // if not head
        int not_equal = strcmp(head->url, LRU_block->url);
        if (not_equal) {
            for (tmp = head; tmp != NULL; tmp = tmp->next) {
                int found = !strcmp(tmp->next->url, LRU_block->url);
                if (found) {
                    prev_block = tmp;
                    break;
                }
            }
        } else { // head
            prev_block = NULL;
        }
        // find the next web object of LRU_block
        cache_block_t *next_block = LRU_block->next;
        // remove the LRU_block from the web cache list
        // if head
        if (prev_block == NULL) {
            head = next_block;
            LRU_block->next = NULL;
        } else { // not head
            prev_block->next = next_block;
            LRU_block->next = NULL;
        }
        total_cache_size = total_cache_size - LRU_block->size;
        LRU_block->thread_cnt = LRU_block->thread_cnt - 1;
        // Free block
        cache_block_free(LRU_block);
    }
}
/**
 * @brief Incease the timer for all blocks in the linked list.
 */
void increase_time() {
    cache_block_t *tmp;
    for (tmp = head; tmp != NULL; tmp = tmp->next) {
        tmp->LRU_cnt = tmp->LRU_cnt + 1;
    }
    return;
}
/**
 * @brief Get the least recent use block.
 * The block that has the largest LRU_cnt value.
 */
cache_block_t *LRU_get() {
    // check empty
    if (head == NULL) {
        return NULL;
    }

    int max_cnt = 0;
    cache_block_t *max = head;
    cache_block_t *tmp;
    for (tmp = head; tmp != NULL; tmp = tmp->next) {
        if (max_cnt <= tmp->LRU_cnt) {
            max_cnt = tmp->LRU_cnt;
            max = tmp;
        }
    }
    return max;
}
/**
 * @brief Sent data directly to client if it is in the cache.
 *
 * @return false if not found in cache
 */
bool cache_check(int fd, char *url) {
    pthread_mutex_lock(&cacheLock);
    increase_time();
    cache_block_t *block = cache_block_find(url);
    // found in the cache
    if (block != NULL) {
        block->thread_cnt = block->thread_cnt + 1;
        block->LRU_cnt = 0; // use, update time
        pthread_mutex_unlock(&cacheLock);
        rio_writen(fd, block->body, block->size); // send directly to client
        block->thread_cnt = block->thread_cnt - 1;
        return true;
    } else { // not found
        pthread_mutex_unlock(&cacheLock);
        return false;
    }
}
/**
 * @brief Find if the url content is in the cache.
 * If not, return NULL. If in the cache, return the block.
 *
 * @param url
 */
cache_block_t *cache_block_find(char *url) {
    cache_block_t *tmp = head;
    for (tmp = head; tmp != NULL; tmp = tmp->next) {
        int matched = !strncmp(tmp->url, url, strlen(url));
        if (matched) {
            return tmp;
        }
    }
    return NULL;
}

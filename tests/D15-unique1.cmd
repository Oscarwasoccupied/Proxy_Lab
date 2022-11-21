# Make sure cache holds at most one copy of a file
serve s1
generate random-text00.txt 100K
generate random-text01.txt 100K
generate random-text02.txt 100K
generate random-text03.txt 100K
# Use 300K of cache
fetch f00 random-text00.txt s1
fetch f01 random-text01.txt s1
fetch f02 random-text02.txt s1
wait *
check f00
check f01
check f02
# Make 10 requests of same file
# If each copy gets cached, that would fill up cache
# and cause older files to be evicted
request r03a random-text03.txt s1
request r03b random-text03.txt s1
request r03c random-text03.txt s1
request r03d random-text03.txt s1
request r03e random-text03.txt s1
request r03f random-text03.txt s1
request r03g random-text03.txt s1
request r03h random-text03.txt s1
request r03i random-text03.txt s1
request r03j random-text03.txt s1
wait *
# These responses are all of the same file.  Only one should be cached
# Out of order response will cause sequential proxy to fail
respond r03f r03g r03h r03i r03j
respond r03a r03b r03c r03d r03e
wait *
check r03a
check r03b
check r03c
check r03d
check r03e
check r03f
check r03g
check r03h
check r03i
check r03j
# These should still be in the cache
request r00a random-text00.txt s1
request r01a random-text01.txt s1
request r02a random-text02.txt s1
wait *
check r00a
check r01a
check r02a
delete random-text00.txt
delete random-text01.txt
delete random-text02.txt
delete random-text03.txt
quit



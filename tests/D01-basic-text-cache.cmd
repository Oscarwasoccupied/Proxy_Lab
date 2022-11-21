# Test use of cache
# This test can be passed by a sequential proxy
serve s1
generate random-text1.txt 10K
generate random-text2.txt 10K
request r1a random-text1.txt s1
wait *
respond r1a
wait *
check r1a
fetch f2 random-text2.txt s1
wait *
check f2
request r1b random-text1.txt s1
# No response needed, since can serve from cache
wait *
check r1b
quit


# Make sure caches for different servers are not mixed
# This test can be passed by a sequential proxy
serve s1 s2
generate random-text1.txt 100K
generate random-text2.txt 100K
generate random-text3.txt 100K
# Serve first versions of the files using server s1
fetch f1a random-text1.txt s1
fetch f2a random-text2.txt s1
fetch f3a random-text3.txt s1
wait *
check f1a
check f2a
check f3a
# Make sure caching occurred
request r1a random-text1.txt s1
wait r1a
check r1a
delete random-text1.txt
delete random-text2.txt
delete random-text3.txt
# Create new files with same names but different contents
generate random-text1.txt 99K
generate random-text2.txt 99K
generate random-text3.txt 99K
# Serve second versions of the files using server s2
request r1b random-text1.txt s2
request r2b random-text2.txt s2
request r3b random-text3.txt s2
wait r1b
respond r1b
wait r2b
respond r2b 
wait r3b
respond r3b
# Since these requests were to a different server,
# the responses should come from server, not from cache.
#
# Respond in order
respond r1b r2b r3b
wait *
check r1b
check r2b
check r3b
quit

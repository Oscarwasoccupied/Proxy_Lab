# Make sure don't cache large objects
# This test can be passed by a sequential proxy
serve s1
# This file is too big to cache
generate random-text1.txt 200K
generate random-text2.txt 20K
request r1a random-text1.txt s1
request r2a random-text2.txt s1
# Respond in order
wait r1a
respond r1a
wait r2a
respond r2a
wait r1a r2a
check r1a
check r2a
# Delete file so that future attempt to fetch it will fail
delete random-text1.txt
# Should not serve from cache
request r1b random-text1.txt s1
wait r1b
respond r1b
# Should serve from cache.
request r2b random-text2.txt s1
wait r1b r2b
# Correct implementation will try to fetch deleted file and return status 404
check r1b 404
# Correct implementation will serve this file from its cache
check r2b
quit


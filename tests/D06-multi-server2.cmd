# Make sure caches for different servers are not mixed.  Binary data
serve s1 s2
generate random-binary1.bin 100K
generate random-binary2.bin 100K
generate random-binary3.bin 100K
# Request first version of files from server s1
request r1a random-binary1.bin s1
request r2a random-binary2.bin s1
request r3a random-binary3.bin s1
wait *
# Out of order response will fail with sequential proxy
respond r3a r2a r1a
wait *
check r1a
check r2a
check r3a
delete random-binary1.bin
delete random-binary2.bin
delete random-binary3.bin
# Generate files with same names, but different contents
generate random-binary1.bin 99K
generate random-binary2.bin 99K
generate random-binary3.bin 99K
# Request first version of files from server s2
request r1b random-binary1.bin s2
request r2b random-binary2.bin s2
request r3b random-binary3.bin s2
wait *
# Since these requests were to a different server,
# the responses should come from server, not from cache.
respond r1b r2b r3b
wait *
check r1b
check r2b
check r3b
# Check for caching
request r1c random-binary1.bin s2
wait *
check r1c
quit

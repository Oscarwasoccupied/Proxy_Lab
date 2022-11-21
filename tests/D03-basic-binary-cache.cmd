# Test ability to retrieve binary file from cache
# This test can be passed by a sequential proxy
serve s1
generate random-binary1.bin 10K
generate random-binary2.bin 10K
# Cache must be able to hold binary data
request r1a random-binary1.bin s1
wait *
respond r1a
wait *
check r1a
fetch f2 random-binary2.bin s1
wait *
check f2
# This request should be serviced directly by proxy
request r1b random-binary1.bin s1
wait *
check r1b
quit



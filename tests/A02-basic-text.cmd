# Test ability to retrieve text file
serve s1
generate random-text.txt 10K
# Request file from server
request r1 random-text.txt s1
wait *
# Allow server to respond to request
respond r1
wait *
check r1
quit


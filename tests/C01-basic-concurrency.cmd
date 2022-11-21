# Test ability to handle out-of-order requests
serve s1
generate random-text1.txt 2K 
generate random-text2.txt 4K 
request r1 random-text1.txt s1
request r2 random-text2.txt s1
wait *
# Proxy must have passed request r2 to server
# even though it has not yet completed r1.
respond r2
respond r1
wait *
check r1
check r2
quit


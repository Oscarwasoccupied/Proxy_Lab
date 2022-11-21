# Test ability to handle missing file from cache
# This test can be passed by a sequential proxy
serve s1
request r1a random-text1.txt s1
wait *
respond r1a
wait *
check r1a 404
fetch f2 random-text2.txt s1
wait *
check f2 404
# Proxy should respond immediately with missing file notification
request r1b random-text1.txt s1
wait *
check r1b 404
quit



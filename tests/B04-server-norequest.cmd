# Test what happens when server closes socket before reading request
generate r1.txt 1k
generate r2.txt 2k
serve s1
disrupt request s1
delay 100
fetch f1 r1.txt s1
delay 100
fetch f2 r2.txt s1
wait *
# f1 failed, but f2 should be OK
trace f1
check f2
quit

# Test ability of proxy to handle bad IP address
generate r1.txt 1k
# Server having name starting with '-' is disabled
serve -s1
serve s2
fetch f1a r1.txt -s1
fetch f1b r1.txt s2
wait f1b
# f1a failed, but f1b should be OK
check f1b
quit

# Test ability of proxy to handle SIGPIPE signal
generate r1.txt 1k
serve s1
# Send SIGPIPE signal to proxy
signal 
fetch f1 r1.txt s1
wait *
check f1
quit

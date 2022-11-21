# Test ability to retrieve 1MB text file
serve s1
generate long-text.txt 1M
request r1 long-text.txt s1
wait *
respond r1
wait *
check r1
delete long-text.txt
quit


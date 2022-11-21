# Test ability to handle missing file
serve s1
# Request nonexistent file
request r1 random-text.txt s1
wait *
respond r1
wait *
# Response should be that file was not found
check r1 404
quit



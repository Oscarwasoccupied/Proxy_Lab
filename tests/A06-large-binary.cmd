# Test ability to retrieve 1MB binary file
serve s1
# This file will contain arbitrary byte values
generate big-binary.bin 1M
request r1 big-binary.bin s1
wait *
respond r1
wait *
check r1
delete big-binary.bin
quit



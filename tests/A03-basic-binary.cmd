# Test ability to retrieve binary file
serve s1
# This file will contain arbitrary byte values
generate random-binary.bin 10K
request r1 random-binary.bin s1
wait *
respond r1
wait *
check r1
quit



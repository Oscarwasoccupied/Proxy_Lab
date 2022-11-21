# Make sure cache uses an LRU policy
serve s1
generate random-binary01.bin 100K
generate random-binary02.bin 100K
generate random-binary03.bin 100K
generate random-binary04.bin 100K
generate random-binary05.bin 100K
generate random-binary06.bin 100K
generate random-binary07.bin 100K
generate random-binary08.bin 100K
generate random-binary09.bin 100K
generate random-binary10.bin 100K
generate random-binary11.bin 100K
generate random-binary12.bin 100K
generate random-binary13.bin 100K
generate random-binary14.bin 100K
generate random-binary15.bin 100K
# Load initial files in cache
fetch f01 random-binary01.bin s1
fetch f02 random-binary02.bin s1
fetch f03 random-binary03.bin s1
wait *
check f01
check f02
check f03
# Generate more requests, to fill up cache
fetch f04 random-binary04.bin s1
fetch f05 random-binary05.bin s1
fetch f06 random-binary06.bin s1
fetch f07 random-binary07.bin s1
fetch f08 random-binary08.bin s1
fetch f09 random-binary09.bin s1
wait *
check f04
check f05
check f06
check f07
check f09
# Check that have initial requests in cache (and mark them as used)
request r01c random-binary01.bin s1
request r02c random-binary02.bin s1
request r03c random-binary03.bin s1
wait *
check r01c
check r02c
check r03c
# Add more files to cache.  Original files should remain
fetch f10 random-binary10.bin s1
fetch f11 random-binary11.bin s1
fetch f12 random-binary12.bin s1
# Add more files to cache.  Original files should remain
request r13 random-binary13.bin s1
request r14 random-binary14.bin s1
request r15 random-binary15.bin s1
wait *
check f10
check f11
check f12
# Out of order response will cause sequential proxy to fail
respond r15 r14 r13
wait *
check r13
check r14
check r15
# Make sure initial requests have not been evicted
request r01cc random-binary01.bin s1
request r02cc random-binary02.bin s1
request r03cc random-binary03.bin s1
wait *
check r01cc 
check r02cc 
check r03cc 
# Make sure still have final requests in cache
request r13c random-binary13.bin s1
request r14c random-binary14.bin s1
request r15c random-binary15.bin s1
wait *
check r13c
check r14c
check r15c
delete random-binary01.bin
delete random-binary02.bin
delete random-binary03.bin
delete random-binary04.bin
delete random-binary05.bin
delete random-binary06.bin
delete random-binary07.bin
delete random-binary08.bin
delete random-binary09.bin
delete random-binary10.bin
delete random-binary11.bin
delete random-binary12.bin
delete random-binary13.bin
delete random-binary14.bin
delete random-binary15.bin
quit


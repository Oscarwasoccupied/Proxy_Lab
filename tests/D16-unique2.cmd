# Make sure cache holds at most one copy of a binary file
serve s1
generate random-binary00.bin 100K
generate random-binary01.bin 100K
generate random-binary02.bin 100K
generate random-binary03.bin 100K
generate random-binary04.bin 100K
generate random-binary05.bin 100K
generate random-binary06.bin 100K
generate random-binary07.bin 100K
generate random-binary08.bin 100K
generate random-binary09.bin 100K
# Use 500K of cache
fetch f00 random-binary00.bin s1
fetch f01 random-binary01.bin s1
fetch f02 random-binary02.bin s1
fetch f03 random-binary03.bin s1
fetch f04 random-binary04.bin s1
wait *
# Make 5 requests, but defer responses
request r05a random-binary05.bin s1
request r06a random-binary06.bin s1
request r07a random-binary07.bin s1
request r08a random-binary08.bin s1
request r09a random-binary09.bin s1
wait *
# Use 500K of cache, filling it up
fetch f05 random-binary05.bin s1
fetch f06 random-binary06.bin s1
fetch f07 random-binary07.bin s1
fetch f08 random-binary08.bin s1
fetch f09 random-binary09.bin s1
wait *
# These responses should not generate cache writes
# since the files were cached due to earlier fetches
# Out of order response will cause sequential proxy to fail
respond r08a r09a r05a r06a r07a
wait *
check f00
check f01
check f02
check f03
check f04
check f05
check f06
check f07
check f08
check f09
check r05a
check r06a
check r07a
check r08a
check r09a
# These should all hit the cache
request r00b random-binary00.bin s1
request r01b random-binary01.bin s1
request r02b random-binary02.bin s1
request r03b random-binary03.bin s1
request r04b random-binary04.bin s1
request r05b random-binary05.bin s1
request r06b random-binary06.bin s1
request r07b random-binary07.bin s1
request r08b random-binary08.bin s1
request r09b random-binary09.bin s1
wait *
check r00b
check r01b
check r02b
check r03b
check r04b
check r05b
check r06b
check r07b
check r08b
check r09b
delete random-binary00.bin
delete random-binary01.bin
delete random-binary02.bin
delete random-binary03.bin
delete random-binary04.bin
delete random-binary05.bin
delete random-binary06.bin
delete random-binary07.bin
delete random-binary08.bin
delete random-binary09.bin
quit



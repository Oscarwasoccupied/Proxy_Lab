# Test ability to evict multiple binary objects to make room for big ones
serve s1
generate little-binary00.bin 10K
generate little-binary01.bin 10K
generate little-binary02.bin 10K
generate little-binary03.bin 10K
generate little-binary04.bin 10K
generate little-binary05.bin 10K
generate little-binary06.bin 10K
generate little-binary07.bin 10K
generate little-binary08.bin 10K
generate little-binary09.bin 10K
generate big-binary00.bin 100K
generate big-binary01.bin 100K
generate big-binary02.bin 100K
generate big-binary03.bin 100K
generate big-binary04.bin 100K
generate big-binary05.bin 100K
generate big-binary06.bin 100K
generate big-binary07.bin 100K
generate big-binary08.bin 100K
generate big-binary09.bin 100K
generate big-binary10.bin 100K
generate big-binary11.bin 100K
# Use 50K of cache
fetch fl00 little-binary00.bin s1
fetch fl01 little-binary01.bin s1
fetch fl02 little-binary02.bin s1
fetch fl03 little-binary03.bin s1
fetch fl04 little-binary04.bin s1
wait *
# Use another 100K of cache
fetch fb00 big-binary00.bin s1
wait *
check fb00
# Use another 50K of cache
fetch fl05 little-binary05.bin s1
fetch fl06 little-binary06.bin s1
fetch fl07 little-binary07.bin s1
fetch fl08 little-binary08.bin s1
fetch fl09 little-binary09.bin s1
wait *
check fl00
check fl01
check fl02
check fl03
check fl04
check fl05
check fl06
check fl07
check fl08
check fl09
# Use another 100K of cache
fetch fb01 big-binary01.bin s1
wait *
# Use another 700K of cache, causing it to be full
fetch fb02 big-binary02.bin s1
fetch fb03 big-binary03.bin s1
fetch fb04 big-binary04.bin s1
fetch fb05 big-binary05.bin s1
fetch fb06 big-binary06.bin s1
fetch fb07 big-binary07.bin s1
fetch fb08 big-binary08.bin s1
wait *
# These should evict the little entries + the first big one
fetch fb09 big-binary09.bin s1
fetch fb10 big-binary10.bin s1
fetch fb11 big-binary11.bin s1
wait *
check fb01
check fb02
check fb03
check fb04
check fb05
check fb06
check fb07
check fb08
check fb09
check fb10
check fb11
# Delete the little files
delete little-binary00.bin
delete little-binary01.bin
delete little-binary02.bin
delete little-binary03.bin
delete little-binary04.bin
delete little-binary05.bin
delete little-binary06.bin
delete little-binary07.bin
delete little-binary08.bin
delete little-binary09.bin
delete big-binary00.bin
# These should not be in the cache
# First big file
request rb00 big-binary00.bin s1
# The little files
request rl00 little-binary00.bin s1
request rl01 little-binary01.bin s1
request rl02 little-binary02.bin s1
request rl03 little-binary03.bin s1
request rl04 little-binary04.bin s1
request rl05 little-binary05.bin s1
request rl06 little-binary06.bin s1
request rl07 little-binary07.bin s1
request rl08 little-binary08.bin s1
request rl09 little-binary09.bin s1
#
wait *
respond rl00 rl01 rl02 rl03 rl04
respond rl05 rl06 rl07 rl08 rl09
# Out of order response will cause sequential proxy to fail
respond rb00
wait *
# Server should have responded that these files are not present
check rb00 404
check rl00 404
check rl01 404
check rl02 404
check rl03 404
check rl04 404
check rl05 404
check rl06 404
check rl07 404
check rl08 404
check rl09 404
# Make sure still have most of the big blocks
request rb02 big-binary02.bin s1
request rb03 big-binary03.bin s1
request rb04 big-binary04.bin s1
request rb05 big-binary05.bin s1
request rb06 big-binary06.bin s1
request rb07 big-binary07.bin s1
request rb08 big-binary08.bin s1
request rb09 big-binary09.bin s1
request rb10 big-binary10.bin s1
request rb11 big-binary10.bin s1
wait *
check rb02
check rb03
check rb04
check rb05
check rb06
check rb07
check rb08
check rb09
check rb10
check rb11
delete big-binary01.bin
delete big-binary02.bin
delete big-binary03.bin
delete big-binary04.bin
delete big-binary05.bin
delete big-binary06.bin
delete big-binary07.bin
delete big-binary08.bin
delete big-binary09.bin
delete big-binary10.bin
delete big-binary11.bin
quit


# Test ability to evict multiple objects to make room for big ones
serve s1
generate little-text00.txt 10K
generate little-text01.txt 10K
generate little-text02.txt 10K
generate little-text03.txt 10K
generate little-text04.txt 10K
generate little-text05.txt 10K
generate little-text06.txt 10K
generate little-text07.txt 10K
generate little-text08.txt 10K
generate little-text09.txt 10K
generate big-text00.txt 100K
generate big-text01.txt 100K
generate big-text02.txt 100K
generate big-text03.txt 100K
generate big-text04.txt 100K
generate big-text05.txt 100K
generate big-text06.txt 100K
generate big-text07.txt 100K
generate big-text08.txt 100K
generate big-text09.txt 100K
generate big-text10.txt 100K
# Use 100K of cache
fetch fl00 little-text00.txt s1
fetch fl01 little-text01.txt s1
fetch fl02 little-text02.txt s1
fetch fl03 little-text03.txt s1
fetch fl04 little-text04.txt s1
fetch fl05 little-text05.txt s1
fetch fl06 little-text06.txt s1
fetch fl07 little-text07.txt s1
fetch fl08 little-text08.txt s1
fetch fl09 little-text09.txt s1
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
# Use another 200K of cache
fetch fb00 big-text00.txt s1
fetch fb01 big-text01.txt s1
wait *
# Use another 700K to fill up cache
fetch fb02 big-text02.txt s1
fetch fb03 big-text03.txt s1
fetch fb04 big-text04.txt s1
fetch fb05 big-text05.txt s1
fetch fb06 big-text06.txt s1
fetch fb07 big-text07.txt s1
fetch fb08 big-text08.txt s1
wait *
# These should evict the little entries
fetch fb09 big-text09.txt s1
fetch fb10 big-text10.txt s1
wait *
check fb00
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
delete little-text00.txt
delete little-text01.txt
delete little-text02.txt
delete little-text03.txt
delete little-text04.txt
delete little-text05.txt
delete little-text06.txt
delete little-text07.txt
delete little-text08.txt
delete little-text09.txt
# These should not be in the cache
request rl00 little-text00.txt s1
request rl01 little-text01.txt s1
request rl02 little-text02.txt s1
request rl03 little-text03.txt s1
request rl04 little-text04.txt s1
request rl05 little-text05.txt s1
request rl06 little-text06.txt s1
request rl07 little-text07.txt s1
request rl08 little-text08.txt s1
request rl09 little-text09.txt s1
wait *
# Server should respond that the files were not found
# Out of order response will cause sequential proxy to fail
respond rl05 rl06 rl07 rl08 rl09
respond rl00 rl01 rl02 rl03 rl04
wait *
# Make sure correct response received
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
# Make sure still have most of the big blocks in cache
request rb02 big-text02.txt s1
request rb03 big-text03.txt s1
request rb04 big-text04.txt s1
request rb05 big-text05.txt s1
request rb06 big-text06.txt s1
request rb07 big-text07.txt s1
request rb08 big-text08.txt s1
request rb09 big-text09.txt s1
request rb10 big-text10.txt s1
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
delete big-text00.txt
delete big-text01.txt
delete big-text02.txt
delete big-text03.txt
delete big-text04.txt
delete big-text05.txt
delete big-text06.txt
delete big-text07.txt
delete big-text08.txt
delete big-text09.txt
delete big-text10.txt
quit


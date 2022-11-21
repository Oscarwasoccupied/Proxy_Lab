# Test ability to handle combination of fetches and requests with
# strictness level 2: Check host and http version.
option strict 2
serve s1 s2 s3
generate random-text1.txt 2K 
generate random-text2.txt 4K 
generate random-text3.txt 6K
generate random-text4.txt 8K
generate random-text5.txt 10K
generate random-text6.txt 12K
# A sequential proxy can handle this ordering
# of requests, fetches, and responses.
request r1 random-text1.txt s2
fetch f1 random-text1.txt s1
request r2 random-text2.txt s3
fetch f2 random-text2.txt s2
request r3 random-text3.txt s1
fetch f3 random-text3.txt s3
request r4 random-text4.txt s1
fetch f4 random-text4.txt s3
request r5 random-text5.txt s3
fetch f5 random-text5.txt s2
request r6 random-text6.txt s2
fetch f6 random-text6.txt s1
wait r1
respond r1
wait r1 f1 r2
check r1
trace r1
check f1
respond r2
wait r2 f2 r3
check r2
check f2
respond r3
wait r3 f3 r4
check r3
check f3
respond r4
wait r4 f4 r5
check r4
check f4
respond r5
wait r5 f5 r6
check r5
check f5
respond r6
wait r6 f6
check r6
check f6
quit


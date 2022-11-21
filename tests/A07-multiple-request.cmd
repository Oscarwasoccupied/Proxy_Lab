# Test ability to handle multiple requests
serve s1 s2 s3
generate random-text1.txt 2K 
generate random-text2.txt 4K 
generate random-text3.txt 6K
generate random-text4.txt 8K
generate random-text5.txt 10K
generate random-text6.txt 12K
request r1 random-text1.txt s1
request r2 random-text2.txt s2
request r3 random-text3.txt s3
request r4 random-text4.txt s3
request r5 random-text5.txt s2
request r6 random-text6.txt s1
# Respond in same order as requests
# This can be done with a sequential proxy
wait r1
respond r1
wait r2
respond r2
wait r3
respond r3
wait r4
respond r4
wait r5
respond r5
wait r6
respond r6
wait *
check r1
check r2
check r3
check r4
check r5
check r6
quit

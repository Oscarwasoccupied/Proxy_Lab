# Test ability to handle mix of requests and fetches, with missing and present binary and text files
serve s1 s2 s3
generate random-text1.txt 10k
generate random-binary1.bin 10k
generate random-text2.txt 100k
generate random-binary2.bin 100k
generate random-text3.txt 1m
generate random-binary3.bin 1m
request r1 random-text1.txt s1
request r2 random-binary2.bin s2
request r3 nothing1.txt s3
request r4 random-binary2.bin s1
request r5 random-text3.txt s2
request r6 nothing2.txt s3
request r7 random-text2.txt s1
request r8 random-binary3.bin s2
request r9 nothing3.txt s3
wait *
respond r5 r6 r7 r8 r9
wait *
respond r1 r2 r3 r4 
fetch f1 random-text1.txt s2
fetch f2 random-binary2.bin s3
fetch f3 nothing1.txt s1
fetch f4 random-binary2.bin s1
fetch f5 random-text3.txt s3
fetch f6 nothing1.txt s2
fetch f7 random-text2.txt s2
fetch f8 random-binary3.bin s1
fetch f9 nothing4.txt s3
wait *
check r1
check r2
check r3 404
check r4
check r5
check r6 404
check r7 
check r8 
check r9 404
check f1
check f2
check f3 404
check f4
check f5
check f6 404
check f7 
check f8 
check f9 404
delete random-text1.txt
delete random-binary1.bin
delete random-text2.txt
delete random-binary2.bin
delete random-text3.txt
delete random-binary3.bin
quit


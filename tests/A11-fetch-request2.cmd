# Test ability to handle combination of fetches and requests of binary data
serve s1 s2 s3
generate random-binary1.bin 2K 
generate random-binary2.bin 4K 
generate random-binary3.bin 6K
generate random-binary4.bin 8K
generate random-binary5.bin 10K
generate random-binary6.bin 12K
fetch f1 random-binary1.bin s1
request r1 random-binary1.bin s2
fetch f2 random-binary2.bin s2
request r2 random-binary2.bin s3
fetch f3 random-binary3.bin s3
request r3 random-binary3.bin s1
fetch f4 random-binary4.bin s3
request r4 random-binary4.bin s1
fetch f5 random-binary5.bin s2
request r5 random-binary5.bin s3
fetch f6 random-binary6.bin s1
request r6 random-binary6.bin s2
wait f1 r1
check f1
respond r1
wait r1 f2 r2
check r1
check f2
respond r2
wait r2 f3 r3
check r2
check f3
respond r3
wait r3 f4 r4
check r3
check f4
respond r4
wait r4 f5 r5
check r4
check f5
respond r5
wait r5 f6 r6
check r5
check f6
respond r6
wait r6
check r6
quit


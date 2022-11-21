# Make sure evict objects
serve s1
generate random-text01.txt 100K
generate random-text02.txt 100K
generate random-text03.txt 100K
generate random-text04.txt 100K
generate random-text05.txt 100K
generate random-text06.txt 100K
generate random-text07.txt 100K
generate random-text08.txt 100K
generate random-text09.txt 100K
generate random-text10.txt 100K
generate random-text11.txt 100K
generate random-text12.txt 100K
generate random-text13.txt 100K
generate random-text14.txt 100K
generate random-text15.txt 100K
request r01 random-text01.txt s1
request r02 random-text02.txt s1
request r03 random-text03.txt s1
wait *
# Out of order response will fail with sequential proxy
respond r03 r01 r02
wait *
check r01
check r02
check r03
# Make sure have initial requests in cache
request r01c random-text01.txt s1
request r02c random-text02.txt s1
request r03c random-text03.txt s1
wait *
check r01c
check r02c
check r03c
# Generate more requests, to eventually evict first three
request r04 random-text04.txt s1
request r05 random-text05.txt s1
request r06 random-text06.txt s1
wait *
respond r04 r05 r06
request r07 random-text07.txt s1
request r08 random-text08.txt s1
request r09 random-text09.txt s1
wait *
check r04
check r05
check r06
respond r07 r08 r09
request r10 random-text10.txt s1
request r11 random-text11.txt s1
request r12 random-text12.txt s1
wait *
check r07
check r08
check r09
respond r10 r11 r12
request r13 random-text13.txt s1
request r14 random-text14.txt s1
request r15 random-text15.txt s1
wait *
check r10
check r11
check r12
respond r13 r14 r15
wait *
check r13
check r14
check r15
delete random-text01.txt
delete random-text02.txt
delete random-text03.txt
# These shouldn't be cached
# Make sure initial requests have been evicted
request r01n random-text01.txt s1
request r02n random-text02.txt s1
request r03n random-text03.txt s1
wait *
respond r01n r02n r03n
wait *
# If these files were evicted from cache, then response
# will be that the files are missing
check r01n 404
check r02n 404
check r03n 404
# Make sure still have final requests in cache
request r13c random-text13.txt s1
request r14c random-text14.txt s1
request r15c random-text15.txt s1
wait *
check r13c
check r14c
check r15c
delete random-text04.txt
delete random-text05.txt
delete random-text06.txt
delete random-text07.txt
delete random-text08.txt
delete random-text09.txt
delete random-text10.txt
delete random-text11.txt
delete random-text12.txt
delete random-text13.txt
delete random-text14.txt
delete random-text15.txt
quit


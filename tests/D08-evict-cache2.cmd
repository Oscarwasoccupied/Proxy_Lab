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
fetch f01 random-text01.txt s1
fetch f02 random-text02.txt s1
fetch f03 random-text03.txt s1
wait *
check f01
check f02
check f03
# Make sure have initial requests in cache
request r01c random-text01.txt s1
request r02c random-text02.txt s1
request r03c random-text03.txt s1
wait *
check r01c
check r02c
check r03c
# Generate more fetches, to eventually evict first three
fetch f04 random-text04.txt s1
fetch f05 random-text05.txt s1
fetch f06 random-text06.txt s1
fetch f07 random-text07.txt s1
fetch f08 random-text08.txt s1
fetch f09 random-text09.txt s1
fetch f10 random-text10.txt s1
fetch f11 random-text11.txt s1
fetch f12 random-text12.txt s1
request r13 random-text13.txt s1
request r14 random-text14.txt s1
request r15 random-text15.txt s1
wait *
check f04
check f05
check f06
check f07
check f08
check f09
check f10
check f11
check f12
# Out of order response will cause sequential proxy to fail
# These should cause initial objects to be evicted
respond r15 r14 r13
wait *
check r13
check r14
check r15
delete random-text01.txt
delete random-text02.txt
delete random-text03.txt
# These shouldn't be cached
# Make sure initial requests have been evicted
fetch f01n random-text01.txt s1
fetch f02n random-text02.txt s1
fetch f03n random-text03.txt s1
wait *
check f01n 404
check f02n 404
check f03n 404
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


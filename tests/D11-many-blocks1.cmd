# Cache should be able to hold many small blocks
serve s1 s2
# 50 * 10K = 500K.  The cache can hold all of these
generate random-text00.txt 10K
generate random-text01.txt 10K
generate random-text02.txt 10K
generate random-text03.txt 10K
generate random-text04.txt 10K
generate random-text05.txt 10K
generate random-text06.txt 10K
generate random-text07.txt 10K
generate random-text08.txt 10K
generate random-text09.txt 10K
generate random-text10.txt 10K
generate random-text11.txt 10K
generate random-text12.txt 10K
generate random-text13.txt 10K
generate random-text14.txt 10K
generate random-text15.txt 10K
generate random-text16.txt 10K
generate random-text17.txt 10K
generate random-text18.txt 10K
generate random-text19.txt 10K
generate random-text20.txt 10K
generate random-text21.txt 10K
generate random-text22.txt 10K
generate random-text23.txt 10K
generate random-text24.txt 10K
generate random-text25.txt 10K
generate random-text26.txt 10K
generate random-text27.txt 10K
generate random-text28.txt 10K
generate random-text29.txt 10K
generate random-text30.txt 10K
generate random-text31.txt 10K
generate random-text32.txt 10K
generate random-text33.txt 10K
generate random-text34.txt 10K
generate random-text35.txt 10K
generate random-text36.txt 10K
generate random-text37.txt 10K
generate random-text38.txt 10K
generate random-text39.txt 10K
generate random-text40.txt 10K
generate random-text41.txt 10K
generate random-text42.txt 10K
generate random-text43.txt 10K
generate random-text44.txt 10K
generate random-text45.txt 10K
generate random-text46.txt 10K
generate random-text47.txt 10K
generate random-text48.txt 10K
generate random-text49.txt 10K
# Generate request/response that will cause sequential proxy to fail
request rx0 random-text00.txt s2
request rx1 random-text01.txt s2
wait *
respond rx1 rx0
wait *
check rx0
check rx1
# These should all be cached
fetch f00 random-text00.txt s1
fetch f01 random-text01.txt s1
fetch f02 random-text02.txt s1
fetch f03 random-text03.txt s1
fetch f04 random-text04.txt s1
fetch f05 random-text05.txt s1
fetch f06 random-text06.txt s1
fetch f07 random-text07.txt s1
fetch f08 random-text08.txt s1
fetch f09 random-text09.txt s1
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
# These should all be cached and not cause any evictions
fetch f10 random-text10.txt s1
fetch f11 random-text11.txt s1
fetch f12 random-text12.txt s1
fetch f13 random-text13.txt s1
fetch f14 random-text14.txt s1
fetch f15 random-text15.txt s1
fetch f16 random-text16.txt s1
fetch f17 random-text17.txt s1
fetch f18 random-text18.txt s1
fetch f19 random-text19.txt s1
wait *
check f10
check f11
check f12
check f13
check f14
check f15
check f16
check f17
check f18
check f19
# These should all be cached and not cause any evictions
fetch f20 random-text20.txt s1
fetch f21 random-text21.txt s1
fetch f22 random-text22.txt s1
fetch f23 random-text23.txt s1
fetch f24 random-text24.txt s1
fetch f25 random-text25.txt s1
fetch f26 random-text26.txt s1
fetch f27 random-text27.txt s1
fetch f28 random-text28.txt s1
fetch f29 random-text29.txt s1
wait *
check f20
check f21
check f22
check f23
check f24
check f25
check f26
check f27
check f28
check f29
# These should all be cached and not cause any evictions
fetch f30 random-text30.txt s1
fetch f31 random-text31.txt s1
fetch f32 random-text32.txt s1
fetch f33 random-text33.txt s1
fetch f34 random-text34.txt s1
fetch f35 random-text35.txt s1
fetch f36 random-text36.txt s1
fetch f37 random-text37.txt s1
fetch f38 random-text38.txt s1
fetch f39 random-text39.txt s1
wait *
check f30
check f31
check f32
check f33
check f34
check f35
check f36
check f37
check f38
check f39
# These should all be cached and not cause any evictions
fetch f40 random-text40.txt s1
fetch f41 random-text41.txt s1
fetch f42 random-text42.txt s1
fetch f43 random-text43.txt s1
fetch f44 random-text44.txt s1
fetch f45 random-text45.txt s1
fetch f46 random-text46.txt s1
fetch f47 random-text47.txt s1
fetch f48 random-text48.txt s1
fetch f49 random-text49.txt s1
wait *
check f40
check f41
check f42
check f43
check f44
check f45
check f46
check f47
check f48
check f49
# These should all be in the cache
request r00 random-text00.txt s1
request r01 random-text01.txt s1
request r02 random-text02.txt s1
request r03 random-text03.txt s1
request r04 random-text04.txt s1
request r05 random-text05.txt s1
request r06 random-text06.txt s1
request r07 random-text07.txt s1
request r08 random-text08.txt s1
request r09 random-text09.txt s1
wait *
check r00
check r01
check r02
check r03
check r04
check r05
check r06
check r07
check r08
check r09
# These should all be in the cache
request r10 random-text10.txt s1
request r11 random-text11.txt s1
request r12 random-text12.txt s1
request r13 random-text13.txt s1
request r14 random-text14.txt s1
request r15 random-text15.txt s1
request r16 random-text16.txt s1
request r17 random-text17.txt s1
request r18 random-text18.txt s1
request r19 random-text19.txt s1
wait *
check r10
check r11
check r12
check r13
check r14
check r15
check r16
check r17
check r18
check r19
# These should all be in the cache
request r20 random-text20.txt s1
request r21 random-text21.txt s1
request r22 random-text22.txt s1
request r23 random-text23.txt s1
request r24 random-text24.txt s1
request r25 random-text25.txt s1
request r26 random-text26.txt s1
request r27 random-text27.txt s1
request r28 random-text28.txt s1
request r29 random-text29.txt s1
wait *
check r20
check r21
check r22
check r23
check r24
check r25
check r26
check r27
check r28
check r29
# These should all be in the cache
request r30 random-text30.txt s1
request r31 random-text31.txt s1
request r32 random-text32.txt s1
request r33 random-text33.txt s1
request r34 random-text34.txt s1
request r35 random-text35.txt s1
request r36 random-text36.txt s1
request r37 random-text37.txt s1
request r38 random-text38.txt s1
request r39 random-text39.txt s1
wait *
check r30
check r31
check r32
check r33
check r34
check r35
check r36
check r37
check r38
check r39
# These should all be in the cache
request r40 random-text40.txt s1
request r41 random-text41.txt s1
request r42 random-text42.txt s1
request r43 random-text43.txt s1
request r44 random-text44.txt s1
request r45 random-text45.txt s1
request r46 random-text46.txt s1
request r47 random-text47.txt s1
request r48 random-text48.txt s1
request r49 random-text49.txt s1
wait *
check r40
check r41
check r42
check r43
check r44
check r45
check r46
check r47
check r48
check r49
delete random-text00.txt
delete random-text01.txt
delete random-text02.txt
delete random-text03.txt
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
delete random-text16.txt
delete random-text17.txt
delete random-text18.txt
delete random-text19.txt
delete random-text20.txt
delete random-text21.txt
delete random-text22.txt
delete random-text23.txt
delete random-text24.txt
delete random-text25.txt
delete random-text26.txt
delete random-text27.txt
delete random-text28.txt
delete random-text29.txt
delete random-text30.txt
delete random-text31.txt
delete random-text32.txt
delete random-text33.txt
delete random-text34.txt
delete random-text35.txt
delete random-text36.txt
delete random-text37.txt
delete random-text38.txt
delete random-text39.txt
delete random-text40.txt
delete random-text41.txt
delete random-text42.txt
delete random-text43.txt
delete random-text44.txt
delete random-text45.txt
delete random-text46.txt
delete random-text47.txt
delete random-text48.txt
delete random-text49.txt


quit



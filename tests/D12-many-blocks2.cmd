# Cache should be able to hold many small binary blocks
serve s1 s2
# 50 * 20K = 1000K.  The cache should be able to hold all of these
generate random-binary00.bin 20K
generate random-binary01.bin 20K
generate random-binary02.bin 20K
generate random-binary03.bin 20K
generate random-binary04.bin 20K
generate random-binary05.bin 20K
generate random-binary06.bin 20K
generate random-binary07.bin 20K
generate random-binary08.bin 20K
generate random-binary09.bin 20K
generate random-binary10.bin 20K
generate random-binary11.bin 20K
generate random-binary12.bin 20K
generate random-binary13.bin 20K
generate random-binary14.bin 20K
generate random-binary15.bin 20K
generate random-binary16.bin 20K
generate random-binary17.bin 20K
generate random-binary18.bin 20K
generate random-binary19.bin 20K
generate random-binary20.bin 20K
generate random-binary21.bin 20K
generate random-binary22.bin 20K
generate random-binary23.bin 20K
generate random-binary24.bin 20K
generate random-binary25.bin 20K
generate random-binary26.bin 20K
generate random-binary27.bin 20K
generate random-binary28.bin 20K
generate random-binary29.bin 20K
generate random-binary30.bin 20K
generate random-binary31.bin 20K
generate random-binary32.bin 20K
generate random-binary33.bin 20K
generate random-binary34.bin 20K
generate random-binary35.bin 20K
generate random-binary36.bin 20K
generate random-binary37.bin 20K
generate random-binary38.bin 20K
generate random-binary39.bin 20K
generate random-binary40.bin 20K
generate random-binary41.bin 20K
generate random-binary42.bin 20K
generate random-binary43.bin 20K
generate random-binary44.bin 20K
generate random-binary45.bin 20K
generate random-binary46.bin 20K
generate random-binary47.bin 20K
generate random-binary48.bin 20K
generate random-binary49.bin 20K
# Generate request/response that will cause sequential proxy to fail
request rx0 random-binary00.bin s2
request rx1 random-binary01.bin s2
wait *
respond rx1 rx0
wait *
check rx0
check rx1
# These should all be cached
fetch f00 random-binary00.bin s1
fetch f01 random-binary01.bin s1
fetch f02 random-binary02.bin s1
fetch f03 random-binary03.bin s1
fetch f04 random-binary04.bin s1
fetch f05 random-binary05.bin s1
fetch f06 random-binary06.bin s1
fetch f07 random-binary07.bin s1
fetch f08 random-binary08.bin s1
fetch f09 random-binary09.bin s1
# These should all be cached and not cause any evictions
fetch f10 random-binary10.bin s1
fetch f11 random-binary11.bin s1
fetch f12 random-binary12.bin s1
fetch f13 random-binary13.bin s1
fetch f14 random-binary14.bin s1
fetch f15 random-binary15.bin s1
fetch f16 random-binary16.bin s1
fetch f17 random-binary17.bin s1
fetch f18 random-binary18.bin s1
fetch f19 random-binary19.bin s1
# These should all be cached and not cause any evictions
fetch f20 random-binary20.bin s1
fetch f21 random-binary21.bin s1
fetch f22 random-binary22.bin s1
fetch f23 random-binary23.bin s1
fetch f24 random-binary24.bin s1
fetch f25 random-binary25.bin s1
fetch f26 random-binary26.bin s1
fetch f27 random-binary27.bin s1
fetch f28 random-binary28.bin s1
fetch f29 random-binary29.bin s1
# These should all be cached and not cause any evictions
fetch f30 random-binary30.bin s1
fetch f31 random-binary31.bin s1
fetch f32 random-binary32.bin s1
fetch f33 random-binary33.bin s1
fetch f34 random-binary34.bin s1
fetch f35 random-binary35.bin s1
fetch f36 random-binary36.bin s1
fetch f37 random-binary37.bin s1
fetch f38 random-binary38.bin s1
fetch f39 random-binary39.bin s1
# These should all be cached and not cause any evictions
fetch f40 random-binary40.bin s1
fetch f41 random-binary41.bin s1
fetch f42 random-binary42.bin s1
fetch f43 random-binary43.bin s1
fetch f44 random-binary44.bin s1
fetch f45 random-binary45.bin s1
fetch f46 random-binary46.bin s1
fetch f47 random-binary47.bin s1
fetch f48 random-binary48.bin s1
fetch f49 random-binary49.bin s1
wait *
# Check all of the files
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
# These should all be in the cache
request r00 random-binary00.bin s1
request r01 random-binary01.bin s1
request r02 random-binary02.bin s1
request r03 random-binary03.bin s1
request r04 random-binary04.bin s1
request r05 random-binary05.bin s1
request r06 random-binary06.bin s1
request r07 random-binary07.bin s1
request r08 random-binary08.bin s1
request r09 random-binary09.bin s1
# These should all be in the cache
request r10 random-binary10.bin s1
request r11 random-binary11.bin s1
request r12 random-binary12.bin s1
request r13 random-binary13.bin s1
request r14 random-binary14.bin s1
request r15 random-binary15.bin s1
request r16 random-binary16.bin s1
request r17 random-binary17.bin s1
request r18 random-binary18.bin s1
request r19 random-binary19.bin s1
# These should all be in the cache
request r20 random-binary20.bin s1
request r21 random-binary21.bin s1
request r22 random-binary22.bin s1
request r23 random-binary23.bin s1
request r24 random-binary24.bin s1
request r25 random-binary25.bin s1
request r26 random-binary26.bin s1
request r27 random-binary27.bin s1
request r28 random-binary28.bin s1
request r29 random-binary29.bin s1
# These should all be in the cache
request r30 random-binary30.bin s1
request r31 random-binary31.bin s1
request r32 random-binary32.bin s1
request r33 random-binary33.bin s1
request r34 random-binary34.bin s1
request r35 random-binary35.bin s1
request r36 random-binary36.bin s1
request r37 random-binary37.bin s1
request r38 random-binary38.bin s1
request r39 random-binary39.bin s1
# These should all be in the cache
request r40 random-binary40.bin s1
request r41 random-binary41.bin s1
request r42 random-binary42.bin s1
request r43 random-binary43.bin s1
request r44 random-binary44.bin s1
request r45 random-binary45.bin s1
request r46 random-binary46.bin s1
request r47 random-binary47.bin s1
request r48 random-binary48.bin s1
request r49 random-binary49.bin s1
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
delete random-binary10.bin
delete random-binary11.bin
delete random-binary12.bin
delete random-binary13.bin
delete random-binary14.bin
delete random-binary15.bin
delete random-binary16.bin
delete random-binary17.bin
delete random-binary18.bin
delete random-binary19.bin
delete random-binary20.bin
delete random-binary21.bin
delete random-binary22.bin
delete random-binary23.bin
delete random-binary24.bin
delete random-binary25.bin
delete random-binary26.bin
delete random-binary27.bin
delete random-binary28.bin
delete random-binary29.bin
delete random-binary30.bin
delete random-binary31.bin
delete random-binary32.bin
delete random-binary33.bin
delete random-binary34.bin
delete random-binary35.bin
delete random-binary36.bin
delete random-binary37.bin
delete random-binary38.bin
delete random-binary39.bin
delete random-binary40.bin
delete random-binary41.bin
delete random-binary42.bin
delete random-binary43.bin
delete random-binary44.bin
delete random-binary45.bin
delete random-binary46.bin
delete random-binary47.bin
delete random-binary48.bin
delete random-binary49.bin
quit



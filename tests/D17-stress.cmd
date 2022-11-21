option timeout 20000
option error 1
option linefeed 0
# Stress proxy with lots of concurrent activity
serve s0 s1 s2 s3 s4
serve s10
generate random-binary00.bin  33K
generate random-binary01.bin  50K
generate random-binary02.bin  66K
generate random-binary03.bin  50K
generate random-binary04.bin  50K
generate random-binary05.bin  50K
generate random-binary06.bin  66K
generate random-binary07.bin 100K
generate random-binary08.bin 100K
generate random-binary09.bin 100K
generate random-binary10.bin 100K
generate random-binary11.bin  66K
generate random-binary12.bin  50K
generate random-binary13.bin  33K
generate random-binary14.bin  20K
# Move data
fetch fc00a random-binary00.bin s0
fetch fc01a random-binary01.bin s1
fetch fc02a random-binary02.bin s2
fetch fc03a random-binary03.bin s3
fetch fc04a random-binary04.bin s4
fetch fs00a random-binary00.bin s10
fetch fs01a random-binary01.bin s10
fetch fs02a random-binary02.bin s10
fetch fs03a random-binary03.bin s10
fetch fs04a random-binary04.bin s10
# Make 10 requests, but defer responses
request rc05a random-binary05.bin s0
request rc06a random-binary06.bin s1
request rc07a random-binary07.bin s2
request rc08a random-binary08.bin s3
request rc09a random-binary09.bin s4
request rs05a random-binary05.bin s10
request rs06a random-binary06.bin s10
request rs07a random-binary07.bin s10
request rs08a random-binary08.bin s10
request rs09a random-binary09.bin s10
# More requests
request rc10 random-binary10.bin s0
request rc11 random-binary11.bin s1
request rc12 random-binary12.bin s2
request rc13 random-binary13.bin s3
request rc14 random-binary14.bin s4
request rs10 random-binary10.bin s10
request rs11 random-binary11.bin s10
request rs12 random-binary12.bin s10
request rs13 random-binary13.bin s10
request rs14 random-binary14.bin s10
wait *
# More traffic
respond rc08a rc09a rc05a rc06a rc07a
wait *
respond rc10 rc11 rc12 rc13 rc14
fetch fc05a random-binary05.bin s0
fetch fc06a random-binary06.bin s1
fetch fc07a random-binary07.bin s2
fetch fc08a random-binary08.bin s3
fetch fc09a random-binary09.bin s4
respond rs08a rs09a rs05a rs06a rs07a
wait *
respond rs10 rs11 rs12 rs13 rs14
fetch fs05a random-binary05.bin s10
fetch fs06a random-binary06.bin s10
fetch fs07a random-binary07.bin s10
fetch fs08a random-binary08.bin s10
fetch fs09a random-binary09.bin s10
# Move data
fetch fc00b random-binary00.bin s0
fetch fc01b random-binary01.bin s1
fetch fc02b random-binary02.bin s2
fetch fc03b random-binary03.bin s3
fetch fc04b random-binary04.bin s4
fetch fc05b random-binary05.bin s0
fetch fc06b random-binary06.bin s1
fetch fc07b random-binary07.bin s2
fetch fc08b random-binary08.bin s3
fetch fc09b random-binary09.bin s4
fetch fs00b random-binary00.bin s10
fetch fs01b random-binary01.bin s10
fetch fs02b random-binary02.bin s10
fetch fs03b random-binary03.bin s10
fetch fs04b random-binary04.bin s10
fetch fs05b random-binary05.bin s10
fetch fs06b random-binary06.bin s10
fetch fs07b random-binary07.bin s10
fetch fs08b random-binary08.bin s10
fetch fs09b random-binary09.bin s10
# Refetch everything
fetch fs00c random-binary00.bin s10
fetch fs01c random-binary01.bin s10
fetch fs02c random-binary02.bin s10
fetch fs03c random-binary03.bin s10
fetch fs04c random-binary04.bin s10
fetch fs05c random-binary05.bin s10
fetch fs06c random-binary06.bin s10
fetch fs07c random-binary07.bin s10
fetch fs08c random-binary08.bin s10
fetch fs09c random-binary09.bin s10
fetch fc00c random-binary00.bin s0
fetch fc01c random-binary01.bin s1
fetch fc02c random-binary02.bin s2
fetch fc03c random-binary03.bin s3
fetch fc04c random-binary04.bin s4
fetch fc05c random-binary05.bin s0
fetch fc06c random-binary06.bin s1
fetch fc07c random-binary07.bin s2
fetch fc08c random-binary08.bin s3
fetch fc09c random-binary09.bin s4
# Refetch everything
fetch fs00d random-binary00.bin s10
fetch fs01d random-binary01.bin s10
fetch fs02d random-binary02.bin s10
fetch fs03d random-binary03.bin s10
fetch fs04d random-binary04.bin s10
fetch fc00d random-binary00.bin s0
fetch fc01d random-binary01.bin s1
fetch fc02d random-binary02.bin s2
fetch fc03d random-binary03.bin s3
fetch fc04d random-binary04.bin s4
fetch fc05d random-binary05.bin s0
fetch fc06d random-binary06.bin s1
fetch fc07d random-binary07.bin s2
fetch fc08d random-binary08.bin s3
fetch fc09d random-binary09.bin s4
fetch fs05d random-binary05.bin s10
fetch fs06d random-binary06.bin s10
fetch fs07d random-binary07.bin s10
fetch fs08d random-binary08.bin s10
fetch fs09d random-binary09.bin s10
wait *
check fc00a
check fc01a
check fc02a
check fc03a
check fc04a
check fc05a
check fc06a
check fc07a
check fc08a
check fc09a
check fc00b
check fc01b
check fc02b
check fc03b
check fc04b
check fc05b
check fc06b
check fc07b
check fc08b
check fc09b
check rc05a
check rc06a
check rc07a
check rc08a
check rc09a
check rc10
check rc11
check rc12
check rc13
check rc14
check fs00a
check fs01a
check fs02a
check fs03a
check fs04a
check fs05a
check fs06a
check fs07a
check fs08a
check fs09a
check fs00b
check fs01b
check fs02b
check fs03b
check fs04b
check fs05b
check fs06b
check fs07b
check fs08b
check fs09b
check rs05a
check rs06a
check rs07a
check rs08a
check rs09a
check rs10
check rs11
check rs12
check rs13
check rs14
check fc00c
check fc01c
check fc02c
check fc03c
check fc04c
check fc05c
check fc06c
check fc07c
check fc08c
check fc09c
check fs00c
check fs01c
check fs02c
check fs03c
check fs04c
check fs05c
check fs06c
check fs07c
check fs08c
check fs09c
check fc00d
check fc01d
check fc02d
check fc03d
check fc04d
check fc05d
check fc06d
check fc07d
check fc08d
check fc09d
check fs00d
check fs01d
check fs02d
check fs03d
check fs04d
check fs05d
check fs06d
check fs07d
check fs08d
check fs09d
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
quit



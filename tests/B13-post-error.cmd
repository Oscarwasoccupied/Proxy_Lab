serve s1
generate random-text.txt 4K
post-request f1 random-text.txt s1
wait *
check f1 501
quit
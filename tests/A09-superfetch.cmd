# Test ability to handle lots of fetches
serve sa sb sc    # Set up 3 servers
generate random-text1.txt 2K 
generate random-text2.txt 4K 
generate random-text3.txt 6K
generate random-text4.txt 8K
generate random-text5.txt 10K
generate random-text6.txt 12K
fetch f1a random-text1.txt sa
fetch f2a random-text2.txt sa
fetch f6a random-text6.txt sa
fetch f2b random-text2.txt sb
fetch f3a random-text3.txt sa
fetch f5c random-text5.txt sc
fetch f4a random-text4.txt sa
fetch f6b random-text6.txt sb
fetch f4c random-text4.txt sc
fetch f3b random-text3.txt sb
fetch f5b random-text5.txt sb
fetch f6c random-text6.txt sc
fetch f3c random-text3.txt sc
fetch f4b random-text4.txt sb
fetch f2c random-text2.txt sc
fetch f1b random-text1.txt sb
fetch f5a random-text5.txt sa
fetch f1c random-text1.txt sc
wait *
check f1a
check f1b
check f1c
check f2a
check f2b
check f2c
check f3a
check f3b
check f3c
check f4a
check f4b
check f4c
check f5a
check f5b
check f5c
check f6a
check f6b
check f6c
quit


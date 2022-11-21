# Test ability to fetch very small text file
serve s1                       # Set up server
generate random-text.txt 50    # Create file
fetch f1 random-text.txt s1    # Fetch it from server
wait *
check f1                       # Make sure it's correct
trace f1                       # Run trace on transaction
quit                           # Exit program


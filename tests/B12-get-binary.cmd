# Test ability of proxy to get binary data from real web server
# These data came from versions of the SCS and ECE home pages
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece_files/radiocity.png
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece_files/USflag.jpg
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs_files/banner-for-the-founders.png
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs_files/banner-cmu-ai.png
# Nonexistent URLs.  Should yield status code 404
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece_files/nonexistent.jpg
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs_files/nonexistent.png
quit
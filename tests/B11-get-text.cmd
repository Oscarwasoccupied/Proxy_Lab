# Test ability of proxy to get text data from actual web server
# Replicas of home pages
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece.html
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs.html
# Objects referenced by these pages
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece_files/bootstrap.css
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece_files/widgets.js
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs_files/analytics.js
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs_files/font-awesome.css
# Nonexistent URLs.  Should yield status code 404
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/ece_files/nonexistent.css
get http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15213/public/proxylab/scs_files/nonexistent.js
quit
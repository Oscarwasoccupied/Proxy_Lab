#!/usr/bin/python

############################################################################
#  Proxylab testing framework
#  Main program
############################################################################

# Driver for testing Proxy Lab

import sys
import os
import socket
import os
import getopt
import time
import subprocess
import threading
import datetime
import signal

import console
import agents
import events
import files


def usage(name):
    print "Usage: %s -h [-q] ([-p PROXY]|[-P HOST:PORT]) [-f FILE] [-c (0-4)] [-l LOGFILE] [-d STRETCH]" % name
    print "  -h           Print this message"
    print "  -q           Operate in quiet mode"
    print "  -p PROXY     Run specified proxy"
    print "  -P HOST:PORT Use proxy running on specified host and port"
    print "  -f FILE      Read commands from FILE"
    print "  -c CHECK     Set level of checking options (0-4)"
    print "  -l FILE      Save results in FILE"
    print "  -d STRETCH   Set stretch value for all delays"
    sys.exit(0)

# Hidden options (research use only)
#    print "  -w WRAPLIB Specify wrapper .so file"

# Global parameters
# Set to home directory for program, split into tokens
homePathFields = ['.']
# Where is the pthreads+read+write wrapper library
wrapperLibrary = "wrapper.so"
# Where is the optimized file generator
fileGenerator = "file_generator"

def findWrapperLibrary():
    fields = homePathFields + [wrapperLibrary]
    path = '/'.join(fields)
    return path

def findFileGenerator():
    fields = homePathFields + [fileGenerator]
    path = '/'.join(fields)
    return path

class Driver:

    portLimit = 10
    host = "localhost"
    # Options (of type console.Option)
    verbose = None
    strict = None
    insertDelays = None
    autoTrace = None
    stretch = None
    timeout = None

    console = None
    eventManager = None
    fileManager = None
    requestManager = None
    portManager = None
    heartbeatManager = None
    servers = {}
    # Connections to stdout and stderr from proxy
    monitors = []

    # Is there an active proxy?
    haveProxy = False
    proxyProcess = None
    getId = 0


    # Mapping from id to event.  Used to implement wait *
    activeEvents = {}

    def __init__(self):
        self.verbose = console.Option(False)
        self.strict = console.Option(0)
        self.autoTrace = console.Option(False)
        self.stretch = console.Option(100)
        self.timeout = console.Option(5000)
        self.checkTiming = console.Option(False)
        self.checkUnsafe = console.Option(False)
        self.checkLocking = console.Option(False)
        self.checkSemaphore = console.Option(False)
        self.linefeedPercent = console.Option(5)

        self.console = console.Command()
        self.console.finishFunction = self.finish
        self.host = socket.gethostname()
        self.eventManager = events.EventManager()
        self.fileManager = files.FileManager(printer = self.console, fileGenerator = findFileGenerator())
        self.fileManager.purgeResponseFiles()
        self.requestManager = agents.RequestGenerator(self.eventManager, self.fileManager, self.console, strict = self.strict, verbose = self.verbose)
        self.portManager = agents.PortFinder(self.console)
        self.servers = {}
        self.monitors = []
        self.haveProxy = False
        self.proxyProcess = None
        self.activeEvents = {}
        self.getId = 0

        self.console.addOption("strict", self.strict, "Set level of strictness on HTTP message formatting (0-4)")
        self.console.addOption("timing", self.checkTiming, "Insert random delays into synchronization operations")
        self.console.addOption("unsafe", self.checkLocking, "Check for thread-unsafe functions")
        self.console.addOption("locking", self.checkLocking, "Check proper use of locks")
        self.console.addOption("semaphore", self.checkSemaphore, "Disallow use of semaphores")
        self.console.addOption("verbose", self.verbose, "Show details")
        self.console.addOption("stretch", self.stretch, "Multiply all delays by factor = stretch / 100")
        self.console.addOption("timeout", self.timeout, "Set default timeout for wait (in milliseconds)")
        self.console.addOption("autotrace", self.autoTrace, "Trace every request for which check fails")
        self.console.addOption("linefeed", self.linefeedPercent, "Frequency of line feeds in binary files (percent)")
        self.console.addCommand("serve", self.doServe,         "SID+",   "Set up servers.  (Server with SID starting with '-' is disabled.)")
        self.console.addCommand("request", self.doRequest,     "ID FILE SID",    "Initiate request named ID for FILE from server SID")
        self.console.addCommand("post-request", self.doPostRequest,     "ID FILE SID",    "Initiate request named ID for FILE from server SID")
        self.console.addCommand("fetch", self.doFetch,     "ID FILE SID",    "Fetch FILE from server SID using request named ID")
        self.console.addCommand("respond", self.doRespond,     "ID+",   "Allow servers to return reponses to requests")
        self.console.addCommand("get", self.doGet,            "URL", "Retrieve web object with and without proxy and compare the two")
        self.console.addCommand("delay", self.doDelay,         "MS",              "Delay for MS milliseconds")
        self.console.addCommand("check", self.doCheck,         "ID [CODE]",     "Make sure request ID handled properly and generated expected CODE")
        self.console.addCommand("generate", self.doGenerate,   "FILE BYTES",      "Generate file (extension '.txt' or '.bin') with specified number of bytes")
        self.console.addCommand("delete", self.doDelete,       "FILE+",  "Delete specified files")
        self.console.addCommand("proxy", self.doProxy,         "[PATH] ARG*", "(Re)start proxy server (pass arguments to proxy)")
        self.console.addCommand("external", self.doExternalProxy,    "HOST:PORT", "Use external proxy")
        self.console.addCommand("trace", self.doTrace,         "ID+",   "Trace histories of requests")
        self.console.addCommand("signal", self.doSignal,       "[SIGNO]", "Send signal number SIGNO to process.  Default = 13 (SIGPIPE)")
        self.console.addCommand("disrupt", self.doDisrupt,     "(request|response) [SID]", "Schedule disruption of request or response by client [or server SID]")
        self.console.addCommand("wait", self.doWait,          "* | ID+", "Wait until all or listed pending requests, fetches, and responses have completed")


    def run(self, commandList = []):
        self.console.run(commandList)

    def handleSignal(self, signum, frame):
        print "Pxydrive Received signal %d.  Terminating proxy" % signum
        if self.proxyProcess is not None:
            try:
                self.proxyProcess.terminate()
                self.proxyProcess = None
            except Exception:
                # Couldn't terminate.  Probably already dead
                pass
        print "Shutting down monitors"
        for m in self.monitors:
            m.shutdown()
        self.monitors = []
        self.console.outMsg("Exiting")
        print "Closing files"
        self.console.closeFiles()
        sys.exit(1)


    def finish(self):
        allOK = self.requestManager.allOK
        if self.proxyProcess is not None:
            try:
                self.proxyProcess.terminate()
                self.proxyProcess = None
            except Exception:
                self.console.errMsg("Couldn't terminate proxy")
                # Couldn't terminate.  Probably already dead
                pass
        for m in self.monitors:
            m.shutdown()
        self.monitors = []
        self.eventManager.stop()  # Prevent queuing of any more events

        if self.heartbeatManager is not None:
#            self.heartbeatManager.report()
            self.heartbeatManager.stop()
        for s in self.servers.values():
            s.stop()
        for s in self.servers.values():
            allOK = allOK and s.waitForExit()
        self.eventManager.shutdown()
#        self.requestManager.cacheStatistics()
        return allOK

    # Check existence and status of proxy.
    # Return either (True, "") or (False, Message)
    def checkProxy(self):
        signalDict = { 4  : "Illegal instruction",
                       7  : "Bus error",
                       8  : "Floating-point exception",
                       10 : "Bus error",
                       11 : "Segmentation violation",
                       13 : "Broken pipe"
                     }
                       
                       
        if self.haveProxy:
            if self.proxyProcess is None:
                # External proxy
                return (True, "")
            elif self.proxyProcess.poll():
                # Terminated proxy
                code = self.proxyProcess.returncode
                explain = ""
                if code < 0 and -code in signalDict:
                    explain = " (%s)" % signalDict[-code]
                return (False, "The proxy exited with return code %d%s" % (code, explain))
            else:
                # Running proxy
                return (True, "")
        else:
            return (False, "There is no proxy running")
        

    def doServe(self, args):
        ok = True
        for id in args:
            if id in self.servers:
                self.console.errMsg("Duplicate server id '%s'" % id)
                ok = False
                continue
            disabled = id[0] == '-'
            s = agents.Server(self.host, self.portLimit, self.eventManager, self.fileManager,
                              self.portManager, self.console,
                              id = id, strict = self.strict, verbose = self.verbose, disabled = disabled)
            if disabled:
                self.servers[id] = s
                self.console.outMsg("Disabled server %s set up at %s:%d" % (id, self.host, s.port))
            elif s.running:
                self.servers[id] = s
                self.console.outMsg("Server %s running at %s:%d" % (id, self.host, s.port))
            else:
                self.console.outMsg("Couldn't set up server %s" % id)
                ok = False
        
        return ok

    def doRequestOrFetch(self, args, isFetch, isPost):
        if len(args) != 3:
            command = "Fetch" if isFetch else "Request"
            self.console.errMsg("%s requires three arguments" % command)
            return False
        (status, msg) = self.checkProxy()
        if not status:
            command = "Fetch" if isFetch else "Request"
            self.console.errMsg("Cannot execute %s. %s" % (command, msg))
            return False
        rid = args[0]
        file = args[1]
        sid = args[2]
        if sid not in self.servers:
            self.console.errMsg("Invalid server name %s" % sid)
            return False
        server = self.servers[sid]
        try:
            event = self.eventManager.addRequestEvent(rid, server = sid, isFetch = isFetch)
        except events.EventException as ex:
            self.console.errMsg("Couldn't generate request event %s (%s)" % (rid, ex))
            return False
        url = server.generateURL(file)
        if self.verbose.getBoolean():
            self.console.outMsg("Attempting URL %s on server %s" % (url, sid))
        disrupting = self.requestManager.disruption == agents.Disruption.request
        if not disrupting:
            self.activeEvents[rid] = event
        success = self.requestManager.request(event, url, isFetch, isPost)
        return success != disrupting

    def doFetch(self, args):
        return self.doRequestOrFetch(args, True, False)

    def doRequest(self, args):
        return self.doRequestOrFetch(args, False, False)

    def doPostRequest(self, args):
        return self.doRequestOrFetch(args, True, True)


    def doRespond(self, args):
        (status, msg) = self.checkProxy()
        if not status:
            self.console.errMsg("Cannot execute respond. %s" % msg)
            return False
        ok = True
        for rid in args:
            event = self.eventManager.findEvent(False, rid)
            if event is None:
                ok = False
                self.console.errMsg("Invalid request ID '%s'" % rid)
            else:
                self.activeEvents[rid] = event
                event.release()
                reason = "" if event.text == "" else " (%s)" % event.text 
                self.console.outMsg("Server responded to request %s with status %s%s" % (rid, event.tag, reason))
        return ok

    def doGet(self, args):
        (status, msg) = self.checkProxy()
        if not status:
            self.console.errMsg("Cannot execute get. %s" % msg)
            return False
        if len(args) != 1:
            self.console.errMsg("Get command takes one argument")
            return False
        url = args[0]
        fields = url.split(':')
        if len(fields) == 1:
            url = "http://" + url
        elif len(fields) == 2:
            if fields[0] == 'https':
                self.console.errMsg("Do not support https protocol")
                return False
            if fields[0] != 'http':
                url = "http://" + url
        parts = self.requestManager.proxy
        proxy = "%s:%d" % (parts[0], parts[1])
        self.getId += 1
        (nstatus, npath) = self.fileManager.getURL(url, id = self.getId)
        (pstatus, ppath) = self.fileManager.getURL(url, proxy = proxy, id = self.getId)
        if nstatus != pstatus:
            self.console.errMsg("Get of URL with proxy returned status %d, but without proxy returned status %d" % (pstatus, nstatus))
            self.console.outMsg("URL = %s" % url)
            return False
        if nstatus != 200:
            self.console.outMsg("Get of URL with and without proxy returned the same status code: %d" % (nstatus))
            self.console.outMsg("URL = %s" % url)
            return True
        (match, reason) = self.fileManager.compareFiles(npath, ppath)
        if match:
            self.console.outMsg("Both copies of URL match.  Result in %s" % (npath))
            self.console.outMsg("URL = %s" % url)
            return True
        else:
            self.console.errMsg("Get of URL with and without proxy returned different results")
            self.console.outMsg("URL = %s" % url)
            self.console.outMsg(reason)
            return False


    def doDelay(self, args):
        if len(args) != 1:
            self.console.errMsg("Delay command takes one argument")
            return False
        try:
            ms = float(args[0]) * self.stretch.getInteger()/100.0
        except:
            self.console.errMsg("Invalid delay '%s'" % args[0])
            return False
        self.eventManager.delay(ms)
        pending = self.eventManager.getPending()
        ok = len(pending) == 0
        if not ok:
            self.console.errMsg("Warning.  %d events still pending" % len(pending))
            for e in pending:
                self.console.outMsg("  " + str(e))
        return ok

    def doWait(self, args):
        ok = True
        if len(args) == 0:
            self.console.errMsg("wait requires list of IDs or '*'")
            return False
        (status, msg) = self.checkProxy()
        if not status:
            self.console.errMsg("Cannot execute wait. %s" % msg)
            return False
        if len(args) == 1 and args[0] == '*':
            checkEvents = self.activeEvents
            self.activeEvents = {}
        else:
            checkEvents = {}
            for id in args:
                e = self.eventManager.findEvent(True, id)
                if e is None:
                    ok = False
                    self.console.errMsg("Unknown id '%s'" % id)
                else:
                    checkEvents[id] = e
                    if id in self.activeEvents:
                        del self.activeEvents[id]
        if not ok:
            return False
        ms = int(self.timeout.getInteger() * self.stretch.getInteger()/100.0)
        (pending, msg) = self.eventManager.waitActive(checkEvents, ms)
        ok = len(pending) == 0
        if not ok:
            self.console.errMsg("%d events still pending.  %s" % (len(pending), msg))
            for e in pending:
                self.console.outMsg("  " + str(e))
        return ok

    def doCheck(self, args):
        if len(args) == 0 or len(args) > 2:
            self.console.errMsg("Check command requires 1-2 arguments")
            return False
        rid = args[0]
        checkTag = "ok"
        if len(args) > 1:
            try:
                code = int(args[1])
            except:
                self.console.errMsg("Invalid status code '%s'" % args[1])
                return False
            checkTag = self.requestManager.httpStatus.getTag(code)
        event = self.eventManager.findEvent(True, rid)
        if event is None:
            self.console.errMsg("Invalid request ID '%s'" % rid)
            return False
        if checkTag != event.tag:
            # see if can find matching request event
            reason = event.text
            if reason == "":
                requestEvent = self.eventManager.findEvent(False, rid)
                # See if can find useful information in corresponding request event
                if requestEvent is not None and event.tag == requestEvent.tag and requestEvent.text != "":
                    reason = requestEvent.text
            if reason == "" and event.tag == "requesting" and event.server in self.servers:
                # See received by server
                if self.servers[event.server].requestCount == 0:
                    reason = "Server did not receive any requests"
                elif self.servers[event.server].readingHeader:
                    reason = "Request header was not properly terminated"
            sreason = "" if reason == "" else (" (%s)" % reason)
            self.console.errMsg("Request %s generated status '%s'.  Expecting '%s'%s" % (rid, event.tag, checkTag, sreason))
            if self.autoTrace.getBoolean():
                self.trace(rid)
            return False
        self.console.outMsg("Request %s yielded expected status '%s'" % (rid, event.tag))
        return True

    def doGenerate(self, args):
        if len(args) != 2:
            self.console.errMsg("Generate command requires two arguments")
            return False
        fname = args[0]
        ssize = args[1]
        weight = 1
        while len(ssize) > 0 and ssize[-1].lower() in 'km':
            factor = 1000 if ssize[-1].lower() == 'k' else 1000*1000
            weight *= factor
            ssize = ssize[:-1]
        try:
            size = weight * int(ssize)
        except:
            self.console.errMsg("Invalid file size: %s" % args[1])
            return False
        path = self.fileManager.generateFile(fname, size, linefeedPercent = self.linefeedPercent.getInteger())
        if path == "":
            return False
        if self.verbose.getBoolean():
            self.console.outMsg("Generated file '%s'" % path)
        return True
        
    def doDelete(self, args):
        ok = True
        for fname in args:
            ok = ok and self.fileManager.deleteFile(fname)
        return ok

    def doProxy(self, args):
        env = { }
        checkTiming = self.checkTiming.getBoolean()
        checkUnsafe = self.checkUnsafe.getBoolean()
        checkLocking = self.checkLocking.getBoolean()
        checkSemaphore = self.checkSemaphore.getBoolean()
        if checkTiming or checkLocking or checkSemaphore or checkUnsafe:
            if self.heartbeatManager is None:
                self.heartbeatManager = agents.HeartbeatManager(self.host, self.portLimit, self.portManager, self.console, verbose = self.verbose)
                self.eventManager.heartbeatManager = self.heartbeatManager
            env['LD_PRELOAD'] = findWrapperLibrary()
            env['CHECK_HOST'] = self.heartbeatManager.host
            env['CHECK_PORT'] = str(self.heartbeatManager.port)
            env['CHECK_TIMING'] = '1' if checkTiming else '0'
            env['CHECK_UNSAFE'] = '1' if checkUnsafe else '0'
            env['CHECK_LOCKING'] = '1' if checkLocking else '0'
            env['CHECK_SEMAPHORE'] = '1' if checkSemaphore else '0'
                
        # Terminate existing proxy
        if self.proxyProcess is not None:
            self.proxyProcess.terminate()
            self.proxyProcess = None
            self.requestManager.proxy = None
            self.haveProxy = False
            for m in self.monitors:
                m.shutdown()
            self.monitors = []
        if len(args) < 1:
            return True
        path = args[0]
        options = args[1:]
        port = None
        for t in range(self.portLimit):
            port = self.portManager.newPort()
            sport = str(port)
            try:
                def subprocess_setup():
                    # Stop ignoring SIGPIPE before exec
                    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

                if self.console.quietMode.getBoolean():
                    trashFile = open(os.devnull, 'w')
                    self.proxyProcess = subprocess.Popen([path] + options + [sport],
                                                         stdout = trashFile, stderr = trashFile,
                                                         preexec_fn = subprocess_setup,
                                                         env = env)
                    trashFile.close()
                else:
                    self.proxyProcess = subprocess.Popen([path] + options + [sport],
                                                         stdout = subprocess.PIPE, stderr = subprocess.PIPE,
                                                         preexec_fn = subprocess_setup,
                                                         env = env)
            except Exception as e:
                self.proxyProcess = None
                self.console.errMsg("Couldn't start proxy %s (%s) on attempt %d" % (path, str(e), t))
                if t == self.portLimit -1:
                    self.console.errMsg("Couldn't start proxy %s (%s)" % (path, str(e)))
                    return False

            if self.proxyProcess is not None:
                break

        if not self.console.quietMode.getBoolean():
            mout = files.FileMonitor(self.proxyProcess.stdout, self.console, id = "Proxy stdout")
            tout = threading.Thread(target = mout.run)
            tout.start()
            mout.thread = tout
            merr = files.FileMonitor(self.proxyProcess.stderr, self.console, id = "Proxy stderr")
            terr = threading.Thread(target = merr.run)
            terr.start()
            merr.thread = terr
            self.monitors = [mout, merr]
        time.sleep(0.15)
        if self.proxyProcess.poll():
            self.console.errMsg("Proxy process terminated with return code %d" % self.proxyProcess.returncode)
            self.proxyProcess = None
            return False
        self.requestManager.proxy = (self.host, port)
        self.haveProxy = True
        self.console.outMsg("Proxy set up at %s:%d" % self.requestManager.proxy)
        return True

    def doExternalProxy(self, args):
        # Make use of external proxy
        # Terminate any existing proxy
        self.doProxy([])
        host = ""
        sport = ""
        if len(args) == 1:
            # Supplied as host:port
            fields = args[0].split(":")
            if len(fields) != 2:
                self.console.errMsg("Require proxy to be specified as 'host:port'")
                return False
            host = fields[0]
            sport = fields[1]
        elif len(args) == 2:
            # Supplied as host port
            host = args[0]
            sport = args[1]
        else:
            self.console.errMsg("Require proxy to be specified as 'host:port'")
            return False
        try:
            port = int(sport)
        except:
            self.console.errMsg("Must provide port as number")
            return False
        if port <= 0:
            self.console.errMsg("Invalid port '%d'" % port)
            return False
        self.requestManager.proxy = (host, port)
        self.haveProxy = True
        self.console.outMsg("Using proxy at %s:%d" % self.requestManager.proxy)
        return True

    def trace(self, rid):
        lineLength = 80
        requestEvent = self.eventManager.findEvent(True, rid)
        responseEvent = self.eventManager.findEvent(False, rid)
        if requestEvent is None:
            self.console.errMsg("Unknown request id '%s'" % rid)
            return False
        outString = "== Trace of request %s " % rid
        pad = max(0, lineLength - len(outString))
        self.console.outMsg(outString + ("=" * pad))

        self.console.outMsg("Initial request by client had header:")
        for line in requestEvent.sentHeaderLines:
            self.console.outMsg(files.showLine(line))

        self.console.outMsg('-' * lineLength)

        if responseEvent is None or responseEvent.receivedHeaderLines == []:
            self.console.outMsg("Request NOT received by server")
        else:
            self.console.outMsg("Message received by server had header:")
            for line in responseEvent.receivedHeaderLines:
                self.console.outMsg(files.showLine(line))

        self.console.outMsg('-' * lineLength)

        if responseEvent is None or responseEvent.sentHeaderLines == []:
            self.console.outMsg("Reponse NOT sent by server")                
        else:
            self.console.outMsg("Message sent by server had header:")
            for line in responseEvent.sentHeaderLines:
                self.console.outMsg(files.showLine(line))

        self.console.outMsg('-' * lineLength)

        if requestEvent.receivedHeaderLines == []:
            self.console.outMsg("Response NOT received by client")
        else:
            self.console.outMsg("Message received by client had header:")
            for line in requestEvent.receivedHeaderLines:
                self.console.outMsg(files.showLine(line))

        self.console.outMsg('-' * lineLength)

        if responseEvent is not None:
            statusString = "Response status: " + responseEvent.tag
            if responseEvent.text != "":
                statusString += " (" + responseEvent.text + ")"
            self.console.outMsg(statusString)
            if responseEvent.path != "":
                self.console.outMsg("  Source file in %s" % responseEvent.path)

        statusString = "Request status:  " + requestEvent.tag
        if requestEvent.text != "":
            statusString += " (" + requestEvent.text + ")"
        self.console.outMsg(statusString)
        if requestEvent.path != "":
            self.console.outMsg("  Result file in %s" % requestEvent.path)

        return True

    def doTrace(self, args):
        ok = True
        for rid in args:
            ok = ok and self.trace(rid)
        return ok

    def doSignal(self, args):
        if len(args) > 1:
            self.console.errMsg("Signal command takes at most one argument")
            return False
        signo = 13 # SIGPIPE
        if len(args) == 1:
            try:
                signo = int(args[0])
            except:
                self.console.errMsg("Invalid signal number '%s'" % args[0])
                return False
        if self.proxyProcess is None:
            self.console.errMsg("No proxy running")
            return False
        self.proxyProcess.send_signal(signo)
        return True

    def doDisrupt(self, args):
        disruptor = agents.Disruption()
        if len(args) < 1 or len(args) > 3:
            self.console.errMsg("Disrupt command takes 1-2 arguments")
            return False
        dname = args[0]
        dis = disruptor.parse(dname)
        if dis == disruptor.none:
            self.console.errMsg("Disruption type must be '%s' or '%s'"
                                % (disruptor.names[1], disruptor.names[2]))
            return False
        if len(args) == 2:
            sid = args[1]
            if sid not in self.servers:
                self.console.errMsg("Invalid server name %s" % sid)
                return False
            server = self.servers[sid]
            server.scheduleDisruption(dis)
        else:
            self.requestManager.scheduleDisruption(dis)
        return True

def run(name, args):
    global wrapperLibrary
    quietMode = False
    checkTiming = False
    checkLocking = False
    checkSemaphore = False
    proxyPath = None
    proxyName = None
    fname = None
    logFilePath = None
    stretch = None
    try:
        optlist, args = getopt.getopt(args, "hqp:P:f:c:l:d:w:")
    except getopt.GetoptError as e:
        print "Command-line error (%s)" % str(e)
        usage(name)
    for opt, val in optlist:
        if opt == '-h':
            usage(name)
        if opt == '-q':
            quietMode = True
        elif opt == '-c':
            try:
                level = int(val)
            except:
                print "Invalid check level '%s'" % val
                usage(name)
            if level > 0:
                checkTiming = True
            if level > 1:
                checkUnsafe = True
            if level > 2:
                checkLocking = True
            if level > 3:
                checkSemaphore = True
        elif opt == '-p':
            proxyPath = val
        elif opt == '-P':
            proxyName = val
        elif opt == '-f':
            fname = val
        elif opt == '-l':
            logFilePath = val
        elif opt == '-d':
            try:
                stretch = int(val)
            except:
                print "Invalid value of stretch '%s'.  Must be integer (100 = unstretched)" % val
                usage(name)
        elif opt == '-w':
            wrapperLibrary = val

    commandList = []
    if quietMode:
        commandList += ["option quiet 1"]
    if logFilePath is not None:
        commandList += ["log " + logFilePath]
    if checkTiming:
        commandList += ["option timing 1"]       
    if checkLocking:
        commandList += ["option locking 1"]       
    if checkSemaphore:
        commandList += ["option semaphore 1"]       
    if proxyPath is not None:
        commandList += ["proxy " + proxyPath]
    if proxyName is not None:
        commandList += ["external " + proxyName]
    if stretch is not None:
        commandList += ["option stretch %d" % stretch]
    if fname is not None:
        commandList += ["source " + fname]
    d = None
    try:
        d = Driver()
        signal.signal(signal.SIGINT, d.handleSignal)
        signal.signal(signal.SIGTERM, d.handleSignal)
        d.run(commandList)
    except SystemExit:
        os._exit(1)
    except Exception as e:
        if d is None:
            sys.stderr.write("Fatal error in main program: %s\n" % str(e))
        else:
            d.console.errors += 1
            d.console.panic("main program", e)
            d.console.finish()

    if d.console.errors:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    current = os.path.realpath(__file__)
    homePathFields = current.split('/')[:-1]
    run (sys.argv[0], sys.argv[1:])

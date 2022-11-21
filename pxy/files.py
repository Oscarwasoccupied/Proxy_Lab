############################################################################
#  Proxylab testing framework
#  Creating and using test files
############################################################################

import datetime
import random
import os
import os.path
import sys
import glob
import urllib2
import select
import socket
import subprocess
import StringIO
import traceback

# Special characters
spaceCharacters = " \t\r\n"
# Printed form
spaceMap = { ' '  : ' '  ,
             '\t' : '\\t',
             '\n' : '\\n',
             '\r' : '\\r'}


# Put line in printable form
def showLine(line):
    outLine = ""
    for c in line:
        if c in spaceCharacters:
            outLine += spaceMap[c]
        else:
            outLine += c
    return outLine


class Printer:
    outFiles = None

    def __init__(self):
        self.outFiles = [sys.stdout]

    def addFile(self,file):
        self.outFiles.append(file)

    def outMsg(self, s, noreturn = False):
        if len(s) == 0:
            s = "NULL\n"
        elif not noreturn and s[-1] != '\n':
            s += '\n'
        for f in self.outFiles:
            f.write(s)

    def errMsg(self, s, noreturn = False):
        self.outMsg("ERROR: " + s)

    def warnMsg(self, s, noreturn = False):
        self.outMsg("WARNING: " + s)

    def panic(self, info, exception):
        self.errMsg("Uncaught exception encountered in %s (%s)" % (info, exception))
        buffer = StringIO.StringIO()
        traceback.print_tb(sys.exc_traceback, 2, buffer)
        self.outMsg(buffer.getvalue())
        buffer.close()

    def close(self):
        for f in self.outFiles:
            if f != sys.stdout:
                f.close()
    


# Utility operations on text
class TextUtil:
    # For binary files, enhanced chance of byte value 0
    zeroProb = 0.05
    # Put in lots of linefeeds, to discourage line-by-line reading of data
    lfProb = 0.05 
    lowText = ord(' ')
    highText = ord('~')
    lf = '\n'
    printForms = { '\t': '<tab>',
                   '\n': '<newline>',
                   '\r': '<return>',
                   ' ':  '<sp>',
                   chr(0x0): '<null>'
                 }
    

    def __init__(self):
        pass

    def linefeed(self, pct):
        if pct >= 0 and pct <= 100:
           self.lfProb = float(pct)/100.0

    def randomCharacter(self, binary):
        if binary and random.uniform(0.0, 1.0) < self.zeroProb:
            return chr(0)
        if binary and random.uniform(0.0, 1.0) < self.lfProb:
            return self.lf
        low = 1 if binary else self.lowText
        high = 255 if binary else self.highText
        return chr(random.randint(low, high))
        
    def showCharacter(self, c, hexOnly):
        v = ord(c)
        if hexOnly:
            return "hex %s" % hex(v)
        if self.lowText <= v and v <= self.highText:
            return "'%s' (hex %s)" % (c, hex(v))
        if c in self.printForms:
            return "%s (hex %s)" % (self.printForms[c], hex(v))
        return "hex %s" % hex(v)

# Create source files and compare with response files
class FileManager:
    # General parameters
    # Location of source files
    sourceFilePath = "./source_files"
    # Location where result files are stored
    responseFilePath = "./response_files"
    # Location where files retrieved by get are stored
    getFilePath = "./get_files"
    # Name of (optional) file generation program
    fileGenerator = None

    # Standard line length for generated text files
    lineLength = 80

    # Subdirectories with permanent files
    staticDirectories = ["images", "icons"]
    # Subdirectory with generated files
    dynamicDirectory = "random"


    # Mapping of extensions to subdirectories
    extensionMap = {
        "bin" : "random",
        "txt" : "random",
        "jpg" : "images",
        "ico" : "icons",
        
        }

    # Dictionaries mapping generated files to length.
    staticFiles = {}
    generatedFiles = {}
    gottenFiles = {}

    textHandler = None
    printer = None

    def __init__(self, printer = None, fileGenerator = None):
        if printer is None:
            self.printer = Printer()
        else:
            self.printer = printer
        if fileGenerator is not None and os.path.exists(fileGenerator):
            self.fileGenerator = fileGenerator
        self.textHandler = TextUtil()
        self.loadStaticFiles()
        if not self.testPath(self.responseFilePath):
            try:
                os.mkdir(self.responseFilePath)
            except Exception as e:
                self.printer.errMsg("Couldn't create directory %s (%s)" % (self.responseFilePath, e))
                return
        self.purgeResponseFiles()
        if not self.testPath(self.sourceFilePath):
            try:
                os.mkdir(self.sourceFilePath)
            except Exception as e:
                self.printer.errMsg("Couldn't create directory %s: %s" % (self.sourceFilePath, e))
                return
        rpath = self.sourceFilePath + "/random"
        if not self.testPath(rpath):
            try:
                os.mkdir(rpath)
            except Exception as e:
                self.printer.errMsg("Couldn't create directory %s: %s" % (rpath, e))
                return
        self.purgeDynamicFiles()
        dynamicPath = self.sourceFilePath + "/" + self.dynamicDirectory
        if not self.testPath(dynamicPath):
            try:
                os.mkdir(dynamicPath)
            except Exception as e:
                self.printer.errMsg("Couldn't create directory %s: %s" % (dynamicPath, e))
        if not self.testPath(self.getFilePath):
            try:
                os.mkdir(self.getFilePath)
            except Exception as e:
                self.printer.errMsg("Couldn't create directory %s (%s)" % (self.responseFilePath, e))
                return
        self.purgeGottenFiles()
                
    def loadStaticFiles(self):
        for d in self.staticDirectories:
            matchp = self.sourceFilePath + "/" + d + "/*"
            for p in glob.glob(matchp):
                hierarchy = p.split("/")
                fname = hierarchy[-1]
                statinfo = os.stat(p)
                length = statinfo.st_size
                self.staticFiles[fname] = length

    # Get extension from file
    def getExtension(self, fname):
        fields = fname.split(".")
        if len(fields) <= 1:
            return ""
        else:
            return fields[-1]

    def isBinary(self, extension):
        return extension in ("bin", "jpg", "ico", "data")

    def sourcePath(self, fname):
        subDirectory = "random"
        extension = self.getExtension(fname)
        if extension in self.extensionMap:
            subDirectory = self.extensionMap[extension]
        return self.sourceFilePath + "/" + subDirectory + "/" + fname

    def responsePath(self, fname):
        return self.responseFilePath + "/" + fname

    def getPath(self, fname):
        return self.getFilePath + "/" + fname

    def testPath(self, path):
        return os.path.exists(path)

    def generateFile(self, fname, bytes, linefeedPercent = None):
        extension = self.getExtension(fname)
        if extension not in ("bin", "txt"):
            self.printer.errMsg("Cannot generate file of type '%s'" % extension)
            return ""
        binary = self.isBinary(extension)
        if fname in self.generatedFiles:
            self.deleteFile(fname)
        path = self.sourcePath(fname)

        if self.fileGenerator is not None:
            # Try generating this with separate program
            cmd = [self.fileGenerator, "-p", path, "-n", str(bytes)]
            if binary:
                cmd += ['-b']
            if linefeedPercent is not None:
                cmd += ['-l', str(linefeedPercent)]
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr = subprocess.PIPE)
            p.communicate()
            if p.returncode == 0:
                self.generatedFiles[fname] = bytes
                return path
        # Must do with own code
        if binary and linefeedPercent is not None:
            self.textHandler.linefeed(linefeedPercent)
        # Seed random number based on file fname
        random.seed(fname)

        try:
            f = outfile = open(path, 'w')
        except Exception as e:
            self.printer.errMsg("Couldn't open file %s: %s" % (fname, e))
            return ""
        if binary:
            for i in xrange(bytes):
                f.write(self.textHandler.randomCharacter(True))
        else:
            for l in xrange(0, bytes, self.lineLength):
                bcnt = min(self.lineLength, bytes-l)-1
                for i in xrange(bcnt):
                    f.write(self.textHandler.randomCharacter(False))
                f.write('\n')
        f.close()
        self.generatedFiles[fname] = bytes
        return path

    def deleteFile(self, name):
        if name is None:
            return False
        if name in self.generatedFiles:
            path = self.sourcePath(name)
            try:
                os.remove(path)
            except Exception as e:
                self.printer.warnMsg("Internal inconsistency.  Couldn't remove file %s" % name)
                return False
            del self.generatedFiles[name]
            return True
        elif name in self.gottenFiles:
            path = self.getPath(name)
            try:
                os.remove(path)
            except Exception as e:
                self.printer.warnMsg("Internal inconsistency.  Couldn't remove file %s" % name)
                return False
            del self.gottenFiles[name]
            return True
                
        else:
            self.printer.errMsg("Unknown file %s" % name)
            return False

    def deleteAllFiles(self):
        for name in self.generatedFiles.keys():
            self.deleteFile(name)
        for name in self.gottenFiles.keys():
            self.deleteFile(name)

    def purgeDynamicFiles(self):
        for path in glob.glob(self.sourceFilePath + "/" + self.dynamicDirectory + "/*"):
            try:
                os.remove(path)
            except Exception as e:
                self.printer.warnMsg("Internal inconsistency.  Couldn't remove file %s" % path)        

    def purgeResponseFiles(self):
        for path in glob.glob(self.responseFilePath + "/*"):
            try:
                os.remove(path)
            except Exception as e:
                self.printer.warnMsg("Internal inconsistency.  Couldn't remove file %s" % path)        

    def purgeGottenFiles(self):
        for path in glob.glob(self.getFilePath + "/*"):
            try:
                os.remove(path)
            except Exception as e:
                self.printer.warnMsg("Internal inconsistency.  Couldn't remove file %s" % path)        

    # Retrieve file.  Return tuple (length, path, file)
    def findFile(self, name, nofile = False):
        if name in self.generatedFiles:
            path = self.sourcePath(name)
            length = self.generatedFiles[name]
        elif name in self.staticFiles:
            path = self.sourcePath(name)
            length = self.staticFiles[name]
        else:
            return (0, "", None)
        if nofile:
            f = None
        else:
            try:
                f = open(path, 'r')
            except:
                self.printer.warnMsg("Internal inconsistency.  Couldn't open file %s" % name)
                return (0, path, None)
        return (length, path, f)

    # Retrieve file via its URL.  Store as file in get directory
    # File name based on id and whether or not uses proxy
    # proxy should be of form HOST:PORT
    # Returns (status_code, path)
    def getURL(self, url, proxy = None, id = 0):
        opener = urllib2.build_opener()

        # Install handler for HTTP proxy
        if proxy is not None:
            proxies = {'http': proxy}
            proxy_handler = urllib2.ProxyHandler(proxies)
            opener.add_handler(proxy_handler)

        # Make HTTP request
        try:
            r = opener.open(url, timeout=2)
            status_code = r.getcode()
            content = r.read()
        except:
            return (400, None)

        if status_code != 200:
            return (status_code, None)

        tag = "noproxy" if proxy is None else "proxied"
        fname = "get-%.3d-%s.data" % (id, tag)
        path = self.getFilePath + '/' + fname
        try:
            outf = open(path, 'wb')
        except Exception as ex:
            self.printer.errMsg("Couldn't open file '%s' to save retrieved web content")
            return (666, None)
        outf.write(content)
        outf.close()
        self.gottenFiles[fname] = len(content)
        return (status_code, path)

    # Compare files.
    # If match, return (True, "")
    # If don't, return (False, explanation)
    def compareFiles(self, sourcePath, responsePath, isGet = False):
        sourceLabel = "non-proxied" if isGet else "source"
        responseLabel = "proxied" if isGet else "response"
        if sourcePath is None:
            if responsePath is None:
                return (True, "")
            else:
                return(False, "Invalid %s path" % sourceLabel)
        if responsePath is None:
            return(False, "Invalid %s path" % responseLabel)
        match = True
        reason = ""
        try:
            sourceLength = os.path.getsize(sourcePath)
        except:
            reason = "%s file %s does not exist" % (sourceLabel, sourcePath)
            return (False, reason)

        try:
            responseLength = os.path.getsize(responsePath)
        except:
            reason = "%s file %s does not exist" % (responseLabel, responsePath)
            return (False, reason)

        if sourceLength != responseLength:
            reason = "%s file is %d bytes long.  %s file is %d bytes long" % (sourceLabel, sourceLength, responseLabel, responseLength)
            return (False, reason)

        binary = self.isBinary(self.getExtension(sourcePath))
        sfile = None
        rfile = None
        try:
            sfile = open(sourcePath, 'r')
        except Exception as e:
            match = False        
            reason = "Internal error. Couldn't open file %s: %s" % (sourcePath, e)
        try:
            rfile = open(responsePath, 'r')
        except Exception as e:
            match = False
            reason = "Couldn't open file %s: %s" % (responsePath, e)
        byteCount = 0
        done = False
        mismatchCount = 0
        mismatchPosition = 0
        sourceChar = 'a'
        referenceChar = 'b'
        while byteCount < sourceLength:
            sstring = sfile.read(min(50000, sourceLength-byteCount))
            rstring = rfile.read(min(50000, responseLength-byteCount))
            if sstring != rstring:
                # find mismatch
                for offset in range(len(sstring)):
                    sc = sstring[offset]
                    rc = rstring[offset]
                    if sc != rc:
                        if mismatchCount == 0:
                            mismatchPosition =  byteCount + offset
                            sourceChar = self.textHandler.showCharacter(sc, binary)
                            referenceChar = self.textHandler.showCharacter(rc, binary)
                        mismatchCount += 1
            byteCount += len(sstring)
        if mismatchCount > 0:
            match = False
            reason = "Files %s and %s have %d mismatches.  First mismatch at position %d: %s != %s" % (
                sourcePath, responsePath, mismatchCount, mismatchPosition, sourceChar, referenceChar)
        sfile.close()
        rfile.close()
        return (match, reason)

# Thread that can be attached to a subprocess object's stdout or stderr.
# Echos anything produced by one of these files.    
class FileMonitor:

    file = None
    printer = None
    id = "FILE"
    running = True
    # Pointer to own thread
    thread = None

    def __init__(self, file, printer, id = None):
        self.file = file
        self.printer = printer
        if id is not None:
            self.id = id
        running = True

    def run(self):
        while self.running:
            rlist =  select.select([self.file], [], [], 1.0)[0]
            if len(rlist) == 0:
                if self.running:
                    continue
                else:
                    break
            try:
                line = self.file.readline()
            except:
                self.printer.outMsg("%s: Proxy terminated" % (self.id))
                break
            if len(line) == 0:
                # End of file
                break
            line = line.rstrip()
            self.printer.outMsg("%s: %s" % (self.id, line))

    def shutdown(self):
        self.running = False
        try:
            self.file.close()
        except Exception as e:
            # No big deal
            pass
        if self.thread is not None:
            self.thread.join()



# Put wrapper around sockets to make them more like files
# Inspired by CS:APP RIO package

# Exception that gets raised when detect request to shutdown socket
class ShutdownException(Exception):
    info = ""

    def __init__(self, info = ""):
        Exception.__init__(self)
        self.info = info

    def __str__(self):
        if self.info == "":
            return "Shutdown Socket"
        else:
            return "Shutdown Socket: %s" % self.info



class SocketFile:

    bufSize = 4096
    sock = None
    buffer = bytes("") # Buffer of received but unread characters
    shutdownFlag = False

    def __init__(self, sock):
        self.sock = sock
        self.sock.settimeout(1.0)
        self.buffer = bytes("")
        self.shutdownFlag = False

    def readlineb(self):
        # See if already have line in buffer
        pos = self.buffer.find('\n')
        while pos < 0:
            try:
                data = self.sock.recv(self.bufSize)
            except socket.timeout:
                if self.shutdownFlag:
                    raise ShutdownException('in function readlineb')
                else:
                    continue
            if len(data) == 0:
                rbuf = self.buffer
                self.buffer = bytes("")
                # Incomplete (perhaps empty) line
                return rbuf
            npos = data.find('\n')
            pos = npos if npos < 0 else len(self.buffer) + npos
            self.buffer += data
        result = self.buffer[:pos+1]
        self.buffer = self.buffer[pos+1:]
        return result
            
    
    # Read bytes, including those buffered up to bufSize
    def read(self):
        if len(self.buffer) > 0:
            result = self.buffer
            self.buffer = bytes("")
            return result
        while True:
            try:
                result = self.sock.recv(self.bufSize)
                return result
            except socket.timeout:
                if self.shutdownFlag:
                    raise ShutdownException('in function read')
        
    def shutdown(self):
        self.shutdownFlag = True

    def __str__(self):
        return str(self.sock.getsockname())
    
    def write(self, buf):
        self.sock.sendall(buf)

    def close(self):
        self.shutdown()
        try:
            self.sock.shutdown(socket.SHUT_RDWR)
        except Exception:
            # Ignore
            pass

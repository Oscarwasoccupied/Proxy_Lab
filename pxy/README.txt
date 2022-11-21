This directory contains the files implement the proxy testing
framework, including the programs pxydrive, pxyregress, and pxyrace.

Program files:

    pxydrive.py:   Main testing program

    pxyregress.py: Runs pxydrive over set of standard tests

Support files:

    agents.py:  Implements server and client for proxy

    console.py: Command-line interpreter

    events.py:	Manages transaction events

    files.py:	Support for miscellaneous file operations

    wrapper.so: Library to interposition calls to pthreads operations
      for doing concurrency checks

    file_generator: Executable program for generating files containing
      random characters or bytes.  Used by pxydrive.

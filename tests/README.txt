This directory contains a set of 50 files to different aspects of a proxy.

ANN-XXXX.cmd:
    Test basic operation of all proxies

BNN-XXXX.cmd:
    Test robustness: ability of proxy to continue after error occurs 
    and compliance to header formatting requirements

CNN-XXXX.cmd
    Test operation of a concurrent proxy

DNN-XXXX.cmd
    Test operation of a caching proxy
    First five can be passed by sequential proxy
    Remaining require concurrent proxy

ENN-XXXX.cmd
    Stress testing of concurrency

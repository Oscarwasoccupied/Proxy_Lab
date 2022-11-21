#!/usr/bin/env bash

#simple program to accompany Pxydrive. Used by autograder to grade submissions

dir=$(pwd)

# Per test weights of different test categories
WEIGHT_A=2
WEIGHT_B=1
WEIGHT_C=3
WEIGHT_D=2

# Stretch factors for pxydrive delays
CP_STRETCH=150
FULL_STRETCH=200


if [ $# -eq 0 ]; then
  echo "Full submission testing"
  echo "Running with stretch = ${FULL_STRETCH}"
  pxy/pxyregress.py -p ./proxy -t 120 -L results.log -c 4 -d ${FULL_STRETCH} -a 5
  cd logs
  score_A=0
  score_B=0
  score_C=0
  score_D=0
  numPassed=0
  for file in A*.log; do
    result=$(tac $file |egrep -a -m 1 .)
    if [ "$result" = "ALL TESTS PASSED" ]; then
      numPassed=`expr ${numPassed} + 1`
    fi
  done
  score_A=$((numPassed*WEIGHT_A))
  numPassed=0
  for file in B*.log; do
    result=$(tac $file |egrep -a -m 1 .)
    if [ "$result" = "ALL TESTS PASSED" ]; then
      numPassed=`expr ${numPassed} + 1`
    fi
  done
  score_B=$((numPassed*WEIGHT_B))
  numPassed=0
  for file in C*.log; do
    result=$(tac $file |egrep -a -m 1 .)
    if [ "$result" = "ALL TESTS PASSED" ]; then
      numPassed=`expr ${numPassed} + 1`
    fi
  done
  score_C=$((numPassed*WEIGHT_C))
  numPassed=0
  for file in D*.log; do
    result=$(tac $file |egrep -a -m 1 .)
    if [ "$result" = "ALL TESTS PASSED" ]; then
      numPassed=`expr ${numPassed} + 1`
    fi
  done
  score_D=$((numPassed*WEIGHT_D))
  totalScore=$((score_A+score_B+score_C+score_D))
  cd ..
  echo "{ \"scores\": {\"A\":${score_A}, \"B\":${score_B}, \"C\":${score_C}, \"D\":${score_D}}, \"scoreboard\": [${totalScore}, ${score_A}, ${score_B}, ${score_C}, ${score_D}]}"
elif [ $1 == "check" ]; then
  echo "Checkpoint submission testing"
  echo "Running with stretch = ${CP_STRETCH}"
  pxy/pxyregress.py -p ./proxy -s AB -t 120 -L results.log -d ${CP_STRETCH} -a 5
  cd logs
  score_A=0
  score_B=0
  numPassed=0
  for file in A*.log; do
    result=$(tac $file |egrep -a -m 1 .)
    if [ "$result" = "ALL TESTS PASSED" ]; then
      numPassed=`expr ${numPassed} + 1`
    fi
  done
  score_A=$((numPassed*WEIGHT_A))
  numPassed=0
  for file in B*.log; do
    result=$(tac $file |egrep -a -m 1 .)
    if [ "$result" = "ALL TESTS PASSED" ]; then
      numPassed=`expr ${numPassed} + 1`
    fi
  done
  score_B=$((numPassed*WEIGHT_B))
  totalScore=$((score_A+score_B))
  cd ..
  echo "{ \"scores\": {\"A\":${score_A}, \"B\":${score_B}}, \"scoreboard\": [${totalScore}, ${score_A}, ${score_B}]}"
else
  echo "Run without arguments to run full PxyRegress test suite for final submission"
  echo "Run with argument 'check' to run PxyRegress test suit for checkpoint submission"
fi

exit
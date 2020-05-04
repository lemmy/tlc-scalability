/*
NAME
  bakery : Lamport's bakery algorithm

DESCRIPTION
  Lamport's bakery algorithm is a classical algorithm of mutual exclusion.

AUTHER
  Fumiyoshi Kobayashi

HISTORY
  2008/08/18(Sun) New

Copyright(C) 2008 Fumiyoshi Kobayashi, Ueda Laboratory.
*/

#ifndef  N
#define  N  4
#endif

bit choosing[N];
byte number[N];
byte in_cs;

init {
  atomic {
    byte i = 0;

    do
    :: i < N -> run P(i); i++;
    :: else  -> break;
    od;
  }
}

inline maximum(max, min, i) {
  i = 0;
  max = 0;
  min = 255;
  do
  :: i < N  ->
     if
     :: max <  number[i] -> max = number[i];
     :: max >= number[i];
     fi;
     if
     :: (min > number[i]) && (number[i] != 0) -> min = number[i];
     :: min <= number[i] || number[i] == 0;
     fi;
     i++;
  :: i == N -> break;
  od;
  if
  :: min == 255;
  :: min != 255 -> i = 0; min--;
     max = max - min;
     do
     :: i < N ->
        if
        :: number[i] != 0 -> number[i] = number[i] - min;
        :: number[i] == 0;
        fi;
        i++;
     :: i == N -> break;
     od;
  fi;
}

proctype P(byte id) {
  byte max, min, i, j;
NonCritical:
  choosing[id] = true;
Wait:
  d_step {
    maximum(max, min, i); number[id] = 1 + max;
    choosing[id] = false; j = 0;
  }
  do
  :: j < N && choosing[j] == false ->
     if
     :: atomic { number[j] == 0; j++; }
     :: atomic { number[j] > number[id]; j++; }
     :: atomic { ((number[j] == number[id]) && (j >= id)); j++; }
     fi;
  :: atomic { j == N -> in_cs++; } break;
  od;
Critical:
  atomic { number[id] = 0; in_cs--; }
  goto NonCritical;
}

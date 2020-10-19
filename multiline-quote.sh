#!/bin/bash -eu

# Quote a single- or multi-line string for use in git's aliases
# Copyright (c) 2016 Tom Hale under https://en.wikipedia.org/wiki/MIT_License

quote() {
  printf %s "$1" | sed -r 's/(["\\])/\\\1/g';
}

IFS=$(printf '\n')
printf '\n!"'
read -r previous

while read -r line; do
  quote "$previous"
  printf ' \\n\\\n'
  previous="$line"
done

quote "$previous"
printf " #\"\n";


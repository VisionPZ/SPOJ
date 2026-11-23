import std/strutils

for line in lines(stdin):
  let numberText = line.strip
  if numberText == "42": break
  echo numberText

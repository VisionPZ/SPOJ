# SBANK - Sorting Bank Accounts

## Problem

A list of bank account numbers is given, with some accounts repeated. Sort them ascending and report how many times each account appears.

Up to 5 test cases, each with up to 100 000 bank account numbers of the same
fixed shape (`control digits`, an 8 digit bank code and 16 owner digits in
groups of four). Sort the account numbers ascending and print how many times
each one appears, with a blank line after every test case. Time limit is strict,
so reading and sorting must be fast.

## Idea

Read every account line as one string, collapse its spaces so equal accounts
become byte identical, sort the strings and count equal neighbours.

## Why It Works

All accounts have the same field layout, so ordinary string order is exactly the
required numeric order: comparing character by character compares the control
digits, then the bank code, then the owner groups in that order. After sorting,
identical accounts are neighbours, so one forward pass counts each group. Collapsing
runs of spaces matters because the input may carry a trailing space on each line
while the expected output has single spaces between the groups.

## Code

```nim
import algorithm

var output: string

proc emit(text: string) =
  output.add(text)
  if output.len >= 1 shl 19:
    stdout.write(output)
    setLen(output, 0)

proc compareAccounts(first: string, second: string): int =
  if first < second:
    return -1
  if first > second:
    return 1
  return 0

proc normalize(text: string): string =
  var trimmed = ""
  for i in 0 ..< text.len:
    if text[i] notin {' ', '\t', '\r', '\v', '\f'}:
      trimmed.add(text[i])
    elif trimmed.len > 0 and trimmed[^1] != ' ':
      trimmed.add(' ')
  if trimmed.len > 0 and trimmed[^1] == ' ':
    setLen(trimmed, trimmed.len - 1)
  return trimmed

proc readNonEmptyLine(): string =
  var current = ""
  while stdin.readLine(current):
    let text = normalize(current)
    if text.len > 0:
      return text
  return ""

proc readCount(): int =
  var value = 0
  let text = readNonEmptyLine()
  for i in 0 ..< text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
  return value

let caseCount = readCount()
for i in 0 ..< caseCount:
  let accountCount = readCount()
  var accounts: seq[string]
  for _ in 0 ..< accountCount:
    accounts.add(readNonEmptyLine())
  sort(accounts, compareAccounts)
  var j = 0
  while j < accounts.len:
    var repeatCount = 1
    while j + repeatCount < accounts.len and accounts[j + repeatCount] == accounts[j]:
      repeatCount += 1
    emit(accounts[j])
    emit(" ")
    emit($repeatCount)
    emit("\n")
    j += repeatCount
  emit("\n")
stdout.write(output)
```

## Complexity

Sorting n account strings costs O(n log n) comparisons of at most 34 characters
each; reading and counting cost O(n). Memory is O(n) for the stored strings,
about 7 MB per test case.

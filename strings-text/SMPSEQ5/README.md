# SMPSEQ5 — Fun with Sequences (Act 3) (SPOJ)

<https://www.spoj.com/problems/SMPSEQ5/>

## Problem

You have two lists of whole numbers. Print the positions where the two lists hold the same value, counting positions from one.

The input gives the size of the first list, then its numbers, then the size of the second list, then its numbers. The output is one line of positions separated by spaces.

| Item | Bound |
|---|---|
| First list size | 2 to 100 |
| Second list size | 2 to 100 |
| Each value | -100 to 100 |
| Judge limit | 1000 ms, 1536 MB |

The sample input:

```
5
-2 -2 -1 1 4
6
-3 -2 -1 1 2 3
```

The sample output:

```
2 3 4
```

The second sample has an unsorted first list, so the lists cannot be assumed sorted.

## Idea

Think of lining up two rows of cards and checking them column by column. Only matching columns get their column number printed.

The program stores both lists and compares each shared position once. That costs O(min(n, m)) with O(1) work per position.

## Why It Works

1. Position `index` is compared only when both lists have that position.
2. Adding one to the zero-based index gives the one-based position the problem wants.
3. Scanning positions upward already prints them in ascending order.
4. A space is written only before later positions, so the line has no trailing space.

| Term | Meaning |
|---|---|
| `sourceValues` | the first list |
| `queryValues` | the second list |
| `sharedLimit` | the smaller of the two list sizes |
| `matchedIndexes` | the one-based positions that match |

The shared limit keeps every comparison inside both lists.

A script-generated trace of the sample:

```
position 1: -2 vs -3, no match
position 2: -2 vs -2, match, print 2
position 3: -1 vs -1, match, print 3
position 4: 1 vs 1, match, print 4
position 5: 4 vs 2, no match
output: "2 3 4"
```

The trace matches the sample output exactly.

## Code

**Constants and scanner.** Read all input and scan integers, including negative ones.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value
```

The sign check comes after the skip loop. The skip loop must stop on a minus sign.

**Driver.** Store both lists, compare shared positions, and write one line.

```nim
let sourceCount = nextInt(inputData, scanPos)
var sourceValues = newSeq[int](sourceCount)
for index in 0 ..< sourceCount:
  sourceValues[index] = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var queryValues = newSeq[int](queryCount)
for index in 0 ..< queryCount:
  queryValues[index] = nextInt(inputData, scanPos)
var sharedLimit = sourceCount
if queryCount < sharedLimit:
  sharedLimit = queryCount
var matchedIndexes = newSeq[int]()
for index in 0 ..< sharedLimit:
  if sourceValues[index] == queryValues[index]:
    matchedIndexes.add index + 1
for index in 0 ..< matchedIndexes.len:
  if index > 0:
    appendOutput(" ")
  appendOutput($(matchedIndexes[index]))
outputBuffer.add '\n'
stdout.write outputBuffer

```

The shared limit is chosen before the loop. Each printed position is one more than its array index.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Store both lists | O(n + m) writes | two lists |
| Compare positions | O(min(n, m)) reads | matched positions |
| Output | one buffered write | one buffer |

Both lists are bounded by 100 items.

| Measure | Big O |
|---|---|
| Time | O(n + m) |
| Space | O(n + m) for the two lists |

Searching the second list for each value would compare n times m pairs. Position comparison avoids that work.

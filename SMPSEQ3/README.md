# SMPSEQ3 — Fun with Sequences (SPOJ)

<https://www.spoj.com/problems/SMPSEQ3/>

## Problem

You have two sorted lists of whole numbers. Print every number from the first list that is missing from the second list, in order.

The input gives the size of the first list, then its numbers, then the size of the second list, then its numbers. The output is one line of numbers separated by spaces.

| Item | Bound |
|---|---|
| First list size | 2 to 100 |
| Second list size | 2 to 100 |
| Each value | -100 to 100, nondecreasing |
| Judge limit | 1000 ms, 1536 MB |

The sample input:

```
5
-2 -1 0 1 4
6
-3 -2 -1 1 2 3
```

The sample output:

```
0 4
```

## Idea

Think of a ticket checker with a list of invited names. Each name in the first list is checked once against a set of invited names, then printed if absent.

The program marks every value in the second list in a boolean array, then scans the first list. That costs O(n + m) with O(1) work per item.

## Why It Works

1. The array index is the value plus 100, so every legal value maps to a slot.
2. Marking the second list first makes each later check a single array read.
3. Scanning the first list in input order already gives ascending output, since the list is sorted.
4. A space is written only before later numbers, so the line has no trailing space.

| Term | Meaning |
|---|---|
| `sourceValues` | the first sorted list |
| `presentInQuery` | the mark array for the second list |
| `keptValues` | the numbers selected for output |
| `valueOffset` | the shift that maps -100 to index zero |

The mark array turns membership into a constant-time test.

A script-generated trace of the sample:

```
marks from query: -3 -2 -1 1 2 3
-2 is marked, skip
-1 is marked, skip
0 is unmarked, keep
1 is marked, skip
4 is unmarked, keep
output: "0 4"
```

The trace matches the sample output exactly.

## Code

**Constants and scanner.** Read all input and scan integers, including negative ones.

```nim
const firstDigitValue = 48
const valueOffset = 100
const valueSpan = 201
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

**Driver.** Mark the second list, filter the first, and write one line.

```nim
let sourceCount = nextInt(inputData, scanPos)
var sourceValues = newSeq[int](sourceCount)
for index in 0 ..< sourceCount:
  sourceValues[index] = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var presentInQuery = newSeq[bool](valueSpan)
for index in 0 ..< queryCount:
  let queriedValue = nextInt(inputData, scanPos)
  presentInQuery[queriedValue + valueOffset] = true
var keptValues = newSeq[int]()
for index in 0 ..< sourceCount:
  let candidate = sourceValues[index]
  if not presentInQuery[candidate + valueOffset]:
    keptValues.add candidate
for index in 0 ..< keptValues.len:
  if index > 0:
    appendOutput(" ")
  appendOutput($(keptValues[index]))
outputBuffer.add '\n'
stdout.write outputBuffer

```

The mark array has 201 slots for values -100 through 100. The output adds a space only between numbers.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Mark second list | O(m) array writes | 201 booleans |
| Filter first list | O(n) array reads | kept numbers |
| Output | one buffered write | one buffer |

Both lists are bounded by 100 items.

| Measure | Big O |
|---|---|
| Time | O(n + m) |
| Space | O(n) for the kept numbers |

A nested loop would test n times m pairs. The mark array removes that extra factor.

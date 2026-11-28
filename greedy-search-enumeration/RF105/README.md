# RF105 — PIÑATA Grado 10 (SPOJ)
<https://www.spoj.com/problems/RF105/>

## Problem

Two lists name the children who get cake and the children who get ice cream.
Every child gets at least one of those two treats.
Print the children who get only one treat, sorted in ascending lexicographic order.
Each input row starts with the number of names, followed by the names on that row.
The rows are separated by spaces, and the sample contains two rows.

| Item | Bound |
|---|---|
| Rows | 2 |
| Names per row | not stated |
| Repeated names in a row | none |
| Time limit | 1000 ms |
| Memory | 1536 MB |

Only membership in the two rows matters, so one sort per row is enough.

The sample from the statement:

```
4 Sofia Pedro Pablo Yolanda
1 Pedro
```

```
Pablo Sofia Yolanda
```

## Idea

Finding the children with one treat is like crossing off every name that appears twice.
The program reads the whole input once and scans the two rows by index.
It sorts each row of names and merges the two sorted lists.
A name printed during the merge appears in only one row.
Names found in both rows are skipped, and the result is already sorted.

One sort per row and one merge give the answer in order.

## Why It Works

1. A child with cake only belongs to the first sorted list.
2. A child with ice cream only belongs to the second sorted list.
3. Equal names appear at the same point of a sorted merge.
4. Skipping equal pairs removes children who got both treats.
5. A merge walks both lists once, so output stays in sorted order.

The main terms follow.

| Term | Meaning |
|---|---|
| `cakeNames` | children from the first row |
| `creamNames` | children from the second row |
| `textOrder` | lexicographic comparison by byte value |
| `cakeIndex` | position in the cake list |
| `creamIndex` | position in the cream list |

Each list is sorted once, and the merge visits each name once.

A trace from `gen.py --trace` for the sample:

```
cake: Pablo, Pedro, Sofia, Yolanda
cream: Pedro
both: Pedro
only one: Pablo Sofia Yolanda
```

The trace matches the sample output exactly.

## Code

**Bulk input and line scanner.** This block reads stdin once and finds each row.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)
```

The read loop ends at end of input.
Both carriage returns and line feeds end a line.
Empty lines never become rows.

**Comparison and sorting.** This block orders names with a hand quicksort.

```nim
proc textOrder(left: string, right: string): int =
  let sharedLength = if left.len < right.len: left.len else: right.len
  for idx in 0..<sharedLength:
    if int(left[idx]) < int(right[idx]):
      return -1
    if int(left[idx]) > int(right[idx]):
      return 1
  if left.len < right.len:
    return -1
  if left.len > right.len:
    return 1
  return 0

proc partitionText(names: var seq[string], low: int, high: int): int =
  let middle = (low + high) div 2
  let heldMiddle = names[middle]
  names[middle] = names[high]
  names[high] = heldMiddle
  let pivot = names[high]
  var store = low
  for idx in low..<high:
    if textOrder(names[idx], pivot) < 0:
      let heldName = names[store]
      names[store] = names[idx]
      names[idx] = heldName
      inc store
  let heldLast = names[store]
  names[store] = names[high]
  names[high] = heldLast
  return store

proc sortText(names: var seq[string], low: int, high: int) =
  if low >= high:
    return
  let pivotPos = partitionText(names, low, high)
  sortText(names, low, pivotPos - 1)
  sortText(names, pivotPos + 1, high)
```

Shorter prefixes sort before longer names.
The middle element becomes the pivot to avoid sorted-input failure.
Sorting costs n log n comparisons on average.

**Row scanner.** This block skips the count and collects every name on a row.

```nim
proc readNames(data: string, lineStart: int, lineEnd: int,
               names: var seq[string]) =
  var cursor = lineStart
  while cursor < lineEnd and (data[cursor] < '0' or data[cursor] > '9'):
    inc cursor
  while cursor < lineEnd and data[cursor] >= '0' and data[cursor] <= '9':
    inc cursor
  while cursor < lineEnd:
    while cursor < lineEnd and data[cursor] <= ' ':
      inc cursor
    if cursor >= lineEnd:
      break
    let tokenStart = cursor
    while cursor < lineEnd and data[cursor] > ' ':
      inc cursor
    names.add data[tokenStart .. cursor - 1]
```

The leading integer is skipped, then names are read as byte slices.
No split strings or token objects are created.
One pass visits every byte of the row.

**Output buffer.** This block buffers text and flushes in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
The last partial block is written after the loop.
No write happens per name.

**Sorted merge.** This block prints names found in only one row.

```nim
var cakeNames: seq[string] = @[]
var creamNames: seq[string] = @[]
var rowsSeen = 0

while scanPos < inputData.len and rowsSeen < 2:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var hasContent = false
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ':
      hasContent = true
      break
  if not hasContent:
    continue
  if rowsSeen == 0:
    readNames(inputData, lineStart, lineEnd, cakeNames)
  else:
    readNames(inputData, lineStart, lineEnd, creamNames)
  inc rowsSeen

if cakeNames.len > 0:
  sortText(cakeNames, 0, cakeNames.len - 1)
if creamNames.len > 0:
  sortText(creamNames, 0, creamNames.len - 1)

var printedName = false
proc printUniqueName(name: string) =
  if printedName:
    outputBuffer.add ' '
  outputBuffer.add name
  printedName = true

var cakeIndex = 0
var creamIndex = 0
while cakeIndex < cakeNames.len or creamIndex < creamNames.len:
  if creamIndex >= creamNames.len or (cakeIndex < cakeNames.len and
      textOrder(cakeNames[cakeIndex], creamNames[creamIndex]) < 0):
    printUniqueName(cakeNames[cakeIndex])
    inc cakeIndex
    while cakeIndex < cakeNames.len and
        textOrder(cakeNames[cakeIndex - 1], cakeNames[cakeIndex]) == 0:
      inc cakeIndex
  elif cakeIndex >= cakeNames.len or
      textOrder(cakeNames[cakeIndex], creamNames[creamIndex]) > 0:
    printUniqueName(creamNames[creamIndex])
    inc creamIndex
    while creamIndex < creamNames.len and
        textOrder(creamNames[creamIndex - 1], creamNames[creamIndex]) == 0:
      inc creamIndex
  else:
    inc cakeIndex
    while cakeIndex < cakeNames.len and
        textOrder(cakeNames[cakeIndex - 1], cakeNames[cakeIndex]) == 0:
      inc cakeIndex
    inc creamIndex
    while creamIndex < creamNames.len and
        textOrder(creamNames[creamIndex - 1], creamNames[creamIndex]) == 0:
      inc creamIndex
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The `*` terminator is not used here, since the two rows are read by count.
Each equal pair is skipped, leaving only names from one row.
A trailing newline ends the single answer line.

## Complexity

Cost follows the two name lists and their total length.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sorting | n log n per row | two name lists |
| Merge and output | one visit per name | block buffer |

Sorting each row once keeps the merge linear.

| Measure | Big O |
|---|---|
| Time | O(I + k log k) for row size k |
| Space | O(I + k + B) |

Here I is input bytes, k is the larger row size, and B is block size.

Checking every pair of names would cost quadratic time.
A sorted merge finds shared names in one linear pass.

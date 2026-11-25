# FARMER — Farmer (SPOJ)

<https://www.spoj.com/problems/FARMER/>

## Problem

Choose exactly Q cypress trees from circular fields and straight strips to collect the most olive trees. An olive tree is collected only when both cypress trees beside it are chosen.

Input starts with t, the number of test cases. Each case gives Q, M, K, then M field sizes and K strip sizes. Output one integer per case: the largest olive count.

The bounds from the statement:

| Item | Bound |
|---|---|
| test cases t | at most 20 |
| trees to pick Q | 0 to 150000 |
| fields M | 0 to 2000 |
| strips K | 0 to 2000 |
| field size Ni | 3 to 150 |
| strip size Ri | 2 to 150 |
| total trees | at least Q |
| judge limit | 50 s, 1536 MB |

The 150000 tree cap sets the bitset size, and the 150 tree cap bounds each group.

The sample case:

```
1
17 3 3 
13 4 8 
4 8 6
```

```
17
```

Taking the fields of 13 and 4 uses all 17 trees and yields 17 olives.

## Idea

Pay for a group only when it is not a whole field. Think of crossing names off a list: a completed field crosses itself off for free, while every strip and partial field costs one olive.

The program uses a subset-sum bitset over field sizes, then a greedy pass over the largest strips. One field costs a shift over about 2400 machine words. One strip costs one comparison after sorting. A DP over every tree count costs (M + K) times Q steps and is slower.

Complete fields are free, so find the largest free total first.

## Why It Works

1. A complete field of Ni trees yields Ni olives, because every neighbouring pair is both chosen.
2. Any other group yields one less olive than trees, because its first tree lacks a chosen predecessor.
3. Choosing consecutive trees keeps one group per field or strip, which maximizes the olives from it.
4. The olive count equals Q minus the number of paid groups, since a complete field cancels its own cost.
5. Let S be the largest field subset sum not above Q. Every excluded field exceeds Q - S, so one partial field covers the remainder.
6. When all fields fit, strips cover the remainder, and the largest strips first minimize their count.

The terms that decide the answer:

| Term | Meaning |
|---|---|
| S | largest field subset sum not above Q |
| Q - S | trees still needed after complete fields |
| `fieldTotal` | sum of every field size |
| `usedStrips` | fewest largest strips whose sizes reach Q - S |
| `answer` | Q minus the number of paid groups |

The answer is Q when S equals Q, otherwise Q minus one or the strip count.

A script trace for Q = 32 with the sample sizes:

```
Q = 32
fields = [13, 4, 8]
reachable field sums up to Q = [0, 4, 8, 12, 13, 17, 21, 25]
best field sum = 25
field total = 25, so strips must cover 7
strips sorted high to low = [8, 6, 4]
first 1 strip(s) cover 8, which reaches 7
olives = 32 - 1 = 31
```

The trace gives 31 olives, matching the result for that case.

## Code

**Constants and scanner.** These values and one hand scanner set up the fast path.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const bitsPerWord = 64

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scanner skips separators and builds values without substrings. Digit bytes use `firstDigitValue`, so no parse call runs. The scan position survives across calls as a var parameter.

**Field subset sum.** One bitset holds every reachable field total up to the capacity.

```nim
proc maxFieldSum(capacity: int, fieldSizes: seq[int]): int =
  let wordCount = capacity div bitsPerWord + 1
  var reachable = newSeq[uint64](wordCount)
  reachable[0] = 1'u64
  for fieldSize in fieldSizes:
    if fieldSize > capacity: continue
    let wordShift = fieldSize div bitsPerWord
    let bitShift = fieldSize mod bitsPerWord
    for wordIndex in countdown(wordCount - 1, wordShift):
      var shifted = reachable[wordIndex - wordShift] shl bitShift
      if bitShift > 0 and wordIndex - wordShift - 1 >= 0:
        shifted = shifted or (reachable[wordIndex - wordShift - 1] shr (bitsPerWord - bitShift))
      reachable[wordIndex] = reachable[wordIndex] or shifted
  for total in countdown(capacity, 0):
    if (reachable[total div bitsPerWord] and (1'u64 shl (total mod bitsPerWord))) != 0'u64:
      return total
  return 0
```

One field costs one pass over about 2400 words. Descending word order keeps the source words unchanged during each shift. The final scan returns the largest reachable sum within the capacity.

**Strip ordering.** A small insertion sort places the largest strips first.

```nim
proc descendingSort(values: var seq[int]) =
  if values.len > 1:
    for rightIndex in 1 ..< values.len:
      let keyValue = values[rightIndex]
      var leftIndex = rightIndex - 1
      while leftIndex >= 0 and values[leftIndex] < keyValue:
        values[leftIndex + 1] = values[leftIndex]
        leftIndex -= 1
      values[leftIndex + 1] = keyValue
```

The comparison is explicit and needs no generic comparator. Larger strips first reduce the number of paid groups. The loop stops early for an already sorted prefix.

**Driver and buffered output.** One read, three answer branches, and block writes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 0 ..< caseCount:
  let treeTarget = nextInt(inputData, scanPos)
  let fieldCount = nextInt(inputData, scanPos)
  let stripCount = nextInt(inputData, scanPos)
  var fieldSizes = newSeq[int](fieldCount)
  var fieldTotal = 0
  for fieldIndex in 0 ..< fieldCount:
    fieldSizes[fieldIndex] = nextInt(inputData, scanPos)
    fieldTotal += fieldSizes[fieldIndex]
  var stripSizes = newSeq[int](stripCount)
  for stripIndex in 0 ..< stripCount:
    stripSizes[stripIndex] = nextInt(inputData, scanPos)
  let bestFieldSum = maxFieldSum(treeTarget, fieldSizes)
  var answer = 0
  if bestFieldSum == treeTarget:
    answer = treeTarget
  elif bestFieldSum < fieldTotal:
    answer = treeTarget - 1
  else:
    descendingSort(stripSizes)
    var covered = 0
    var usedStrips = 0
    for stripSize in stripSizes:
      covered += stripSize
      usedStrips += 1
      if covered >= treeTarget - bestFieldSum: break
    answer = treeTarget - usedStrips
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

All input lines join one buffer before scanning starts. The three branches cover an exact fit, one partial field, and strip coverage. Output is written once per 262144 bytes and once at the end.

## Complexity

Costs by phase for one test case:

| Phase | Time | Space |
|---|---|---|
| input read | one pass over input bytes | input bytes |
| field subset sum | O(M * Q/64) word shifts | Q/8 bytes |
| strip sorting | O(K^2) worst case | K integers |
| output | one write per 262144 bytes | block buffer |

The field bitset and the strip sort dominate the run.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| time | O(M * Q/64 + K^2) |
| space | O(Q) bits plus O(M + K) integers |

A direct tree-by-tree DP costs O((M + K)Q) steps per case, so the bitset divides the field work by 64.

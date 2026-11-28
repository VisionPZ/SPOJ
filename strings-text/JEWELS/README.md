# JEWELS — Jewelry and Fashion (SPOJ)

<https://www.spoj.com/problems/JEWELS/>

## Problem

A jeweler cuts an amber string and discards stones until both halves show the same pattern. A half can also be turned by 180 degrees before it is compared.

Read `t` strings of letters `a` through `z`. Cut a string into a left part and a right part. Remove stones so both parts match as written or after the right part reverses.

Print twice the kept length and the smallest cut position that achieves it.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Test cases `t` | at most 500 |
| Characters per case | at most 8000 |
| Total input size | at most 100 kB |
| Time limit | 25000 ms |
| Memory limit | 1536 MB |

The total input size sets the scale, so each character must cost a small fixed amount.

The sample case:

```
3
abcacdd
acbddabedff
abcbca
```

```
4 3
6 4
4 2
```

## Idea

Treat each half as a line of stones; keeping matching stones means choosing a common subsequence (letters kept in order, with gaps allowed).

The program runs two sweeps that price every cut at once. The first compares the left prefix with the right suffix in the same order. The second compares that prefix with the reversed suffix, which models the turn.

Each sweep keeps one row of state and visits every character pair once.

Each sweep costs O(n^2) time and O(n) memory. Recomputing a fresh longest common subsequence for every cut costs O(n^3). Two sweeps answer all cuts at the price of two full tables.

## Why It Works

Five facts prove the sweeps correct.

1. For a cut at `c`, the kept stones form a common subsequence of the left part and the right part. A rotation reverses the right part before comparison.
2. `curHorizontal[j]` holds the lowest left row where the horizontal gain reaches column `j`. `curVertical[j]` holds the highest left row where the vertical gain reaches `j`.
3. On a letter match both values swap their sources. On a mismatch each value takes the larger or smaller source, so the two boundaries never cross.
4. After row `i`, a column `j` past `i` whose horizontal value is at most `i` adds one to the straight LCS. Column `i` always matches itself, so the count skips it.
5. The rotated sweep links a left stone to a right stone with a decreasing right index. `revMatch[p]` stores the best chain ending at left stone `p`, and a forward pass makes every prefix ready.

The arrays and their roles:

| Term | Meaning |
| --- | --- |
| `straightMatch` | straight LCS length for each cut |
| `revMatch` | rotated LCS length for each cut |
| `prevHorizontal` | previous row of horizontal boundaries |
| `curVertical` | current row of vertical boundaries |
| `pairLength` | twice the better of the two lengths |

Each array has one entry per cut, so the final scan is linear.

A script prices every cut of `abcbca` and prints these values:

```
cut 1: straight=1 rotated=1 pairLength=2
cut 2: straight=1 rotated=2 pairLength=4
cut 3: straight=2 rotated=2 pairLength=4
cut 4: straight=1 rotated=2 pairLength=4
cut 5: straight=1 rotated=1 pairLength=2
answer: (4, 2)
```

Cuts 2, 3, and 4 tie at length 4. A strict comparison keeps cut 2, which matches the sample output.

## Code

**Setup and input.** One buffer holds the stream, and bounds checks are off in the hot loops.

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The whole input is read before parsing starts. Disabling checks speeds up the two sweeps. Reading line by line happens once, not once per answer.

**Scanner and output.** A hand scanner reads the case count, and one buffer collects answers.

```nim
proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and builds each integer by hand. The output buffer flushes after `flushBlockBytes` bytes. One write then covers many answers.

**String extraction.** The scanner finds each lowercase run in place.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  while scanPos < inputData.len and (inputData[scanPos] < 'a' or inputData[scanPos] > 'z'):
    scanPos += 1
  let strStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= 'a' and inputData[scanPos] <= 'z':
    scanPos += 1
  let strLen = scanPos - strStart
```

The inner loops skip leading whitespace and keep each color string in place. No substring is copied. The cost is one pass over the input characters.

**Straight sweep.** Boundary rows give the same-order LCS for every cut.

```nim
  var straightMatch = newSeq[uint16](strLen + 1)
  if strLen >= 2:
    var prevHorizontal = newSeq[uint16](strLen + 1)
    var curHorizontal = newSeq[uint16](strLen + 1)
    var curVertical = newSeq[uint16](strLen + 1)
    for j in 0..strLen:
      prevHorizontal[j] = uint16(j)
    for i in 1..strLen:
      curVertical[0] = 0
      let leftLetter = inputData[strStart + i - 1]
      for j in 1..strLen:
        if leftLetter == inputData[strStart + j - 1]:
          curHorizontal[j] = curVertical[j - 1]
          curVertical[j] = prevHorizontal[j]
        else:
          let across = curVertical[j - 1]
          let above = prevHorizontal[j]
          curHorizontal[j] = if across > above: across else: above
          curVertical[j] = if across < above: across else: above
      if i < strLen:
        var reached = 0
        for j in (i + 1)..strLen:
          if curHorizontal[j] <= uint16(i):
            reached += 1
        straightMatch[i] = uint16(reached)
      swap prevHorizontal, curHorizontal
```

The row loop runs once per left prefix length and the column loop once per right position. Counting skips columns up to `i`, so column `i` never adds itself. Swapping rows avoids a copy and keeps the sweep at O(n^2).

**Rotated sweep.** Chains of matching pairs give the turned LCS for every cut.

```nim
  var revMatch = newSeq[uint16](strLen + 1)
  if strLen >= 2:
    for j in countdown(strLen - 1, 1):
      for p in countdown(j - 1, 0):
        if inputData[strStart + p] == inputData[strStart + j]:
          let candidate = (if p > 0: int(revMatch[p - 1]) else: 0) + 1
          if candidate > int(revMatch[p]):
            revMatch[p] = uint16(candidate)
      for p in 1..<strLen:
        if revMatch[p - 1] > revMatch[p]:
          revMatch[p] = revMatch[p - 1]
      revMatch[j] = revMatch[j - 1]
```

The outer loop adds one right stone at a time, from the end inward. The inner loop extends chains from the left. The forward pass makes the array non-decreasing, so every shorter prefix has a ready value.

**Answer.** The final scan keeps the longest pair and the leftmost cut.

```nim
  var bestLength = 0
  var bestCut = 1
  for cut in 1..<strLen:
    let oneSide = int(straightMatch[cut])
    let turnedSide = int(revMatch[cut])
    let pairLength = 2 * (if oneSide > turnedSide: oneSide else: turnedSide)
    if pairLength > bestLength:
      bestLength = pairLength
      bestCut = cut
  appendOutput($(bestLength) & " " & $(bestCut) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan visits cuts from left to right. A strict comparison keeps the leftmost cut on ties. The final write flushes the partial output block.

## Complexity

Both sweeps scale with the square of one string length.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(n) | one input buffer |
| Straight sweep | O(n^2) | three rows of n + 1 values |
| Rotated sweep | O(n^2) | one row of n + 1 values |
| Cut scan and output | O(n) | one output block |

The `uint16` rows stay small because a cut never exceeds 8000.

| Measure | Big O |
| --- | --- |
| Time | O(n^2) per case |
| Space | O(n) beyond the I/O buffers |

A fresh LCS computation for each of the `n` cuts would cost O(n^3) time per case.

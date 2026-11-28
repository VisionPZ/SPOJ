# MATHII — Yet Another Mathematical Problem (SPOJ)

<https://www.spoj.com/problems/MATHII/>

## Problem

Count ordered triples of positive integers whose product does not exceed N. Print the count for each input line with a case number.

Input contains one integer N per line until end of file. Output one line per case in the form `Case X: Y`.

| item | bound |
|---|---|
| N | 1 to 100000000000 |
| answer | fits in a signed 64-bit integer |
| judge limit | 3000 ms, 1536 MB |

The size of N rules out enumerating triples and drives a divisor-based split.

Sample input:

```
1
3
6
10
15
21
28
```

Sample output:

```
Case 1: 1
Case 2: 7
Case 3: 25
Case 4: 53
Case 5: 95
Case 6: 161
Case 7: 246
```

## Idea

Every triple has a smallest entry, and that entry is at most the cube root of N, like finding the shortest side of a box. Split triples by which position holds that smallest entry and count the other two entries with divisor sums. Each level needs one hyperbola count plus a short prefix sum, so the work grows as a fractional power of N. Enumerating triples would grow linearly in N and cannot finish. Takeaway: partition by the smallest factor and reuse pair counts.

## Why It Works

1. In any triple with product at most N, the minimum is at most the cube root of N.
2. Partition triples by the first position that attains the minimum, with ties assigned to the earliest position.
3. For a fixed minimum value d, the remaining pair has product at most N/d.
4. The count of pairs with product at most v is `pairCount`, found by the divisor hyperbola.
5. Subtracting pairs with a smaller coordinate removes words that belong to another partition class.

| term | meaning |
|---|---|
| `pairCount` | number of ordered pairs with product at most a limit |
| `tripleCount` | number of ordered triples with product at most a limit |
| `splitIndex` | integer cube root of the limit |
| `integerSquareRoot` | exact floor square root used by the hyperbola |

A script trace for small limits:

```
N  : triples
1  : 1
3  : 7
6  : 25
10 : 53
15 : 95
21 : 161
28 : 246
```

Each value counts ordered factorizations of every number up to N.

Square and cube roots are adjusted with integer products, so float rounding cannot change a boundary.

## Code

**Input and helpers.** The reader stores every limit and supplies exact integer roots.

```nim
import math

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc integerSquareRoot(value: int64): int64 =
  var guess = int64(sqrt(float(value)))
  while (guess + 1) * (guess + 1) <= value:
    guess += 1
  while guess * guess > value:
    guess -= 1
  return guess

proc integerCubeRoot(value: int64): int64 =
  var guess = int64(pow(float(value), 1.0 / 3.0))
  while (guess + 1) * (guess + 1) * (guess + 1) <= value:
    guess += 1
  while guess * guess * guess > value:
    guess -= 1
  return guess
```

The scanner parses all limits before any table work.
Both roots start from a float estimate and end with exact integer checks.
All products stay inside int64 for the stated range.

**Pair count.** The hyperbola counts pairs with product at most a limit.

```nim
proc pairCount(limitValue: int64): int64 =
  let rootValue = integerSquareRoot(limitValue)
  var totalPairs: int64 = 0
  var divisorValue: int64 = 1
  while divisorValue <= rootValue:
    totalPairs = totalPairs + limitValue div divisorValue
    divisorValue += 1
  return 2 * totalPairs - rootValue * rootValue
```

The loop visits divisors up to the square root.
The square term removes the double-counted center.
One call costs a square-root number of divisions.

**Triple count.** Three partition classes sum into the answer.

```nim
proc tripleCount(limitValue: int64): int64 =
  let splitIndex = integerCubeRoot(limitValue)
  var answer: int64 = 0
  var levelIndex: int64 = 1
  while levelIndex <= splitIndex:
    let remainingValue = limitValue div levelIndex
    let allPairs = pairCount(remainingValue)
    var prefixBefore: int64 = 0
    var prefixThrough: int64 = 0
    var divisorValue: int64 = 1
    while divisorValue <= levelIndex:
      prefixThrough = prefixThrough + remainingValue div divisorValue
      if divisorValue < levelIndex:
        prefixBefore = prefixThrough
      divisorValue += 1
    let beforeCount = allPairs - 2 * prefixBefore + (levelIndex - 1) * (levelIndex - 1)
    let middleCount = allPairs - prefixThrough - prefixBefore + levelIndex * (levelIndex - 1)
    let afterCount = allPairs - 2 * prefixThrough + levelIndex * levelIndex
    answer = answer + beforeCount + middleCount + afterCount
    levelIndex += 1
  return answer
```

The minimum ranges only up to the cube root.
Two prefix sums handle the subtractions for all three classes.
Every level reuses one pair count.

**Output.** One labeled answer is written per input line.

```nim
var caseIndex = 0
while scanPos < inputData.len:
  let limitValue = nextInt(inputData, scanPos)
  if limitValue == 0 and scanPos >= inputData.len:
    break
  if limitValue < 1:
    continue
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & $tripleCount(int64(limitValue)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Trailing whitespace cannot add a case.
The answer is computed once per case.
The buffer flushes after the last line.

## Complexity

The cube-root split controls the total work.

| phase | time | space |
|---|---|---|
| input read | one pass over limit lines | one input string |
| pair counts | square-root divisions per level | a few integers |
| prefix sums | up to cube-root terms per level | a few integers |
| output | one line per case | block buffer |

Each level pays about the square root of N divided by that level.

| measure | Big O |
|---|---|
| time | O(N^(2/3)) per case |
| space | O(1) |

A triple loop would take O(N) or worse per case. Takeaway: the three-class split keeps large limits affordable.

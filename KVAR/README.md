# KVAR — Kevin likes array (SPOJ)

<https://www.spoj.com/problems/KVAR/>

## Problem

An array is beautiful when its total inversions equal its local inversions. A total inversion is a pair (i, j) with i < j and A[i] > A[j]. A local inversion is an adjacent drop A[i] > A[i+1]. Print `YES` or `NO` per test.

The first line holds T with 1 ≤ T ≤ 10. Each test gives N (1 ≤ N ≤ 100) and then N values with 1 ≤ A[i] ≤ 100.

| item | bound |
|---|---|
| tests T | 1 ≤ T ≤ 10 |
| array length N | 1 ≤ N ≤ 100 |
| values A[i] | 1 ≤ A[i] ≤ 100 |
| judge limit | 1000 ms, 1536 MB |

Every local inversion is a total inversion, so beauty fails only when a far pair inverts.

Sample input:

```
4
1
1
2
2 1
3
3 2 1
4
1 3 2 4
```

Sample output:

```
YES
YES
NO
YES
```

## Idea

A staircase with a hidden step behind a corner is the only way to trip. A local inversion is a step between neighbours. Beauty asks that no inversion hides two places apart.

The program checks, for each position i, whether A[i] beats the smallest value at or after i+2. If it does, a far inversion exists and the array is not beautiful. A suffix-minimum table makes each check one lookup.

Takeaway: equal counts mean no far pair, so only far pairs need checking.

## Why It Works

1. Every adjacent drop is also an inversion, so local count ≤ total count always.
2. The counts are equal exactly when no non-adjacent pair inverts.
3. A non-adjacent inversion (i, j) has j ≥ i+2, so A[i] > A[j] ≥ suffix minimum from i+2.
4. Conversely, if A[i] exceeds the suffix minimum from i+2, some j ≥ i+2 inverts with i.
5. Scanning all i therefore decides beauty in one pass.

For the sample, [3, 2, 1] has 3 total inversions but only 2 local ones, so the answer is `NO`. The array [1, 3, 2, 4] has one of each, so it is `YES`.

Arrays of length 1 or 2 have no far pairs, so they are always beautiful.

## Code

**Input and scanning.** The hand reader loads the file and parses integers.

```nim
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
```

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.

**Buffered output.** One string collects the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Suffix minimum.** The table stores the smallest value from each index onward.

```nim
  var suffixMinimum = newSeq[int](elementCount + 1)
  suffixMinimum[elementCount] = 2147483647
  var reverseIndex = elementCount - 1
  while reverseIndex >= 0:
    if values[reverseIndex] < suffixMinimum[reverseIndex + 1]:
      suffixMinimum[reverseIndex] = values[reverseIndex]
    else:
      suffixMinimum[reverseIndex] = suffixMinimum[reverseIndex + 1]
    reverseIndex -= 1
```

The sentinel at the end keeps the walk simple.
Each cell takes the min of its value and the cell after it.

**Far-pair check.** One lookup per position decides the test.

```nim
  var beautiful = true
  for leftIndex in 0 .. elementCount - 3:
    if values[leftIndex] > suffixMinimum[leftIndex + 2]:
      beautiful = false
  if beautiful:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
```

The loop stops two places before the end because far pairs need room.
The first hit sets the answer, so the scan is short-circuit in spirit.
Every test contributes exactly one line.

## Complexity

Each test builds one suffix table and scans once.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| suffix table | one pass per test | N cells |
| check | one lookup per position | none |
| output | one line per test | one block buffer |

| measure | Big O |
|---|---|
| time | O(total N) |
| space | O(N) |

Counting all inversions with double loops costs O(N^2) per test.

Takeaway: compare against the suffix minimum to skip the double loop.

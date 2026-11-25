# ADDEVENA — Add To Even (Part A) (SPOJ)
<https://www.spoj.com/problems/ADDEVENA/>

## Problem

Count unordered index pairs whose values add to an even number. Only parity matters, because even plus even and odd plus odd give even sums.

The first line gives n. The second line gives n positive integers. Print one integer, the number of unique pairs.

| Constraint | Value |
| --- | --- |
| Integers n | 2 to 100000 |
| Each value | positive integer |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

One linear pass handles the largest input.

The sample input and its expected output follow byte for byte.

```
3
1 1 1
```

```
3
```

Three odd values form three pairs.

## Idea

Splitting the list into even and odd values is like separating socks into two drawers before counting pairs. Each new value pairs only with earlier values from its own drawer.

The program keeps two running tallies, `evenSeen` and `oddSeen`. For each value it adds the matching tally to `pairTotal`, then increments that tally. This is a single pass over the list.

Testing every index pair would take quadratic time. The running tally takes constant time per value and ends with the same count.

## Why It Works

1. A sum is even exactly when both summands have the same parity.
2. The value at position r pairs with earlier values only, so each pair is counted once.
3. Before position r, the number of same-parity partners is `evenSeen` or `oddSeen`.
4. Adding that count to `pairTotal` accounts for every pair ending at r.
5. After the last value, `pairTotal` holds the count of all unique pairs.

| Term | Meaning |
| --- | --- |
| `evenSeen` | even values read so far |
| `oddSeen` | odd values read so far |
| `pairTotal` | pairs counted so far |
| `numberCount` | size of the input list |

These four names cover the whole state of the scan.

A script check on the second sample list [2, 12, 3, 14, 29, 4] finds four even values and two odd values. Four evens give C(4, 2) = 6 pairs, and two odds give C(2, 2) = 1 pair.

| Step | Value | Tally before | Pairs added |
| --- | --- | --- | --- |
| 1 | 2 | even 0 | 0 |
| 2 | 12 | even 1 | 1 |
| 3 | 3 | odd 0 | 0 |
| 4 | 14 | even 2 | 2 |
| 5 | 29 | odd 1 | 1 |
| 6 | 4 | even 3 | 3 |

The six added counts sum to 7, matching the sample output.

## Code

**Input reader and output buffer.** The hand scanner loads all values, and `appendOutput` flushes large blocks of text.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Token parsing skips spaces and line breaks.
One final write empties the buffer.

**Running parity tally.** Each value contributes the size of its matching tally before the tally grows.

```nim
let numberCount = nextInt(inputData, scanPos)
var evenSeen: int64 = 0
var oddSeen: int64 = 0
var pairTotal: int64 = 0
for numberIndex in 0 .. numberCount - 1:
  let currentNumber = nextInt(inputData, scanPos)
  if currentNumber mod 2 == 0:
    pairTotal += evenSeen
    evenSeen += 1
  else:
    pairTotal += oddSeen
    oddSeen += 1
appendOutput($pairTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The tallies and total use int64 for large pair counts.
The answer is written once after the loop.

## Complexity

The scan touches each value once.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over the stream | one input string |
| parity tally | constant work per value | three counters |
| output | one line | block buffer |

No list of values is stored.

| Measure | Big O |
| --- | --- |
| time | O(n) |
| space | O(1) besides input |

A brute-force check of all index pairs would take O(n^2) time.

The running tally keeps the largest allowed list well inside the limit.

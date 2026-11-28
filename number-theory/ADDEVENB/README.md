# ADDEVENB — Add To Even (Part B) (SPOJ)
<https://www.spoj.com/problems/ADDEVENB/>

## Problem

Count index pairs with an even sum whose positions differ by at most k. Only parity matters, so a pair qualifies when both values are even or both are odd.

The first line gives n and k. The second line gives n positive integers. Print one integer, the pair count.

| Constraint | Value |
| --- | --- |
| List size n | up to 100000 |
| Distance k | at least 1 and less than n |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

A sliding window handles the largest list in one pass.

The sample input and its expected output follow byte for byte.

```
3 1
1 1 1
```

```
2
```

Only adjacent pairs qualify here.

## Idea

Keeping the last k values in view is like sliding a short frame along a row of socks. Each new value pairs with earlier values of the same kind that still sit inside the frame.

The program stores the list, then keeps `evenWindow` and `oddWindow` for the current frame. Before adding value r, the frame holds positions r-k through r-1. After adding value r, the value at position r-k leaves the frame.

Checking every pair would cost quadratic time. The window updates once per position, so the work stays linear.

## Why It Works

1. An even sum needs two values with the same parity.
2. At position r, the legal partners are the earlier positions from r-k to r-1.
3. The matching window count equals the number of such partners.
4. After value r enters, value r-k is too far away for all later positions.
5. Removing it keeps the window exact, so every pair is counted once.

| Term | Meaning |
| --- | --- |
| `numberList` | the input values in order |
| `maxDistance` | largest allowed index gap k |
| `evenWindow` | even values currently in frame |
| `oddWindow` | odd values currently in frame |
| `pairTotal` | pairs counted so far |

These names describe the entire sliding state.

A script check on the second sample list [2, 12, 3, 14, 29, 4] with k = 4 gives 6 pairs.

| Position | Value | Same-parity partners | Pairs added | Running total |
| --- | --- | --- | --- | --- |
| 0 | 2 | 0 | 0 | 0 |
| 1 | 12 | 1 | 1 | 1 |
| 2 | 3 | 0 | 0 | 1 |
| 3 | 14 | 2 | 2 | 3 |
| 4 | 29 | 1 | 1 | 4 |
| 5 | 4 | 2 | 2 | 6 |

The final total matches the sample output.

## Code

**Input reader and output buffer.** The hand scanner reads the header and the full list.

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
The buffer flushes large blocks and once at the end.

**Sliding parity window.** Each position adds its partners, then drops the value that fell out of range.

```nim
let numberCount = nextInt(inputData, scanPos)
let maxDistance = nextInt(inputData, scanPos)
var numberList = newSeq[int](numberCount)
for numberIndex in 0 .. numberCount - 1:
  numberList[numberIndex] = nextInt(inputData, scanPos)
var evenWindow: int64 = 0
var oddWindow: int64 = 0
var pairTotal: int64 = 0
for rightIndex in 0 .. numberCount - 1:
  let currentNumber = numberList[rightIndex]
  if currentNumber mod 2 == 0:
    pairTotal += evenWindow
    evenWindow += 1
  else:
    pairTotal += oddWindow
    oddWindow += 1
  if rightIndex >= maxDistance:
    let leavingNumber = numberList[rightIndex - maxDistance]
    if leavingNumber mod 2 == 0:
      evenWindow -= 1
    else:
      oddWindow -= 1
appendOutput($pairTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The window holds exactly k earlier values after each step.
Counters use int64 because the pair count can be large.

## Complexity

The scan adds and removes each value once.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over the stream | one input string |
| sliding window | constant work per position | list of n values |
| output | one line | block buffer |

Only the list is stored besides the two counters.

| Measure | Big O |
| --- | --- |
| time | O(n) |
| space | O(n) |

A brute-force check of all pairs within k would take O(n*k) time.

The window keeps the largest allowed list inside the limit.

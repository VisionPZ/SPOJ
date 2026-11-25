# AWESOMECHILDHOOD — Awesome Childhood (SPOJ)
<https://www.spoj.com/problems/AWESOMECHILDHOOD/>

## Problem

Each case gives an even number G. A story hides a number N, doubles it, adds G, halves the total, then takes back N. The value left at the end is always G/2. Print one labelled line per case.

The first line holds the case count. Each following line holds one even integer G. For case k, print `Case k: R`, where R is the remaining number.

The bounds from the statement:

| Item | Bound |
|---|---|
| Cases T | 0 < T < 10000 |
| Given value G | 1 < G ≤ 2^32, even |
| Judge time | 500 ms |
| Judge memory | 1536 MB |

The case count drives the loop; each case costs one division.

The sample case:

```
2
10236
172
```

```
Case 1: 5118
Case 2: 86
```

## Idea

The trick is cancellation. Think of borrowing a book, then returning it on the same page; the page number never changes. Algebra removes the hidden N, so only half of G remains. One integer division per case gives the answer.

## Why It Works

1. The story forms 2N + G, then halves it to get N + G/2.
2. Removing the borrowed N leaves exactly G/2, whatever N was.
3. G is even, so integer division by two is exact.
4. Each case needs one division and one formatted line.

The main terms:

| Term | Meaning |
|---|---|
| `G` | the even number supplied for one case |
| `N` | the hidden borrowed number that cancels |
| `caseCount` | number of cases from the first line |
| `givenValue` | parsed value of G |

These terms reduce the whole story to one quotient.

A script trace gives 10236/2 = 5118 for case 1. It gives 172/2 = 86 for case 2. Both values match the sample output.

## Code

**Input buffer.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const caseLabel = "Case "

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```
One readLine loop stores all bytes. The append adds the lost newline after each line.

**Hand scanner.**
```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```
The scanner skips separators by index. It builds the value in int64, so 2^32 fits.

**Answer loop and flush.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 1..caseCount:
  let givenValue = nextInt(inputData, scanPos)
  appendOutput(caseLabel)
  appendOutput($(caseIndex))
  appendOutput(": ")
  appendOutput($(givenValue div 2))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
The loop writes one label and one quotient per case. A final flush emits the last partial block.

## Complexity

The cost is one read pass and one write pass.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Case work | one division per case | constant |
| Output | one write per 128 KiB block | block buffer |

The phase costs are all linear in the input size.

Big O uses T as the case count.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(T) for stored input |

Simulating the story repeats several operations per case. Direct halving uses one step and stays fast at 9999 cases.

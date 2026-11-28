# SUMUNZ — Sum Until 0 (SPOJ)

<https://www.spoj.com/problems/SUMUNZ/>

## Problem

The input is one bracketed list of signed integers, such as [3,6,7,2,0,4]. Add the elements that appear before the first 0 and print the total. An empty list produces 0, and a missing 0 means every element counts.

| item | bound |
|---|---|
| input form | one bracketed list of integers |
| element values | fit in 64-bit signed integers |
| judge limit | 1000 ms, 1536 MB |

The first 0 stops the sum even when more numbers follow it.

Sample input:

```
[3,6,7,2,0,4,0,45,32,0]
```

Sample output:

```
18
```

## Idea

Think of the input as a number tape: you add each value to a tally and cut the tape the moment a 0 appears. The hand scanner skips brackets, commas, and spaces, then reads one signed integer at a time. Each byte gets a constant amount of work, and the loop stops at the first 0. Building the whole list first with an evaluator would allocate one object per element before any adding starts. Reading and adding in one pass avoids that allocation entirely.

## Why It Works

1. Brackets, commas, and spaces are neither digits nor minus signs, so the scanner skips them.
2. A minus sign flips the sign of the digit run that follows it.
3. Adding as we scan makes the running total equal the sum before the first 0.
4. The zero test stops the loop at the first 0, leaving later elements untouched.
5. An empty list yields no digit runs, so the total stays at its initial value.

| term | meaning |
|---|---|
| `nextSignedInt` | reads one integer, including an optional minus sign |
| `elementFound` | true when a digit run exists at the current position |
| `elementValue` | the integer scanned in this call |
| `total` | sum of elements before the first 0 |
| `flushBlockBytes` | buffer size that triggers a write |

The found flag also ends the loop when the buffer runs out.

A script-traced example from the generator:

```
tokens 3, 6, 7, 2, 0, 4, ...
running 3 -> 9 -> 16 -> 18 -> stop at 0
result 18
```

The trace matches the sample answer.

## Code

**Signed scanner.** The reader loads stdin once and parses one integer per call.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int, found: var bool): int =
  found = false
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
    found = true
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The skip loop ignores punctuation and whitespace.
The sign branch keeps negative elements correct.
Scanning costs one pass over the consumed characters.

**Sum loop.** The loop adds each value and stops at the first 0.

```nim
var total: int64 = 0
while true:
  var elementFound = false
  let elementValue = nextSignedInt(inputData, scanPos, elementFound)
  if not elementFound:
    break
  if elementValue == 0:
    break
  total = total + int64(elementValue)

appendOutput($total)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The accumulator holds sums that exceed a 32-bit integer.
The zero test cuts the tape at the first 0.
One short answer goes out after the loop ends.

## Complexity

The input size sets the cost because each byte is visited once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input string |
| scan and sum | constant work per byte | running total |
| output | one short line | block buffer |

The phase table shows that the scan is the only growing cost.

| measure | Big O |
|---|---|
| time | O(N) for N input bytes |
| space | O(N) for the input buffer |

Allocating every element first also costs O(N) time but needs O(N) extra storage; scanning in place uses no list.

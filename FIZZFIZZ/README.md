# FIZZFIZZ — Fizz-fizz (SPOJ)

<https://www.spoj.com/problems/FIZZFIZZ/>

## Problem

For every position from 1 to n, print the position itself when three does not divide it. Otherwise print one fizz word per clean division by three, joined by hyphens. The output has exactly n lines in increasing position order.

| item | bound |
|---|---|
| number of students n | 1 to 10000 |
| output lines | n |
| judge limit | 1000 ms, 1536 MB |

A position divisible by nine says fizz twice.
A position not divisible by three says its own number.

Sample input:

```
9
```

Sample output:

```
1
2
fizz
4
5
fizz
7
8
fizz-fizz
```

## Idea

Peeling layers from an onion resembles counting fizz words: each clean division by three removes one layer. The algorithm divides the position by three until a remainder appears. That count gives the number of fizz words, and zero count means print the number. Each item costs a few divisions, about log base three of n. Testing every power of three for every position repeats the same work. One pass over the positions finishes the task.

## Why It Works

1. A clean division by three contributes one fizz word.
2. Repeating the division counts every layer of three in the position.
3. The loop stops as soon as the remainder is nonzero.
4. A zero fizz count means the position is not divisible by three.
5. Hyphens separate the words whenever the count exceeds one.

| term | meaning |
|---|---|
| `studentCount` | input value n, the last position |
| `studentNumber` | current position in the line |
| `remainingValue` | position after removing factors of three |
| `fizzCount` | number of clean divisions by three |
| `fizzPhrase` | fizz words joined by hyphens |

A short script traces the nine sample positions:

| position | divisions by 3 | printed line |
|---|---|---|
| 3 | 1 | fizz |
| 6 | 1 | fizz |
| 9 | 2 | fizz-fizz |
| all others | 0 | the position number |

The ninth position yields two fizz words because 9 equals 3 times 3.

## Code

**Input and scanning.** One read loop loads n, then the hand scanner extracts it.

```nim
const flushBlockBytes = 1 shl 17
const fizzDivisor = 3

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

The divisor constant holds the value three.
Digits build the count one place at a time.
Whitespace and line breaks never enter the value.

**Output scan.** Each position is reduced by repeated division.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let studentCount = nextInt(inputData, scanPos)
for studentNumber in 1 .. studentCount:
  var remainingValue = studentNumber
  var fizzCount = 0
  while remainingValue mod fizzDivisor == 0:
    fizzCount += 1
    remainingValue = remainingValue div fizzDivisor
  if fizzCount == 0:
    appendOutput($studentNumber & "\n")
  else:
    var fizzPhrase = ""
    for fizzIndex in 0 .. fizzCount - 1:
      if fizzIndex > 0:
        fizzPhrase.add '-'
      fizzPhrase.add "fizz"
    appendOutput(fizzPhrase & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The division loop ends at the first nonzero remainder.
Hyphens appear only between fizz words.
The buffer flushes after large blocks of output.

## Complexity

Each position costs at most eight divisions for the given bound.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| position scan | n short division loops | constant |
| output | n lines | one buffer string |

| measure | Big O |
|---|---|
| time | O(n log n) with base 3 on each division count |
| space | O(1) beyond input and output buffers |

Testing every power of three at every position would add repeated modulus work.

The division loop keeps the scan short even at the largest n.

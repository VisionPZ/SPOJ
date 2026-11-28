# MMFSUNDARAM — Sieve of Sundaram (SPOJ)

<https://www.spoj.com/problems/MMFSUNDARAM/>

## Problem

Given one integer n, print every prime not greater than n in ascending order. The judge accepts only a Sieve of Sundaram implementation.

The input is one integer n. The output is one line with the primes separated by single spaces.

The limits from the statement:

| Item | Bound |
|---|---|
| Upper bound | 2 ≤ n ≤ 100000 |
| Prime count | at most 9592 primes |
| Judge limit | 300 ms, 1536 MB |

The bound on n fixes both sieve size and output size.

The sample case:

```
7
```

```
2 3 5 7
```

## Idea

Sundaram's sieve crosses off composite odd numbers, like crossing names off a guest list before inviting the rest. The program marks every value i + j + 2ij up to half of n. Each unmarked index k yields the prime 2k + 1, and 2 is printed separately. Marking costs roughly O(n log n) steps, and printing costs one pass over the surviving indices. Testing each candidate by trial division repeats divisor work for every value. One sieve pass marks each composite once and finishes well inside 300 ms.

Marking once beats testing every candidate separately.

## Why It Works

1. Every odd composite 2k + 1 has k = i + j + 2ij for integers i and j at least 1.
2. The loops set `composite[k]` for each such k up to `halfLimit`.
3. An unmarked index k gives a prime, because no factor pair marked its odd number.
4. The fixed array avoids allocation during the sieve and output phases.

The terms used by the program:

| Term | Meaning |
|---|---|
| `halfLimit` | largest odd index considered, equal to (n − 1) div 2 |
| `composite` | fixed array flagging odd composite indices |
| `leftIndex` | smaller index in the current factor pair |
| `rightIndex` | larger index in the current factor pair |
| `oddIndex` | index of an odd candidate prime |

Each term names one part of the sieve pass.

A script-traced example from `gen.py`:

```
limit 15
primes 2 3 5 7 11 13
count 6
```

The marks remove 9 and 15, leaving six primes at most 15.

## Code

**Input buffer and hand scanner.** This block reads stdin and defines the index scanner.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxCompositeIndex = 50000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects stdin into `inputData`.
The scanner builds n from digits using `scanPos`.
The fixed upper bound keeps the flag array stack allocated.

**Buffered output helpers.** This block writes separated primes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendInteger(value: int) =
  var digits: array[12, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digits[digitCount] = chr(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for digitIndex in countdown(digitCount - 1, 0):
    outputBuffer.add digits[digitIndex]

proc appendPrime(value: int, isFirst: bool) =
  if not isFirst:
    outputBuffer.add ' '
  appendInteger(value)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The digit array holds at most 12 characters.
`appendPrime` inserts one separating space before later primes.
Each block flush caps buffered memory at 128 KiB.

**Sieve marking and printing.** This block marks composites, then emits primes.

```nim
let limit = nextInt(inputData, scanPos)
let halfLimit = (limit - 1) div 2
var composite: array[0..maxCompositeIndex, bool]
for leftIndex in 1..halfLimit:
  var rightIndex = leftIndex
  while leftIndex + rightIndex + 2 * leftIndex * rightIndex <= halfLimit:
    composite[leftIndex + rightIndex + 2 * leftIndex * rightIndex] = true
    rightIndex += 1

if limit >= 2:
  appendPrime(2, true)
for oddIndex in 1..halfLimit:
  if not composite[oddIndex]:
    appendPrime(2 * oddIndex + 1, false)

appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop ends at `halfLimit`, so no index exceeds the array.
The inner loop starts at `rightIndex = leftIndex` and visits each pair once.
The final pass appends 2 first, then every unmarked odd candidate.

## Complexity

The work splits into input parsing, sieve marking, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sieve marking | about O(n log n) pair visits | fixed flag array |
| Output | one write per 128 KiB block | block buffer |

The flag array holds 50,001 booleans at every input size.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(n log n) |
| Space | O(n) |

Trial division costs O(n sqrt n) in total, so the sieve wins at the upper bound.

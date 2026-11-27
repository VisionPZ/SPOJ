# SAFECRAC — Crack the Safe (SPOJ)

<https://www.spoj.com/problems/SAFECRAC/>

## Problem

Count the passcodes of length N whose neighboring digits are adjacent on the keypad. Two digits are adjacent when their keys share an edge; the `Enter` key is never part of a passcode. Output each count modulo 1000000007.

Input starts with T, the number of test cases. Each of the next T lines holds one length N. Output one count per line.

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| passcode length N | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Every digit may start a passcode, so length one has ten valid codes.

Sample input:

```
2
3
25
```

Sample output:

```
74
478325846
```

## Idea

A passcode is a walk on the keypad, like tracing a route between neighboring keys with at most one step per digit. Keep one count per ending digit and extend it by the neighboring digits at each step.

A step scans the small neighbor lists once, so the precomputation costs a constant amount per length. Enumerating every passcode grows exponentially with N and cannot reach length 100000.

One precomputed table answers all test cases in constant time each.

## Why It Works

1. A passcode of length N ends with some digit d.
2. Its prefix of length N minus one must end with a neighbor of d.
3. Therefore the count for d is the sum of the counts of its neighbors.
4. Summing over all ending digits gives the count for length N.
5. Reducing after each step keeps every value below the modulus.

| term | meaning |
|---|---|
| `neighborDigits` | list of keys sharing an edge with each digit |
| `countsByDigit` | number of passcodes of the current length ending at each digit |
| `answersByLength` | precomputed answer for every requested length |
| `answerModulus` | 1000000007, the required modulus |

The keypad places 0 below 7 and `Enter` below 8.

| digit | neighbors |
|---|---|
| 0 | 7 |
| 5 | 2 4 6 8 |
| 8 | 5 7 9 |

A trace of the first three lengths from the generator:

| length | counts by digit summed | answer |
|---|---|---|
| 1 | ten digits start a code | 10 |
| 2 | sum of neighbor counts over starts | 26 |
| 3 | sum of next-step counts | 74 |

The third row matches the sample answer for length three.

## Code

**Input and buffer.** The reader loads all lengths before any precomputation.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007

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

The largest length sets the precomputation bound.
All requests are stored before the table is built.
The buffer collects one answer line per test case.

**Keypad and table.** Neighbor lists drive one count per ending digit.

```nim
let testCount = nextInt(inputData, scanPos)
var requestedLengths = newSeq[int](testCount)
var largestLength = 0
for caseIndex in 0 .. testCount - 1:
  let requestedLength = nextInt(inputData, scanPos)
  requestedLengths[caseIndex] = requestedLength
  if requestedLength > largestLength:
    largestLength = requestedLength

var neighborDigits = newSeq[seq[int]](10)
neighborDigits[0] = @[7]
neighborDigits[1] = @[2, 4]
neighborDigits[2] = @[1, 3, 5]
neighborDigits[3] = @[2, 6]
neighborDigits[4] = @[1, 5, 7]
neighborDigits[5] = @[2, 4, 6, 8]
neighborDigits[6] = @[3, 5, 9]
neighborDigits[7] = @[4, 8, 0]
neighborDigits[8] = @[5, 7, 9]
neighborDigits[9] = @[6, 8]
```

The neighbor lists exclude the `Enter` key.
Digit counts stop at nine keys, so the table is tiny.
The requested lengths stay in input order.

**Precompute and answer.** Each length costs one pass over the ten digits.

```nim
var countsByDigit = newSeq[int](10)
for digit in 0 .. 9:
  countsByDigit[digit] = 1
var answersByLength = newSeq[int](largestLength + 1)
if largestLength >= 1:
  answersByLength[1] = 10
if largestLength >= 2:
  for lengthIndex in 2 .. largestLength:
    var nextCounts = newSeq[int](10)
    for digit in 0 .. 9:
      var totalCount: int64 = 0
      for previousDigit in neighborDigits[digit]:
        totalCount += int64(countsByDigit[previousDigit])
      nextCounts[digit] = int(totalCount mod int64(answerModulus))
    var lengthTotal: int64 = 0
    for digit in 0 .. 9:
      lengthTotal += int64(nextCounts[digit])
    answersByLength[lengthIndex] = int(lengthTotal mod int64(answerModulus))
    countsByDigit = nextCounts

for caseIndex in 0 .. testCount - 1:
  appendOutput($answersByLength[requestedLengths[caseIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Sums use int64 before the modulus keeps them small.
Length one is stored directly because it seeds the table.
Every query then reads one table entry.

## Complexity

Precomputation runs once up to the largest requested length.

| phase | time | space |
|---|---|---|
| input read | one pass over all lengths | one input string |
| table build | ten digits per length | table of length answers |
| output | one line per test case | block buffer |

The table build dominates the runtime.

| measure | Big O |
|---|---|
| time | O(max(N) plus T) |
| space | O(max(N)) |

Enumerating passcodes would grow exponentially instead of linearly.
The ten-digit table keeps length 100000 inexpensive.

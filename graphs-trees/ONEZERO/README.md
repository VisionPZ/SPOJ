# ONEZERO — Ones and zeros (SPOJ)

<https://www.spoj.com/problems/ONEZERO/>

## Problem

For each given `n`, print the smallest multiple whose digits are only 0 and 1 and that starts with 1. The product can exceed a 64-bit integer, so print its digits as a string.

Input: the first line holds `K`, the number of cases. Each of the next `K` lines holds one integer `n`. Output: one digit string per line, in input order.

Notation: `n` is the divisor, `K` is the case count, `r` is a remainder, and `d` is an appended digit.

The bounds from the statement and judge page:

| Item | Bound |
|---|---|
| test cases `K` | approximately 1000 |
| divisor `n` | 1 ≤ n ≤ 20000 |
| answer form | digits 0 and 1 only, first digit 1 |
| answer size | may exceed a 64-bit integer |
| judge limit | 8000 ms, 1536 MB |
| source limit | 4096 B |

The divisor bound sets the number of remainders; the answer size forces string output.

The sample case:

```
3
17
11011
17
```

```
11101
11011
11101
```

Both occurrences of 17 produce the same string, so a cache pays off.

## Idea

Build the number one digit at a time and keep only its remainder after division by `n`. Think of a maze whose rooms are remainders: adding 0 or 1 moves to a new room, and reaching room 0 ends the search.

The program uses breadth-first search over remainders. Each remainder leaves the queue once and generates two children, so a divisor costs at most 2n edge steps. A cache stores each finished string, so repeated divisors cost nothing extra.

Listing every 0 and 1 string doubles the work per digit. With 37 digits that is about 1.4 * 10^11 candidates, while the remainder search touches at most 20000 states.

One search per distinct divisor gives the answer, and the cache reuses it.

## Why It Works

Five facts prove the search.

1. Appending digit `d` to a partial number with remainder `r` gives remainder `(10 * r + d) mod n`. The remainder describes everything about the partial number that later digits can change.
2. Breadth-first search expands shorter strings before longer ones. The first string that reaches remainder 0 has the fewest digits.
3. Trying digit 0 before digit 1 orders strings of equal length by value. The first answer is the smallest such number.
4. Two partial numbers with one remainder share every possible continuation. Keeping the first visit loses no answer.
5. Among `n + 1` numbers made only of ones (1, 11, 111, ...), two share a remainder. Their difference is a 0/1 multiple of `n`, and it has at most `n + 1` digits.

The table names each state the program keeps:

| Term | Meaning |
|---|---|
| `(10 * r + d) mod n` | remainder after appending `d` to a prefix with remainder `r` |
| `parentRemainder` | previous remainder on the shortest path |
| `parentDigit` | digit appended on that step |
| `unvisitedMarker` | the value -2, meaning no path has reached `x` |
| `bfsQueue` | remainders waiting for expansion, in discovery order |

These fields store the path without storing any full candidate string.

A script trace for divisor 17 shows the search expanding remainders:

```
n=17  step remainder prefix -> digit child childRemainder status
   1         1      1 -> 0     10            10 new
   2         1      1 -> 1     11            11 new
   3        10     10 -> 0    100            15 new
   4        10     10 -> 1    101            16 new
   5        11     11 -> 0    110             8 new
   6        11     11 -> 1    111             9 new
   7        15    100 -> 0   1000            14 new
   8        15    100 -> 1   1001            15 seen
   9        16    101 -> 0   1010             7 new
  10        16    101 -> 1   1011             8 seen
  11         8    110 -> 0   1100            12 new
  12         8    110 -> 1   1101            13 new
  13         9    111 -> 0   1110             5 new
  14         9    111 -> 1   1111             6 new
  15        14   1000 -> 0  10000             4 new
  16        14   1000 -> 1  10001             5 seen
  17         7   1010 -> 0  10100             2 new
  18         7   1010 -> 1  10101             3 new
  19        12   1100 -> 0  11000             1 seen
  20        12   1100 -> 1  11001             2 seen
  21        13   1101 -> 0  11010            11 seen
  22        13   1101 -> 1  11011            12 seen
  23         5   1110 -> 0  11100            16 seen
  24         5   1110 -> 1  11101             0 FOUND 11101
```

The trace stops at prefix 11101, whose remainder is 0 after 24 edge steps.

## Code

`firstDigitValue` converts an ASCII digit, and `flushBlockBytes` sets the write block. `unvisitedMarker` marks a remainder with no path yet.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unvisitedMarker = -2
```

Two constants and one marker cover the whole program. The block size is 256 KiB.

**Digit scanner.** `nextInt` reads one integer from the shared input string.

```nim
proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

`scanPos` is a `var` parameter, so the position survives across calls. The loop skips non-digits, including the newlines left by `readLine`. No token string is created.

**Shortest string.** `smallestBinaryMultiple` walks the remainder graph and rebuilds the digits.

```nim
proc smallestBinaryMultiple(divisor: int): string =
  if divisor == 1:
    return "1"
  var parentRemainder = newSeq[int](divisor)
  var parentDigit = newSeq[char](divisor)
  var bfsQueue = newSeq[int](divisor)
  for remainder in 0 ..< divisor:
    parentRemainder[remainder] = unvisitedMarker
  var queueHead = 0
  var queueTail = 0
  var startRemainder = 1 mod divisor
  parentRemainder[startRemainder] = -1
  parentDigit[startRemainder] = '1'
  bfsQueue[queueTail] = startRemainder
  queueTail += 1
  var foundRemainder = -1
  while foundRemainder < 0 and queueHead < queueTail:
    let currentRemainder = bfsQueue[queueHead]
    queueHead += 1
    var digitValue = 0
    while digitValue <= 1:
      let nextRemainder = (currentRemainder * 10 + digitValue) mod divisor
      if parentRemainder[nextRemainder] == unvisitedMarker:
        parentRemainder[nextRemainder] = currentRemainder
        if digitValue == 0:
          parentDigit[nextRemainder] = '0'
        else:
          parentDigit[nextRemainder] = '1'
        if nextRemainder == 0:
          foundRemainder = 0
          break
        bfsQueue[queueTail] = nextRemainder
        queueTail += 1
      digitValue += 1
  var digitCount = 0
  var traceRemainder = foundRemainder
  while traceRemainder >= 0:
    digitCount += 1
    traceRemainder = parentRemainder[traceRemainder]
  var answer = newString(digitCount)
  var writePos = digitCount - 1
  traceRemainder = foundRemainder
  while traceRemainder >= 0:
    answer[writePos] = parentDigit[traceRemainder]
    writePos -= 1
    traceRemainder = parentRemainder[traceRemainder]
  return answer
```

Each remainder leaves `bfsQueue` once, and `digitValue` tries 0 before 1. The root digit is '1', stored at `startRemainder`. The last loop fills `answer` backwards from `foundRemainder`. For `divisor` equal to 1, the string "1" is already a multiple.

**Driver.** One read of stdin, one cached answer per divisor, one buffered output.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var cachedAnswers = newSeq[string](20001)
var outputBuffer = ""
for _ in 1 .. caseCount:
  let divisor = nextInt(inputData, scanPos)
  if cachedAnswers[divisor].len == 0:
    cachedAnswers[divisor] = smallestBinaryMultiple(divisor)
  outputBuffer.add cachedAnswers[divisor]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

`readLine` appends every line to `inputData`, so blank lines cannot desync the reader. `cachedAnswers` skips a second search for a repeated divisor. The last `stdout.write` emits the tail after the loop.

## Complexity

The work splits into reading, one search per distinct divisor, and output:

| Phase | Time | Space |
|---|---|---|
| input read | one pass over bytes, one digit scan per value | input bytes |
| one divisor | at most 2n edge steps and n queue pushes | three arrays of n slots |
| cache | one search per distinct divisor | up to 20001 cached strings |
| output | one write per 256 KiB block | 256 KiB buffer |

Most cases finish in a few milliseconds because the divisor bound limits every search.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| time | O(n) per distinct divisor, plus O(K + output digits) for I/O |
| space | O(n) working storage plus one cached string per distinct divisor |

Listing all 0 and 1 strings costs O(2^L) for an answer of L digits, up to 2^37 candidates. The remainder search touches at most 20000 states for the same divisor.

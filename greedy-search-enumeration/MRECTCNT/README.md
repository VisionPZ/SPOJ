# MRECTCNT — Rectangles Counting (SPOJ)

<https://www.spoj.com/problems/MRECTCNT/>

## Problem

A rectangle with integer sides is cut into unit squares, and one diagonal passes through some of them. Count the unordered side pairs whose diagonal meets exactly N squares.

The input is a single integer `N`. The output is a single integer: the number of rectangles with side lengths a and b, where a at most b, and `a + b - gcd(a, b)` equals N.

The bounds from the statement:

| item | bound |
|---|---|
| target N | 1 to 999999 |
| side lengths | positive integers, unordered pairs |
| judge limit | 1000 ms, 1536 MB |

The diagonal count formula turns a geometry question into a number-theory count.

Sample input:

```
4
```

Sample output:

```
4
```

## Idea

A diagonal climbs across grid lines like a walker stepping over tiles, and it enters a new square at every row line or column line it crosses. Shared crossings at grid corners merge two steps, which is why the greatest common divisor is subtracted.

The algorithm uses the identity `a + b - gcd(a, b)` for the number of squares. Write a and b as a common factor times coprime sides, so N becomes that factor times `x + y - 1`. Each divisor of N then contributes the number of coprime pairs that sum to the divisor plus one.

Euler's totient counts those coprime pairs in half its value, because each pair and its swap share the same sum. A small sieve computes all totients up to N plus one in one pass.

Enumerating every side pair up to N would cost quadratic time, far above the divisor scan.

Trying each divisor once turns the count into a short loop over square-root of N values.

## Why It Works

1. A diagonal crosses a minus 1 internal vertical lines and b minus 1 internal horizontal lines.
2. It enters a new square at each crossing, but corner crossings count for both directions at once.
3. The number of corner crossings is `gcd(a, b) - 1`, giving `a + b - gcd(a, b)` squares.
4. Writing a as g times x and b as g times y with coprime x and y gives `N = g * (x + y - 1)`.
5. For a divisor s of N, the copied factor is g, and the coprime pair must sum to s plus 1.
6. Coprime pairs with sum m number `phi(m) / 2` when m exceeds 2, and exactly 1 when m equals 2.

The main terms and formulas:

| term | meaning |
|---|---|
| `sieveLimit` | N plus 1, the largest totient index needed |
| `phiValues` | Euler totient for every index up to the limit |
| `stepContribution` | rectangle count for one divisor of N |
| `rectangleCount` | running total over all divisors |

The table names the values built by the sieve and the divisor loop.

The gen.py oracle loops each divisor and tests coprime pairs with a gcd call. On the sample it produces this trace:

```
divisor 1 -> pair (1, 1), scale 4 -> 1 rectangle
divisor 2 -> pairs (1, 2), scale 2 -> 1 rectangle
divisor 4 -> pairs (1, 4) and (2, 3), scale 1 -> 2 rectangles
total = 1 + 1 + 2 = 4
```

The trace gives the sample answer of four rectangles.

## Code

**Input and scanner.** One read loads stdin, and the integer parser skips separators.

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

The statement supplies one target value.
The parser needs no sign branch.
The output buffer flushes by block size.

**Totient sieve.** Every totient up to N plus one is filled in one sweep.

```nim
proc stepContribution(stepSize: int, phiTable: seq[int]): int64 =
  if stepSize == 1:
    return 1
  return int64(phiTable[stepSize + 1] div 2)

let targetValue = nextInt(inputData, scanPos)
let sieveLimit = targetValue + 1
var phiValues = newSeq[int](sieveLimit + 1)
for index in 0 .. sieveLimit:
  phiValues[index] = index
for primeCandidate in 2 .. sieveLimit:
  if phiValues[primeCandidate] == primeCandidate:
    var multiple = primeCandidate
    while multiple <= sieveLimit:
      phiValues[multiple] = (phiValues[multiple] div primeCandidate) * (primeCandidate - 1)
      multiple += primeCandidate
```

An untouched entry marks a prime.
Each prime updates all of its multiples once.
The special divisor 1 contributes a square rectangle.

**Divisor scan.** Divisors come in pairs, and each pair adds two contributions.

```nim
var rectangleCount: int64 = 0
var divisor = 1
while divisor * divisor <= targetValue:
  if targetValue mod divisor == 0:
    rectangleCount += stepContribution(divisor, phiValues)
    let pairedDivisor = targetValue div divisor
    if pairedDivisor != divisor:
      rectangleCount += stepContribution(pairedDivisor, phiValues)
  divisor += 1

appendOutput($rectangleCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A square divisor is added once.
The loop stops at the square root of N.
One buffered line holds the answer.

## Complexity

The sieve touches each multiple once per prime factor, and the divisor loop stops at the square root.

| phase | time | space |
|---|---|---|
| input read | one integer | one input string |
| totient sieve | up to N plus 1 entries | one array of N plus 1 integers |
| divisor scan | square root of N checks | a few counters |
| output | one line | block buffer |

The totient array sets the space cost.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(N log log N) |
| space | O(N) |

Checking every unordered side pair up to N would cost O(N squared) time.

The divisor scan keeps the arithmetic small after the sieve is ready.

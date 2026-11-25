# TRIALDIV — Trial Division (SPOJ)

<https://www.spoj.com/problems/TRIALDIV/>

## Problem

For each number, print its prime factors in ascending order, repeated once per multiplicity, separated by spaces. The value 1 has no factors, so its answer is an empty line.

| item | bound |
|---|---|
| test cases | one count on the first line, then one number per case |
| number value | 1 to 1000000 |
| test cases count | up to 100000 |
| judge limit | 1000 ms, 1536 MB |

The number cap allows a precomputed factor table that serves every case.

Sample input:

```
6
16
127
256
513
2048
5097
```

Sample output:

```
2 2 2 2
127
2 2 2 2 2 2 2 2
3 3 3 19
2 2 2 2 2 2 2 2 2 2 2
3 1699
```

## Idea

Think of a multiplication table where each cell already names its smallest prime factor, so factoring becomes reading a cell and dividing. The algorithm builds that table with a sieve: each prime marks its uncovered multiples starting at its square, and unmarked entries become their own smallest factor. Each case then divides by the table entry until the number reaches 1. That costs a few steps per factor, while trial division tests every candidate divisor up to the square root. The table is built once and reused by all cases.

## Why It Works

1. A composite below 1000000 has a smallest prime factor at most its square root.
2. Marking multiples from the square of a prime skips pairs already handled by smaller primes.
3. An entry left unmarked after the sieve is prime, so it becomes its own factor.
4. Dividing by the smallest factor shrinks the number and keeps the remaining value factorizable.
5. Repeated division emits factors in ascending order, matching the required output.

| term | meaning |
|---|---|
| `limitValue` | 1000000, the largest number in the input |
| `smallestPrime` | table mapping each number to its smallest prime factor |
| `candidate` | sieve value being tested as a prime |
| `multiple` | composite value receiving a factor mark |
| `factorValue` | factor found for the current number |
| `firstFactor` | flag that places a space before later factors |

The table replaces repeated divisor tests with direct lookups.

A script-traced example from the generator:

```
number 5097
smallestPrime[5097] = 3, 5097 / 3 = 1699
smallestPrime[1699] = 1699, 1699 / 1699 = 1
factors 3 1699
```

The trace reproduces the last sample line.

## Code

**Input and scanner.** The reader loads all of stdin and defines the buffered output path.

```nim
const flushBlockBytes = 1 shl 17
const limitValue = 1000000

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

The limit sets the table length.
The scanner accepts numbers separated by any whitespace.
The buffer keeps output writes infrequent.

**Factor table.** The sieve fills the smallest prime factor for every value up to the limit.

```nim
var smallestPrime = newSeq[int](limitValue + 1)
var candidate = 2
while int64(candidate) * int64(candidate) <= int64(limitValue):
  if smallestPrime[candidate] == 0:
    smallestPrime[candidate] = candidate
    var multiple = int64(candidate) * int64(candidate)
    while multiple <= int64(limitValue):
      if smallestPrime[int(multiple)] == 0:
        smallestPrime[int(multiple)] = candidate
      multiple = multiple + int64(candidate)
  candidate += 1
for numberValue in 2 .. limitValue:
  if smallestPrime[numberValue] == 0:
    smallestPrime[numberValue] = numberValue
```

The outer loop stops at the square root of the limit.
64-bit products keep the square comparison exact.
The final loop marks every remaining prime as its own factor.

**Factorization loop.** Each case divides by table entries until the number becomes 1.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var numberValue = nextInt(inputData, scanPos)
  var firstFactor = true
  while numberValue > 1:
    let factorValue = smallestPrime[numberValue]
    if not firstFactor:
      appendOutput(" ")
    appendOutput($factorValue)
    firstFactor = false
    numberValue = numberValue div factorValue
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per prime factor with multiplicity.
The flag avoids a leading space on every answer line.
A value of 1 writes only the newline.

## Complexity

The sieve runs once, and each case costs one division per factor.

| phase | time | space |
|---|---|---|
| table build | one pass over multiples of each prime | one integer per value |
| factorization | one lookup and division per factor | scanner position |
| output | one line per case | block buffer |

The phase table shows that the table build is a fixed setup cost.

| measure | Big O |
|---|---|
| time | O(L log log L + T log L), with L = 1000000 |
| space | O(L) for the factor table |

Trial division for every case would test divisors up to the square root each time; the shared table removes that repeated work.

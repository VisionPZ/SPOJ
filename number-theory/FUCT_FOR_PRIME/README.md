# FUCT_FOR_PRIME — List Prime Numbers (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_PRIME/>

## Problem

For each query, list every prime in the inclusive range between two endpoints. The endpoints may arrive in either order, so the smaller one starts the range.

The first line holds t, the number of tests, with 1 ≤ t ≤ 1000. Each of the next t lines holds two integers a and b with 1 ≤ a, b ≤ 500. Print the primes in increasing order, separated by commas, one line per test.

| item | bound |
|---|---|
| tests t | 1 to 1000 |
| endpoints a, b | 1 to 500 |
| judge limit | 1000 ms, 1536 MB |

The upper bound is fixed at 500, so one table serves every test.

Sample input:

```
2
10 50
500 400
```

Sample output:

```
11,13,17,19,23,29,31,37,41,43,47
401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499
```

## Idea

Crossing out multiples of each small prime is like striking every second, third, and fifth name off a class list.

A sieve builds one table of prime flags up to 500. Each test then reads that table once across its range. Marking costs one step per multiple, and answering costs one step per value. Testing each value by division would repeat the same work for every test.

Takeaway: build the table once, then read it many times.

## Why It Works

1. A sieve marks every multiple of 2, 3, 5, and so on as composite.
2. A value stays marked prime only when no smaller prime divides it.
3. Starting each marking at the square of the prime avoids repeated work.
4. Swapping reversed endpoints gives the same inclusive range in order.
5. A comma is added only before a value that follows an earlier prime.

| term | meaning |
|---|---|
| `maxEndpoint` | the largest allowed value, 500 |
| `primeFlags` | the sieve table indexed by value |
| `leftEndpoint` | the smaller end of the query range |
| `rightEndpoint` | the larger end of the query range |
| `hasPreviousPrime` | true after at least one prime was written |

The table and the two ends describe each answer completely.

For the sample, the range 10 to 50 yields 11,13,17,19,23,29,31,37,41,43,47. The reversed pair 500 400 is read as 400 to 500 and yields 401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499.

The value 1 stays unmarked, so it never appears in an answer. An empty range of primes produces an empty line.

## Code

**Input and scanning.** The hand reader loads the test count and the pairs.

```nim
const flushBlockBytes = 1 shl 17
const maxEndpoint = 500

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

The scanner skips spaces and newlines.
Every endpoint is positive, so no minus branch is needed.
The endpoint bound is a named constant.

**Buffered output.** One string collects all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Sieve table.** Multiples of each prime are marked composite once.

```nim
proc buildPrimeFlags(): seq[bool] =
  var primeFlags = newSeq[bool](maxEndpoint + 1)
  var endpoint = 2
  while endpoint <= maxEndpoint:
    primeFlags[endpoint] = true
    endpoint += 1
  var candidate = 2
  while candidate * candidate <= maxEndpoint:
    if primeFlags[candidate]:
      var multiple = candidate * candidate
      while multiple <= maxEndpoint:
        primeFlags[multiple] = false
        multiple += candidate
    candidate += 1
  return primeFlags
```

Values 0 and 1 stay false by default.
Marking starts at the square of the current prime.
The loop stops once the square passes 500.

**Answer each test.** Each pair is normalised and written as one comma-separated line.

```nim
let primeFlags = buildPrimeFlags()
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  var leftEndpoint = nextInt(inputData, scanPos)
  var rightEndpoint = nextInt(inputData, scanPos)
  if leftEndpoint > rightEndpoint:
    swap(leftEndpoint, rightEndpoint)
  var lineText = ""
  var hasPreviousPrime = false
  var endpoint = leftEndpoint
  while endpoint <= rightEndpoint:
    if primeFlags[endpoint]:
      if hasPreviousPrime:
        lineText.add ','
      lineText.add $endpoint
      hasPreviousPrime = true
    endpoint += 1
  appendOutput(lineText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The swap handles the reversed pair in the sample.
The flag suppresses a leading or trailing comma.
Every test contributes exactly one line.

## Complexity

The sieve runs once before any test. Each test scans its own range.

| phase | time | space |
|---|---|---|
| sieve | one pass over multiples up to 500 | 501 flags |
| each test | one pass over the range | one line string |
| output | one line per test | one block buffer |

| measure | Big O |
|---|---|
| sieve | O(M log log M), M = 500 |
| all tests | O(total range length) |
| space | O(M) |

Trial division for each value of every test would repeat far more work.

Takeaway: one small sieve answers all 1000 tests.

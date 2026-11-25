# G10185 — TrianguloRectangulo Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10185/>

## Problem

Print the primes below 1000 in descending order, arranged as a right triangle with one more prime in each row. The triangle stops when the requested rows are printed or the prime list runs out.

The input holds one integer, the number of rows to draw. The output holds that many rows, with row k containing k primes taken in descending order and separated by single spaces.

The bounds that shape the output:

| item | bound |
|---|---|
| requested rows | positive integer; 168 primes limit the printed rows |
| prime pool | 997 down to 2, all primes below 1000 |
| judge limit | 1000 ms, 1536 MB |

The prime pool sets the maximum number of complete rows.

Sample input:

```
4
```

Sample output:

```
997
991 983
977 971 967
953 947 941 937
```

## Idea

Stack the primes like books in a widening tower, adding one more book to each row. The sieve of Eratosthenes marks composites up to 1000, and a downward scan collects the primes in order. Each printed prime costs one append, so the row loop scales with the output size. Testing every candidate again for each row would repeat the sieve work. Sieve once, then stream the list row by row.

## Why It Works

1. A sieve flag stays true exactly when its index has no smaller prime factor.
2. Scanning indexes from 1000 down to 2 yields primes in descending order.
3. Row k takes k consecutive primes from that descending list.
4. Stopping at the list end keeps the triangle valid for oversized row counts.
5. Single spaces and one newline per row match the required layout.

The names below carry the sieve state:

| term | meaning |
|---|---|
| `primeFlags` | prime markers for values up to 1000 |
| `descendingPrimes` | collected primes, largest first |
| `rowCount` | rows requested by the input |
| `rowWidth` | primes to print in the current row |

These values turn a fixed prime pool into a widening triangle.

A script trace from the generator:

```
primes below 1000: [997, 991, 983, 977, 971, 967, 953, 947, 941, 937]
count: 168
rows that fit: 17
```

The first ten primes fill four rows as 1 + 2 + 3 + 4, matching the sample.

## Code

**Input and scanning.** The reader joins all input lines and parses the row count.

```nim
const flushBlockBytes = 1 shl 17
const maxPrimeValue = 1000

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

The scan skips whitespace before the digits.
The value stays in range for a small row count.
Parsing touches each input byte once.

**Prime pool.** Marking composites leaves a descending list ready for output.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var primeFlags = newSeq[bool](maxPrimeValue + 1)
for candidate in 2 .. maxPrimeValue:
  primeFlags[candidate] = true
var factor = 2
while factor * factor <= maxPrimeValue:
  if primeFlags[factor]:
    var multiple = factor * factor
    while multiple <= maxPrimeValue:
      primeFlags[multiple] = false
      multiple += factor
  factor += 1

var descendingPrimes = newSeq[int](0)
for candidate in countdown(maxPrimeValue, 2):
  if primeFlags[candidate]:
    descendingPrimes.add candidate
```

The factor loop stops at the square root of 1000.
The downward pass produces the required prime order.
The output buffer flushes in large blocks.

**Row emission.** Each row takes the next slice of primes and ends with a newline.

```nim
var rowCount = nextInt(inputData, scanPos)
var primeIndex = 0
var rowWidth = 1
while rowCount > 0 and primeIndex < descendingPrimes.len:
  var column = 0
  while column < rowWidth and primeIndex < descendingPrimes.len:
    if column > 0:
      appendOutput(" ")
    appendOutput($descendingPrimes[primeIndex])
    primeIndex += 1
    column += 1
  appendOutput("\n")
  rowWidth += 1
  rowCount -= 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The row loop stops when the prime list ends.
A space precedes every prime except the first in a row.
The final write drains the remaining buffer.

## Complexity

The sieve builds the pool once, then each row appends a fixed number of tokens.

| phase | time | space |
|---|---|---|
| input read | one pass over the input text | one input string |
| sieve | mark composites up to 1000 | one flag per value |
| row emission | one append per printed prime | one descending list |

The fixed sieve cost stays small while the row loop scales with printed primes.

Let p be the number of printed primes:

| measure | Big O |
|---|---|
| time | O(p) after fixed sieve work |
| space | O(1000) |

Testing primality again for every row would repeat work the sieve already finished.

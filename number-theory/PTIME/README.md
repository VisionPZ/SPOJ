# PTIME — Prime Time (SPOJ)

<https://www.spoj.com/problems/PTIME/>

## Problem

Several numbers arrive one per line. For each number, report the prime factorization of its factorial with every exponent written out.

Each test case holds one integer N on its own line. Read lines until the input ends. Print one line per case, listing primes in increasing order as `primeValue^exponent` joined by `" * "`.

| item | bound |
|---|---|
| factorial argument N | 2 to 10000 |
| test cases | until end of input |
| judge limit | 1000 ms, 1536 MB |

The largest argument drives the design: the answer needs every prime up to 10000.

Sample input:

```
10
```

Sample output:

```
2^8 * 3^4 * 5^2 * 7^1
```

## Idea

Count each prime inside a factorial by adding floor divisions, like counting how many rows of a fixed size fit in a stack. The real algorithm is Legendre's formula, computed after one sieve primes once.

For a prime p, the exponent in N! is the sum of N div p, N div p^2, N div p^3, and so on. Each term counts one layer of multiples. Evaluating all primes costs about O(pi(N) log N) operations, independent of the factorial's size.

Building N! first would create a number with thousands of digits, then require slow division. The formula works with small integers only. The takeaway is to count prime layers instead of multiplying out the factorial.

## Why It Works

1. A factorial N! is the product of every integer from 1 to N.
2. Multiples of p contribute one factor p each, giving N div p factors.
3. Multiples of p^2 contribute a second factor, giving N div p^2 more factors.
4. Adding every power of p counts each factor exactly once, which is Legendre's formula.
5. Every prime below N contributes at least one factor, so the sieve list is complete.

| term | meaning |
|---|---|
| `isComposite` | sieve flag marking nonprime numbers up to `maxPrimeLimit` |
| `primes` | sorted list of primes used as factors |
| `limitValue` | the factorial argument N for one case |
| `power` | current power of p in the summation |
| `exponent` | accumulated exponent for the current prime |

The table names each value that the loop maintains.

A script trace for N = 10 starts from 10! = 3628800. Division by 2 succeeds eight times and leaves 14175. Division by 3 succeeds four times and leaves 175. Division by 5 succeeds twice and leaves 7. Division by 7 succeeds once and leaves 1.

| prime | divisions | value left |
|---|---|---|
| 2 | 8 | 14175 |
| 3 | 4 | 175 |
| 5 | 2 | 7 |
| 7 | 1 | 1 |

The trace reproduces the sample exponents exactly.

The power loop stops before multiplication can exceed `limitValue`. No rounding appears anywhere because every operation is integer division.

## Code

**Input and scanner.** The reader loads all lines and slices numbers with a digit scanner.

```nim
const flushBlockBytes = 1 shl 17
const maxPrimeLimit = 10000

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

The scanner skips spaces and line breaks between cases.
It stops at the first nondigit after each number.
The sieve bound is fixed because N never exceeds 10000.

**Sieve and output buffer.** A small sieve lists every usable prime, and one buffer collects all output.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isComposite = newSeq[bool](maxPrimeLimit + 1)
var primes: seq[int] = @[]
for candidate in 2 .. maxPrimeLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if candidate * candidate <= maxPrimeLimit:
      var multiple = candidate * candidate
      while multiple <= maxPrimeLimit:
        isComposite[multiple] = true
        multiple += candidate
```

The sieve marks composites starting at each prime's square.
`flushBlockBytes` limits how much text stays in memory.
Each composite receives one mark from its smallest prime factor.

**Exponent summation.** Each case walks the prime list and counts layered multiples.

```nim
while scanPos < inputData.len:
  let limitValue = nextInt(inputData, scanPos)
  if limitValue < 2:
    break
  var firstTerm = true
  for primeValue in primes:
    if primeValue > limitValue:
      break
    var power = primeValue
    var exponent = 0
    while power <= limitValue:
      exponent += limitValue div power
      if power > limitValue div primeValue:
        break
      power *= primeValue
    if not firstTerm:
      appendOutput(" * ")
    firstTerm = false
    appendOutput($primeValue)
    appendOutput("^")
    appendOutput($exponent)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The `firstTerm` flag places separators only between factors.
The guard before `power *= primeValue` prevents overflow.
One final write flushes any remaining buffered text.

## Complexity

The sieve runs once, and each case scans the prime list with short power loops.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| sieve | one pass up to 10000 | sieve flags and prime list |
| exponent summation | about pi(N) log N per case | constant scratch |
| output | buffered writes | one output buffer |

The sieve cost is paid once, so many cases share it.

| measure | Big O |
|---|---|
| time | O(maxN log log maxN + cases * pi(maxN) log maxN) |
| space | O(maxN) |

Computing each factorial as a big integer would cost far more than counting layered divisions. The formula keeps every arithmetic operation small and exact.

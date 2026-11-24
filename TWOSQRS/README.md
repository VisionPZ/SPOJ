## Problem

Read several integers up to 10¹². For each one, decide whether it can be written as the sum of two squares of integers. Print `Yes` or `No` on its own line.

| Quantity | Bound |
| --- | --- |
| Test cases `c` | at most 100 |
| Value `n` | 0 to 10¹² |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

A value may be zero, and the same square may be used twice.

## Idea

Factor the value and inspect only primes congruent to 3 modulo 4. Such a prime must occur an even number of times; otherwise the value is not a sum of two squares. Primes congruent to 1 modulo 4 and the prime 2 never block a representation.

A sieve builds all primes up to 10⁶ once. Each test case then trial-divides by those primes and checks the exponents. The sieve costs O(10⁶ log log 10⁶) once; factoring one value costs at most O(π(10⁶)) divisions.

## Why It Works

Fermat's two-square theorem says a positive integer is a sum of two squares exactly when every prime factor of the form `4k + 3` has an even exponent. The rule is:

- divide out each prime `p` while `p²` does not exceed the remaining value
- count how many times `p` divides it
- return `No` when `p mod 4 = 3` and the count is odd
- after the loop, the remaining factor is prime; reject it when it is `3 mod 4`

Zero passes because it is `0² + 0²`. The sieve covers every possible small factor because `√(10¹²) = 10⁶`.

## Code

The sieve and the digit scanner use one input buffer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const primeLimit = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

Values reach 10¹², so the scanner and all arithmetic use 64 bits. Each digit is visited once.

The sieve writes one flag per integer and collects the primes in order.

```nim
var isComposite = newSeq[bool](primeLimit + 1)
var primes: seq[int] = @[]
for candidate in 2..primeLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= primeLimit:
      var multiple = candidate * candidate
      while multiple <= primeLimit:
        isComposite[multiple] = true
        multiple += candidate
```

Crossing off starts at `candidate²`, so each composite is marked once per distinct prime factor. The table is built before any case is read from the parsed buffer.

The check divides out each prime and inspects its exponent.

```nim
proc isSumOfTwoSquares(value: int64): bool =
  var remaining = value
  for prime in primes:
    let primeValue = int64(prime)
    if primeValue * primeValue > remaining:
      break
    if remaining mod primeValue != 0:
      continue
    var exponent = 0
    while remaining mod primeValue == 0:
      remaining = remaining div primeValue
      exponent += 1
    if primeValue mod 4 == 3 and (exponent and 1) == 1:
      return false
  if remaining > 1 and remaining mod 4 == 3:
    return false
  return true
```

The loop stops when the square of the next prime exceeds the remainder. The leftover value is then prime, so one modulo-four test finishes the decision.

The driver writes the answers through one output buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, i))
for j in 0..<caseCount:
  let value = nextInt(inputData, i)
  if isSumOfTwoSquares(value):
    appendOutput("Yes")
  else:
    appendOutput("No")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case performs one factorization and one answer. The buffer flushes in blocks, never once per case.

## Complexity

The sieve costs O(10⁶ log log 10⁶) time and O(10⁶) space. Each case costs at most O(π(10⁶)) divisions and O(1) extra space. Output costs O(1) per case. Total time is the sieve cost plus O(c · π(10⁶)), and total space is O(10⁶). Testing every pair of squares up to √n would cost O(n) per case.

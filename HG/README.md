# HG — Huge GCD (SPOJ)

<https://www.spoj.com/problems/HG/>

## Problem

A and B are products of many small integers. Print their greatest common divisor, keeping only its last nine digits if it has more than nine digits.

Input gives N, then N factors of A, then M, then M factors of B. Output is one integer, with leading zeros when the true answer exceeds nine digits.

| item | bound |
|---|---|
| factor counts N and M | 1 to 1000 each |
| each factor | positive and below 1e9 |
| judge limit | 1000 ms, 1536 MB |

The products are far larger than any machine integer, so the answer needs a factored approach.

Sample input:

```
3
2 3 5
2
4 5
```

Sample output:

```
10
```

A is 30, B is 20, and their gcd is 10.

## Idea

Compare two towers by their bricks, then rebuild only the bricks they share.

Prime factorization turns each product into a list of prime exponents. The gcd keeps the smaller exponent for every prime. The program multiplies those shared powers while tracking the remainder modulo 1e9. A flag records whether the exact product ever passed nine digits. Building both giant products first needs arbitrary precision and far more work.

## Why It Works

1. A product is fully described by the exponent of each prime in its factors.
2. The gcd of two products takes the minimum exponent for every prime.
3. Trial division by primes up to the square root finds every factor; a leftover above one is prime.
4. Multiplying shared powers modulo 1e9 gives the last nine digits without storing the whole gcd.
5. Once the running value reaches 1e9, padding with leading zeros reproduces the required output.

| term | meaning |
|---|---|
| `exponentsFirst` | prime exponents collected from the factors of A |
| `exponentsSecond` | prime exponents collected from the factors of B |
| `remainder` | running product modulo 1e9 |
| `exceedsLimit` | whether the exact gcd has more than nine digits |
| `digitLimit` | 1e9, the divisor used for the last nine digits |

Each multiplication stays below 1e18, which fits a signed 64-bit integer.

A script traces the second statement sample:

```
A primes: 2^3, 3, 41, 97^2, 8863, 29881
B primes: 2^2, 29, 41^2, 97^2, 8863, 29881
shared: 2^2 * 41 * 97^2 * 8863 * 29881
gcd = 408661000012028, 15 digits
last 9 digits padded: 000012028
```

The trace explains why leading zeros appear even though the printed value reads 12028.

## Code

**Input, scanner, and buffer.** The reader loads stdin once and parses positive integers.

```nim
import tables

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const digitLimit = 1000000000
const outputDigits = 9
const primeLimit = 31623

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and line breaks between factors.
The sieve limit covers square roots up to 1e9.
Output still passes through one block buffer.

**Prime sieve and factorization.** Small primes are generated once, then used on every factor.

```nim
var composite = newSeq[bool](primeLimit + 1)
var primes = newSeq[int](0)
for candidate in 2 .. primeLimit:
  if not composite[candidate]:
    primes.add candidate
    var multiple = candidate * candidate
    while multiple <= primeLimit:
      composite[multiple] = true
      multiple += candidate

proc addExponent(table: var Table[int, int], primeValue: int) =
  if table.hasKey(primeValue):
    table[primeValue] = table[primeValue] + 1
  else:
    table[primeValue] = 1

proc factorize(value: int, table: var Table[int, int]) =
  var remaining = value
  var primeIndex = 0
  while primeIndex < primes.len and primes[primeIndex] * primes[primeIndex] <= remaining:
    let primeValue = primes[primeIndex]
    while remaining mod primeValue == 0:
      addExponent(table, primeValue)
      remaining = remaining div primeValue
    primeIndex += 1
  if remaining > 1:
    addExponent(table, remaining)
```

The sieve writes each prime once.
Division stops early when the prime square exceeds the remainder.
A leftover above one is a final prime factor.

**Shared exponents and remainder.** The program keeps only primes present on both sides.

```nim
let factorCountFirst = nextInt(inputData, scanPos)
var exponentsFirst = initTable[int, int]()
for factorIndex in 0 .. factorCountFirst - 1:
  factorize(nextInt(inputData, scanPos), exponentsFirst)
let factorCountSecond = nextInt(inputData, scanPos)
var exponentsSecond = initTable[int, int]()
for factorIndex in 0 .. factorCountSecond - 1:
  factorize(nextInt(inputData, scanPos), exponentsSecond)

var remainder: int64 = 1
var exceedsLimit = false
for primeValue in exponentsFirst.keys:
  if not exponentsSecond.hasKey(primeValue):
    continue
  var exponent = exponentsFirst[primeValue]
  let otherExponent = exponentsSecond[primeValue]
  if otherExponent < exponent:
    exponent = otherExponent
  for powerIndex in 0 .. exponent - 1:
    let multiplier = int64(primeValue)
    if exceedsLimit:
      remainder = (remainder * multiplier) mod int64(digitLimit)
    else:
      let product = remainder * multiplier
      if product >= int64(digitLimit):
        exceedsLimit = true
      remainder = product mod int64(digitLimit)
```

A prime missing from B contributes nothing.
The smaller exponent is used for every shared prime.
The flag flips once the exact product passes 1e9.

**Final formatting.** The answer is padded only when the true gcd is too long.

```nim
if exceedsLimit:
  let digits = $remainder
  var padded = ""
  for padIndex in 0 .. outputDigits - digits.len - 1:
    padded.add '0'
  padded.add digits
  appendOutput padded
else:
  appendOutput $remainder
appendOutput "\n"
stdout.write outputBuffer
outputBuffer.setLen 0
```

Short answers keep their normal decimal form.
Long answers always occupy exactly nine characters.
The final write flushes the buffer once.

## Complexity

Sieve setup happens once; each input factor is then divided by small primes.

| phase | time | space |
|---|---|---|
| sieve | primes up to 31623 | one boolean array |
| factorization | up to 3401 divisions per factor | two exponent tables |
| gcd product | one multiply per shared exponent | constant |
| output | one line | block buffer |

The exponent tables never hold more entries than the distinct primes seen.

| measure | Big O |
|---|---|
| time | O(primeLimit log log primeLimit + (N+M) times divisions) |
| space | O(number of distinct primes) |

Building both products as big integers needs far more memory and time.
Factored exponents are the takeaway.

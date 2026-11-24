## Problem

Read a count, then one integer per line. Print YES when that integer is prime and NO otherwise. Values reach 2^63 - 1, so trial division is too slow.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 500 |
| Candidate value | 2 <= N <= 2^63 - 1 |
| Time limit | 21 000 ms |
| Memory limit | 1536 MB |

The value bound, not the case count, decides the algorithm.

## Idea

Use deterministic Miller-Rabin testing with twelve fixed bases; doubling replaces 128-bit multiplication. Each base costs about 64 squarings, so one candidate costs 12 x 64 x 64 small steps. Trial division would need about 3 billion divisions for a 64-bit prime.

Cost per candidate: 12 bases x 63 squarings x 64 doubling steps.

## Why It Works

Fermat's little theorem says that a prime n divides a^(n-1) - 1 for every base a below n. The strong form writes n - 1 as an odd part times a power of two. It squares the first power repeatedly and checks the sequence.

A composite fails at least one base. The twelve bases from 2 to 37 cover every value below 2^64. Each candidate is below 2^63, so the set is enough.

| Term | Meaning |
| --- | --- |
| `oddPart` | odd factor of candidate minus one |
| `twosCount` | number of factors of two in candidate minus one |
| `modMultiply` | one modular product, built by repeated doubling |
| `witnessBases` | twelve bases that prove primality below 2^64 |

The table gives every name used by the test. The update formulas are:

```
n - 1 = oddPart * 2^twosCount
term = base^oddPart mod n
term = term^2 mod n, repeated twosCount - 1 times
product = product + doubled; if product >= modulus: product -= modulus
doubled = doubled + doubled; if doubled >= modulus: doubled -= modulus
```

Both `product` and `doubled` stay below the modulus before each add. The modulus is at most 2^63 - 1, so twice the modulus fits in `uint64`. No 128-bit type is needed.

A script produced this trace for a composite that fools bases 2, 3, 5 and 7:

```
n=3215031751 oddPart=1607515875 twosCount=1
base  2: passes with final term 1
base  3: passes with final term 3215031750
base  5: passes with final term 1
base  7: passes with final term 3215031750
base 11: FAILS with final term 2129160099
```

Base 11 exposes the composite, so the answer is NO. The doubling trace for 7 x 11 mod 13 is:

```
step remaining doubled product
   0         5       1       7
   1         2       2       8
   2         1       4       8
   3         0       8      12
result 12
```

The result 12 is correct and no intermediate value exceeds 26.

## Code

The constants hold the digit offset, the output block size and the witness set.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const witnessBases: array[12, uint64] = [2'u64, 3'u64, 5'u64, 7'u64, 11'u64, 13'u64,
                                         17'u64, 19'u64, 23'u64, 29'u64, 31'u64, 37'u64]
```

Twelve bases cover every value below 2^64. `flushBlockBytes` is 256 KiB. The array is built at compile time, so it costs nothing at run time.

The token scanner reads digits by index.

```nim
proc nextUint(data: string, i: var int): uint64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0'u64
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10'u64 + uint64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

The scan advances `i` past separators, then over digits. `i` is a var parameter, so the position survives between calls.

The input has no negative values, so no sign branch is needed. The cost is one pass over the input bytes.

The modular product uses only 64-bit additions and shifts.

```nim
proc modMultiply(leftValue, rightValue, modulusValue: uint64): uint64 =
  var doubled = leftValue mod modulusValue
  var remaining = rightValue
  var product = 0'u64
  while remaining != 0'u64:
    if (remaining and 1'u64) != 0'u64:
      product = product + doubled
      if product >= modulusValue: product = product - modulusValue
    remaining = remaining shr 1
    doubled = doubled shl 1
    if doubled >= modulusValue: doubled = doubled - modulusValue
  return product
```

The loop runs once per bit of `rightValue`, at most 64. Each add keeps the product below the modulus. Each doubling keeps `doubled` below the modulus too.

Since the modulus is at most 2^63 - 1, twice the modulus fits in `uint64`.

Modular exponentiation applies that product in square-and-multiply order.

```nim
proc modularPower(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var factor = baseValue mod modulusValue
  var power = 1'u64
  var exponent = exponentValue
  while exponent != 0'u64:
    if (exponent and 1'u64) != 0'u64:
      power = modMultiply(power, factor, modulusValue)
    factor = modMultiply(factor, factor, modulusValue)
    exponent = exponent shr 1
  return power
```

The loop runs once per bit of `exponentValue`, at most 63. One running power accumulates the answer. The cost is at most 126 calls to `modMultiply`.

The test rejects small factors, then runs the strong witness check.

```nim
proc isPrime(candidate: uint64): bool =
  if candidate < 2'u64: return false
  for primeBase in witnessBases:
    if candidate == primeBase: return true
    if candidate mod primeBase == 0'u64: return false
  var oddPart = candidate - 1'u64
  var twosCount = 0
  while (oddPart and 1'u64) == 0'u64:
    oddPart = oddPart shr 1
    twosCount += 1
  for primeBase in witnessBases:
    var term = modularPower(primeBase, oddPart, candidate)
    if term == 1'u64 or term == candidate - 1'u64: continue
    var witnessed = false
    var roundIndex = 1
    while roundIndex < twosCount:
      term = modMultiply(term, term, candidate)
      if term == candidate - 1'u64:
        witnessed = true
        break
      roundIndex += 1
    if not witnessed: return false
  return true
```

The first loop accepts the bases themselves and rejects candidates with a small factor. The second loop tests every base. `twosCount` counts factors of two in candidate minus one.

The inner loop squares `term` until it reaches candidate minus one or runs out of rounds. The cost is at most 12 x 126 modular products per candidate.

The driver reads once and writes in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = int(nextUint(inputData, i))
var outputBuffer = ""

var caseIndex = 0
while caseIndex < caseCount:
  let candidate = nextUint(inputData, i)
  if isPrime(candidate):
    outputBuffer.add "YES\n"
  else:
    outputBuffer.add "NO\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
```

The read loop appends every line to one buffer, so spacing cannot desync the scan. `caseCount` bounds the main loop.

`outputBuffer` flushes every 256 KiB, and the final write covers the tail. The cost is one pass over input and output bytes.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Input | one pass over input bytes | input size |
| Modular product | up to 64 doubling steps | constant |
| Primality test | 12 bases x at most 126 products | constant |
| Output | one write per 256 KiB block | 256 KiB |
| Total at t = 500 | about 36 million doubling steps | input size plus 256 KiB |

The table splits the run by phase. All primality work is constant per candidate, and the input buffer is the only large allocation.

| Measure | Big O |
| --- | --- |
| Time | O(t * log^3 N), with log N at most 63 |
| Space | O(input bytes) |

The second table gives the asymptotic form. Trial division by every integer up to sqrt(N) costs about 3 billion divisions for one 64-bit prime.

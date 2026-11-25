# BBM — Billion ByteMan March (SPOJ)

<https://www.spoj.com/problems/BBM/>

## Problem

Count the set partitions of N times K distinct people into equal-sized teams, summed over every team size that divides the total, and report the count modulo 1000000007. The input supplies factorial values at spaced indices so large factorials stay cheap.

Input opens with 4096 precomputed factorials, one per line. A test count follows, then one N and K per line. Print one residue per line.

| item | bound |
|---|---|
| precomputed lines | 4096 |
| test count | 1 to 300 |
| bus count N | 1 to 30000 |
| capacity K | 1 to 30000 |
| judge limit | 5000 ms, 1536 MB |

The precomputed spacing drives the design because totals reach nine digits.

Sample input, with the long middle of the table abbreviated:

```
1
639926614
[...]
0
3
2 2
1 6
2 3
```

Sample output:

```
5
27
27
```

The trailing zero is a precomputed factorial, not a test count.

## Idea

Each precomputed factorial is a milestone, like a marker on a long road that shortens the remaining walk. To get factorial(x), start at the last milestone at or below x and multiply the remaining numbers, fewer than 262144 of them. Fermat inversion turns each divisor term into a product of factorials under the prime modulus. A direct cache covers small indices. Enumerating partitions would be factorial in the total, while this path uses one modular product per divisor.

## Why It Works

1. The team count for size d is total factorial divided by d factorial to the m and m factorial, with m = total/d.
2. The modulus 1000000007 is prime and exceeds every total, so all factorials are invertible.
3. The table stores factorial(j times 262144), and at most 262144 multiplications reach any index.
4. Modular exponentiation raises d factorial to the power m, and Fermat inversion divides by the denominator.
5. A 128-bit intermediate keeps products below the modulus from overflowing 64 bits.

| term | meaning |
|---|---|
| `precomputedFactorials` | factorial values at spaced indices |
| `factorialModulo` | factorial for any index |
| `powerMod` | fast modular exponentiation |
| `denominator` | divisor factorial power times group factorial |
| `inverseDenominator` | Fermat inverse of that denominator |

The table names the inputs and helpers used per divisor.

A script trace for four people follows:

```
total = 4
divisor 1: 24/(1^4 * 24) = 1
divisor 2: 24/(2^2 * 2) = 3
divisor 4: 24/(24 * 1) = 1
sum = 5 modulo 1000000007
```

The trace matches the first sample answer.

Indices at or beyond the prime modulus have factorial zero, and the supplied table already records that.

## Code

**Input and modular multiply.** The table and test pairs are read in one pass.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'u64
const blockStride = 262144
const directLimit = 200000

proc mulmod128(leftValue, rightValue, modulusValue: uint64): uint64 {.importc: "mulmod128_c", nodecl.}
{.emit: """
static inline unsigned long long mulmod128_c(unsigned long long leftValue, unsigned long long rightValue, unsigned long long modulusValue) {
  return (unsigned long long)(((unsigned __int128)leftValue * (unsigned __int128)rightValue) % (unsigned __int128)modulusValue);
}
""".}

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

There are 4096 table tokens before the test count.
The stride matches the spacing in the statement.
Buffered writes keep output off the hot path.

**Factorial lookup.** Small indices use a cache, large ones extend a milestone.

```nim
proc powerMod(baseValue, exponentValue: uint64): uint64 =
  var powerResult = 1'u64
  var currentBase = baseValue mod modulusValue
  var currentExponent = exponentValue
  while currentExponent > 0'u64:
    if (currentExponent and 1'u64) == 1'u64:
      powerResult = mulmod128(powerResult, currentBase, modulusValue)
    currentBase = mulmod128(currentBase, currentBase, modulusValue)
    currentExponent = currentExponent shr 1
  return powerResult

var precomputedFactorials = newSeq[uint64](4096)
for blockIndex in 0 .. 4095:
  precomputedFactorials[blockIndex] = uint64(nextInt(inputData, scanPos))
let caseCount = nextInt(inputData, scanPos)

var busCounts = newSeq[int](caseCount)
var busCapacities = newSeq[int](caseCount)
var largestSize = 0
for caseIndex in 0 .. caseCount - 1:
  busCounts[caseIndex] = nextInt(inputData, scanPos)
  busCapacities[caseIndex] = nextInt(inputData, scanPos)
  let candidateSize = busCounts[caseIndex] * busCapacities[caseIndex]
  if candidateSize > largestSize:
    largestSize = candidateSize

var directFactorials = newSeq[uint64](directLimit + 1)
directFactorials[0] = 1'u64
for numberValue in 1 .. directLimit:
  directFactorials[numberValue] = mulmod128(directFactorials[numberValue - 1], uint64(numberValue), modulusValue)

proc factorialModulo(argument: int): uint64 =
  if argument <= directLimit:
    return directFactorials[argument]
  let blockIndex = argument div blockStride
  var factorialResult = precomputedFactorials[blockIndex]
  var numberValue = blockIndex * blockStride + 1
  while numberValue <= argument:
    factorialResult = mulmod128(factorialResult, uint64(numberValue), modulusValue)
    numberValue += 1
  return factorialResult
```

The direct cache covers common small totals.
The walk never exceeds one stride.
All factors are below the prime modulus.

**Divisor sweep.** Each divisor contributes one modular term.

```nim
for caseIndex in 0 .. caseCount - 1:
  let totalSize = busCounts[caseIndex] * busCapacities[caseIndex]
  let totalFactorial = factorialModulo(totalSize)
  var answer = 0'u64
  for divisor in 1 .. totalSize:
    if totalSize mod divisor == 0:
      let groupCount = totalSize div divisor
      let divisorFactorial = factorialModulo(divisor)
      let groupFactorial = factorialModulo(groupCount)
      let denominator = mulmod128(powerMod(divisorFactorial, uint64(groupCount)),
                                  groupFactorial, modulusValue)
      let inverseDenominator = powerMod(denominator, modulusValue - 2'u64)
      let term = mulmod128(totalFactorial, inverseDenominator, modulusValue)
      answer = (answer + term) mod modulusValue
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Fermat inversion needs exponent modulus minus two.
The denominator is invertible because totals stay below the modulus.
The buffer flushes once after all cases.

## Complexity

Each case visits divisors of its total.

| phase | time | space |
|---|---|---|
| table read | 4096 token reads | factorial array |
| direct cache | one pass to the limit | 200001 residues |
| factorial lookup | up to one stride | constant extra |
| divisor sweep | one term per divisor | block buffer |

The phase table separates shared setup from per-case work.

| measure | Big O |
|---|---|
| time | O(d(n) log n + 262144) per case |
| space | O(262144) |

Listing every partition takes factorial time. Fermat inversion and milestones replace that list with one term per divisor.

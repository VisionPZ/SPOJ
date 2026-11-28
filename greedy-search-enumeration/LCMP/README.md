# LCMP — LCM Pesticide (SPOJ)

<https://www.spoj.com/problems/LCMP/>

## Problem

For each range request, report the least common multiple of the field numbers in that range after dropping every factor of one selected prime. Print the result modulo 1000000007.

Input starts with N and Q. The second line holds N field numbers from 1 to 100000. Each of the next Q lines is `0 L R` for a range request or `1 P` for changing the selected prime. P is a prime from 1 to 100000, with 1 meaning no prime is selected. The initial selection is 1.

Output holds one line per range request, in the original request order.

| item | bound |
|---|---|
| fields N | 1 to 50000 |
| events Q | 1 to 100000 |
| field values | 1 to 100000 |
| selected prime P | 1 to 100000 |
| modulus | 1000000007 |
| judge limit | 2500 ms, 1536 MB |

All field values factor into primes below 100000.

Sample input:

```
10 12
4 2 3 5 6 47 10007 32768 59049 1
0 1 5
0 2 5
1 2
0 1 5
0 2 5
0 6 10
1 3
0 6 10
1 1
0 1 10
0 10 10
0 1 5
```

The sample has twelve events and nine range requests.

Sample output:

```
60
30
15
15
772456932
411740567
342852967
1
60
```

Each output line answers one of the nine range requests.

## Idea

Keep the tallest exponent in each prime bin while a window slides, like a clerk tracking the tallest stack in every bin. The product of those tallest powers is the range LCM modulo the modulus.

The program uses Mo's algorithm. It reorders range requests so that the two window ends move a bounded total distance. A additive or removal touches only the distinct prime factors of one field, at most six. A frequency table per prime and exponent gives the current largest exponent after each change. Dropping the selected prime means dividing out its stored power.

Scanning each range from scratch would factor every field again for every request. Mo's algorithm reuses the previous window instead.

Process requests in sorted order, maintain one window, then print answers in input order.

## Why It Works

1. The LCM equals the product over primes of p raised to the largest exponent in the range.
2. Removing all factors of prime P sets only P's exponent to zero.
3. Mo's algorithm sorts requests by left block, then by right end with alternating direction.
4. Moving one window end changes at most six prime factors of one field.
5. A frequency count per prime and exponent gives the largest exponent after any change.
6. The running product is multiplied or divided by a prime power when that largest exponent changes.
7. The modulus is prime and every prime base is smaller, so modular division uses a modular inverse.

| term | meaning |
|---|---|
| `fullProduct` | product of all current largest prime powers |
| `frequencies` | count of fields holding each prime exponent |
| `maximumExponents` | current largest exponent for each prime |
| `suppressedPrime` | prime whose factors are ignored in the answer |

The running product always matches the current window after each change.

For the sample request `0 1 5`, the fields are 4, 2, 3, 5, 6. The script gives these largest powers:

| prime | largest exponent | contribution |
|---|---|---|
| 2 | 2, from 4 | 4 |
| 3 | 1, from 3 or 6 | 3 |
| 5 | 1, from 5 | 5 |

The product is 4 times 3 times 5, which is 60. After event `1 2`, prime 2 is dropped and the answer becomes 3 times 5, which is 15. Both values appear in the sample output.

Exponents fit in 16 bits because 2 to the 16th power is below 100001. Products stay in 64 bits because the modulus is below 2 to the 30th power.

## Code

**Input and helpers.** The reader loads the input, and the scanner and power helper support later stages.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxFieldValue = 100000
const maxPrimeExponent = 16

type QueryRecord = object
  leftIndex: int
  rightIndex: int
  suppressedPrime: int
  resultIndex: int

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

proc modPow(baseValue: int64, exponentValue: int64, modulusValue: int64): int64 =
  result = 1
  var current = baseValue mod modulusValue
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      result = result * current mod modulusValue
    current = current * current mod modulusValue
    remaining = remaining div 2
```

The result index keeps answers aligned with input order.

Fast exponentiation computes a prime inverse by Fermat's little theorem.

The output buffer flushes once per large block.

**Prime index table.** A sieve maps each prime value to a compact index.

```nim
var primes = newSeq[int](0)
var compositeFlags = newSeq[bool](maxFieldValue + 1)
var primeIndexByValue = newSeq[int](maxFieldValue + 1)
for primeValue in 2 .. maxFieldValue:
  primeIndexByValue[primeValue] = -1
for candidate in 2 .. maxFieldValue:
  if not compositeFlags[candidate]:
    primeIndexByValue[candidate] = primes.len
    primes.add candidate
    var multiple = candidate * 2
    while multiple <= maxFieldValue:
      compositeFlags[multiple] = true
      multiple += candidate
```

The value 1 keeps index zero but is never used as a prime base.

Non-prime values map to minus one and are skipped when suppressing.

**Field factors.** Each field is reduced to its distinct prime exponents once.

```nim
let fieldCount = nextInt(inputData, scanPos)
let eventCount = nextInt(inputData, scanPos)
var factorsByPosition = newSeq[seq[int]](fieldCount + 1)
var exponentsByPosition = newSeq[seq[int]](fieldCount + 1)
for position in 1 .. fieldCount:
  var fieldValue = nextInt(inputData, scanPos)
  var primeIndexes = newSeq[int](0)
  var primeExponents = newSeq[int](0)
  for primeValue in primes:
    if primeValue * primeValue > fieldValue:
      break
    if fieldValue mod primeValue == 0:
      var exponent = 0
      while fieldValue mod primeValue == 0:
        fieldValue = fieldValue div primeValue
        exponent += 1
      primeIndexes.add primeIndexByValue[primeValue]
      primeExponents.add exponent
  if fieldValue > 1:
    primeIndexes.add primeIndexByValue[fieldValue]
    primeExponents.add 1
  factorsByPosition[position] = primeIndexes
  exponentsByPosition[position] = primeExponents
```

Trial division stops at the square root of the remaining value.

Each position stores at most six prime indexes.

**Request collection and powers.** Each request records the prime selected at that moment.

```nim
var queries = newSeq[QueryRecord](0)
var suppressedPrime = 1
for eventIndex in 0 .. eventCount - 1:
  let eventType = nextInt(inputData, scanPos)
  if eventType == 1:
    suppressedPrime = nextInt(inputData, scanPos)
  else:
    let leftIndex = nextInt(inputData, scanPos)
    let rightIndex = nextInt(inputData, scanPos)
    queries.add QueryRecord(leftIndex: leftIndex, rightIndex: rightIndex, suppressedPrime: suppressedPrime, resultIndex: queries.len)

let primeCount = primes.len
let exponentStride = maxPrimeExponent + 1
var powerByPrime = newSeq[seq[int64]](primeCount)
var inversePowerByPrime = newSeq[seq[int64]](primeCount)
for primeIndex in 0 .. primeCount - 1:
  var powers = newSeq[int64](exponentStride)
  var inversePowers = newSeq[int64](exponentStride)
  powers[0] = 1
  inversePowers[0] = 1
  var runningPower: int64 = int64(primes[primeIndex]) mod int64(answerModulus)
  let primeInverse = modPow(int64(primes[primeIndex]), int64(answerModulus - 2), int64(answerModulus))
  var runningInverse: int64 = 1
  for exponent in 1 .. maxPrimeExponent:
    powers[exponent] = runningPower
    runningInverse = runningInverse * primeInverse mod int64(answerModulus)
    inversePowers[exponent] = runningInverse
    runningPower = runningPower * int64(primes[primeIndex]) mod int64(answerModulus)
  powerByPrime[primeIndex] = powers
  inversePowerByPrime[primeIndex] = inversePowers
```

A request keeps its own selected prime because events are processed in order.

Prime powers and their inverses are precomputed for every possible exponent.

**Mo ordering.** Requests are sorted to keep both window ends moving slowly.

```nim
var moBlockSize = 1
while moBlockSize * moBlockSize < fieldCount:
  moBlockSize += 1

proc compareQueries(leftQuery, rightQuery: QueryRecord): int =
  let leftBlock = leftQuery.leftIndex div moBlockSize
  let rightBlock = rightQuery.leftIndex div moBlockSize
  if leftBlock != rightBlock:
    return leftBlock - rightBlock
  if leftBlock mod 2 == 0:
    return leftQuery.rightIndex - rightQuery.rightIndex
  return rightQuery.rightIndex - leftQuery.rightIndex

sort(queries, compareQueries)
```

The block size is the integer square root of the field count.

Alternating right-direction order avoids repeated long jumps.

**Window updates.** Adding and removing a field change only its prime factors.

```nim
var frequencies = newSeq[int](primeCount * exponentStride)
var maximumExponents = newSeq[int](primeCount)
var fullProduct: int64 = 1

proc addPosition(position: int) =
  for factorIndex in 0 .. factorsByPosition[position].len - 1:
    let primeIndex = factorsByPosition[position][factorIndex]
    let exponent = exponentsByPosition[position][factorIndex]
    let slot = primeIndex * exponentStride + exponent
    frequencies[slot] += 1
    if exponent > maximumExponents[primeIndex]:
      let previousMaximum = maximumExponents[primeIndex]
      fullProduct = fullProduct * powerByPrime[primeIndex][exponent] mod int64(answerModulus)
      if previousMaximum > 0:
        fullProduct = fullProduct * inversePowerByPrime[primeIndex][previousMaximum] mod int64(answerModulus)
      maximumExponents[primeIndex] = exponent

proc removePosition(position: int) =
  for factorIndex in 0 .. factorsByPosition[position].len - 1:
    let primeIndex = factorsByPosition[position][factorIndex]
    let exponent = exponentsByPosition[position][factorIndex]
    let slot = primeIndex * exponentStride + exponent
    frequencies[slot] -= 1
    if exponent == maximumExponents[primeIndex] and frequencies[slot] == 0:
      var newMaximum = exponent - 1
      while newMaximum > 0 and frequencies[primeIndex * exponentStride + newMaximum] == 0:
        newMaximum -= 1
      fullProduct = fullProduct * inversePowerByPrime[primeIndex][exponent] mod int64(answerModulus)
      if newMaximum > 0:
        fullProduct = fullProduct * powerByPrime[primeIndex][newMaximum] mod int64(answerModulus)
      maximumExponents[primeIndex] = newMaximum
```

The product changes only when the largest exponent changes.

Removing a top exponent searches downward for the next occupied level.

**Request driver.** The window moves toward each sorted request and records its answer.

```nim
var answers = newSeq[int64](queries.len)
var currentLeft = 1
var currentRight = 0
for queryIndex in 0 .. queries.len - 1:
  let currentQuery = queries[queryIndex]
  while currentLeft > currentQuery.leftIndex:
    currentLeft -= 1
    addPosition(currentLeft)
  while currentRight < currentQuery.rightIndex:
    currentRight += 1
    addPosition(currentRight)
  while currentLeft < currentQuery.leftIndex:
    removePosition(currentLeft)
    currentLeft += 1
  while currentRight > currentQuery.rightIndex:
    removePosition(currentRight)
    currentRight -= 1
  var answer = fullProduct
  if currentQuery.suppressedPrime != 1:
    let primeIndex = primeIndexByValue[currentQuery.suppressedPrime]
    if primeIndex >= 0:
      answer = answer * inversePowerByPrime[primeIndex][maximumExponents[primeIndex]] mod int64(answerModulus)
  answers[currentQuery.resultIndex] = answer

for answerIndex in 0 .. answers.len - 1:
  appendOutput($answers[answerIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The selected prime is divided out at answer time, not during window moves.

Storing by result index restores the order required by the output contract.

## Complexity

Factorization and prime powers are prepared before any window move.

| phase | time | space |
|---|---|---|
| sieve | one pass up to 100000 | flag and index arrays |
| field factors | trial division per field | up to six factors per field |
| request sorting | Q log Q comparisons | Q request records |
| window moves | O((N+Q) times square root N) moves | prime exponent counts |
| output | one line per request | output buffer |

Each window move touches at most six prime factors.

| measure | Big O |
|---|---|
| preprocessing | O(100000 log log 100000 + N log 100000) |
| request handling | O((N + Q) sqrt N times 6) |
| space | O(N + Q + 100000 times 16) |

The factor count per field is the small constant six.

Refactoring every field for every request would cost O(Q times N) factor work.

Mo's algorithm reuses one window and keeps the total movement close to linear in the input size.

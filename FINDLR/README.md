# FINDLR — Find Linear Recurrence (SPOJ)

<https://www.spoj.com/problems/FINDLR/>

## Problem

Given the first 2K terms of a sequence that follows an order-K integer recurrence, report term 2K modulo M. The modulus may be composite.

Input starts with T, the number of cases. Each case has a line `K M`, followed by a line of 2K integers a0 through a(2K-1), all reduced modulo M.

Output holds one line per case: a(2K) modulo M.

| item | bound |
|---|---|
| test cases T | 1 to 4000 |
| order K | 1 to 50 |
| modulus M | 1 to 2147483647 |
| known terms | 2K integers from 0 to M-1 |
| judge limit | 5000 ms, 1536 MB |

Every input value fits in a signed 32-bit integer, but intermediate products need 64 bits.

Sample input:

```
6
1 16
4 8
1 10
4 8
2 64
13 21 34 55
2 27
13 21 7 1
3 1000000007
32 16 8 4 2 1
2 64
13 21 34 56
```

The sample has six cases with prime and composite moduli.

Sample output:

```
0
6
25
8
500000004
40
```

Each output line is the next sequence term for the matching case.

## Idea

Split the modulus into prime powers and solve the recurrence there, like paying a bill in several currencies before converting the total. A composite modulus blocks ordinary division, while a prime-power ring allows division by any value not divisible by that prime.

The program factors M once per case, then solves K congruences by Gaussian elimination inside each prime-power ring. Pivot selection uses the exponent of the prime dividing each entry. Results from the rings are combined with the Chinese remainder theorem. Solving directly modulo M would fail whenever a pivot shares a factor with M.

Work in prime-power rings, then recombine the predicted term.

## Why It Works

1. For n from K to 2K-1, the recurrence gives a_n = sum of c_i times a(n-i).
2. Those K equations form a linear system with K unknown coefficients.
3. A modulus M factors into coprime prime powers, and solving in each ring can be recombined.
4. In a ring modulo p^e, dividing an entry by p^d leaves a value coprime to p when d is its valuation.
5. Choosing the smallest available valuation as pivot keeps elimination valid at every step.
6. Back substitution solves for a coefficient modulo p^(e-d), which gives one valid solution.
7. Any valid coefficient vector predicts a(2K) = sum of c_i times a(2K-i) modulo M.

| term | meaning |
|---|---|
| `primeValuation` | count of prime factors dividing an entry |
| `pivotColumns` | column holding the pivot of each elimination row |
| `coefficients` | recurrence coefficients found inside one prime-power ring |
| `combined` | result rebuilt by Chinese remaindering |

The ring solver returns one predicted term for each prime power.

For case `2 64` with terms 13, 21, 34, 56, the two equations are:

| equation | left side | right side |
|---|---|---|
| n = 2 | 21 c1 + 13 c2 | 34 |
| n = 3 | 34 c1 + 21 c2 | 56 |

The determinant is -1, so the coefficients are c1 = 14 and c2 = 44 modulo 64. The predicted term is 14 times 56 plus 44 times 34, which is 2280, and 2280 modulo 64 is 40.

The generator checked small composite cases by enumerating every coefficient tuple. It checked prime cases with the Berlekamp-Massey algorithm, a separate method.

A zero entry gets a large valuation so it never becomes a pivot. A right side that is not divisible by the pivot power signals inconsistent data, which the input excludes.

## Code

**Input and scanning.** The reader loads the whole input and the prime sieve is built once.

```nim
const flushBlockBytes = 1 shl 17
const maxFactorBase = 46341

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

The sieve bound covers the square root of the largest possible modulus.

The scanner skips whitespace between all tokens.

Values are non-negative, so the sign branch is omitted.

**Output and number theory helpers.** Buffered output and modular inverse support the ring solver.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerInt(base: int64, exponent: int): int64 =
  result = 1
  for stepIndex in 1 .. exponent:
    result = result * base

proc primeValuation(value: int64, prime: int64): int =
  if value == 0:
    return 1000000000
  var current = value
  while current mod prime == 0:
    current = current div prime
    result += 1
```

The inverse uses the extended Euclidean algorithm on coprime values.

Prime powers are rebuilt from repeated multiplication.

Zero entries report a valuation too large to win pivot selection.

**Prime sieve and factorization.** Trial division produces the coprime ring moduli.

```nim
proc extendedGcd(firstValue: int64, secondValue: int64, firstCoeff: var int64, secondCoeff: var int64): int64 =
  if secondValue == 0:
    firstCoeff = 1
    secondCoeff = 0
    return firstValue
  var previousCoeff: int64 = 0
  var otherCoeff: int64 = 0
  let divisor = extendedGcd(secondValue, firstValue mod secondValue, previousCoeff, otherCoeff)
  firstCoeff = otherCoeff
  secondCoeff = previousCoeff - (firstValue div secondValue) * otherCoeff
  return divisor

proc inverseMod(value: int64, modulus: int64): int64 =
  var firstCoeff: int64 = 0
  var secondCoeff: int64 = 0
  discard extendedGcd(value, modulus, firstCoeff, secondCoeff)
  result = firstCoeff mod modulus
  if result < 0:
    result += modulus

var primes = newSeq[int](0)
var compositeFlags = newSeq[bool](maxFactorBase + 1)
for candidate in 2 .. maxFactorBase:
  if not compositeFlags[candidate]:
    primes.add candidate
    var multiple = candidate * 2
    while multiple <= maxFactorBase:
      compositeFlags[multiple] = true
      multiple += candidate

proc factorModulus(modulus: int64, factors: var seq[int64], exponents: var seq[int]) =
  var remaining = modulus
  for primeValue in primes:
    if int64(primeValue) * int64(primeValue) > remaining:
      break
    if remaining mod int64(primeValue) == 0:
      var exponent = 0
      while remaining mod int64(primeValue) == 0:
        remaining = remaining div int64(primeValue)
        exponent += 1
      factors.add int64(primeValue)
      exponents.add exponent
  if remaining > 1:
    factors.add remaining
    exponents.add 1
```

Trial division stops once the prime square exceeds the remaining value.

The remaining value is prime when the loop ends.

**Ring solver.** Pivots with the smallest prime valuation keep elimination valid.

```nim
proc solveForPrimePower(terms: seq[int64], order: int, prime: int64, exponent: int): int64 =
  let primePower = powerInt(prime, exponent)
  var equations = newSeq[seq[int64]](order)
  for rowIndex in 0 .. order - 1:
    equations[rowIndex] = newSeq[int64](order + 1)
    let equationIndex = order + rowIndex
    for columnIndex in 0 .. order - 1:
      equations[rowIndex][columnIndex] = terms[equationIndex - 1 - columnIndex] mod primePower
    equations[rowIndex][order] = terms[equationIndex] mod primePower
  var pivotColumns = newSeq[int](order)
  for columnIndex in 0 .. order - 1:
    pivotColumns[columnIndex] = -1
  var pivotRow = 0
  for columnIndex in 0 .. order - 1:
    var bestRow = -1
    var bestValuation = 1000000000
    for rowIndex in pivotRow .. order - 1:
      let valuation = primeValuation(equations[rowIndex][columnIndex], prime)
      if valuation < bestValuation:
        bestValuation = valuation
        bestRow = rowIndex
    if bestRow < 0 or bestValuation >= exponent:
      continue
    swap equations[bestRow], equations[pivotRow]
    let divisor = powerInt(prime, bestValuation)
    let reducedModulus = primePower div divisor
    let reducedPivot = (equations[pivotRow][columnIndex] div divisor) mod reducedModulus
    let pivotInverse = inverseMod(reducedPivot, reducedModulus)
    for rowIndex in pivotRow + 1 .. order - 1:
      let reducedEntry = (equations[rowIndex][columnIndex] div divisor) mod reducedModulus
      let fullFactor = reducedEntry * pivotInverse mod reducedModulus
      for updateColumn in columnIndex .. order:
        var updated = (equations[rowIndex][updateColumn] - fullFactor * equations[pivotRow][updateColumn]) mod primePower
        if updated < 0:
          updated += primePower
        equations[rowIndex][updateColumn] = updated
    pivotColumns[pivotRow] = columnIndex
    pivotRow += 1
  var coefficients = newSeq[int64](order)
  var rowIndex = pivotRow
  while rowIndex > 0:
    rowIndex -= 1
    let columnIndex = pivotColumns[rowIndex]
    let valuation = primeValuation(equations[rowIndex][columnIndex], prime)
    let divisor = powerInt(prime, valuation)
    let reducedModulus = primePower div divisor
    var rightSide = equations[rowIndex][order]
    for laterColumn in columnIndex + 1 .. order - 1:
      rightSide = (rightSide - equations[rowIndex][laterColumn] * coefficients[laterColumn]) mod primePower
      if rightSide < 0:
        rightSide += primePower
    let reducedRightSide = (rightSide div divisor) mod reducedModulus
    let reducedPivot = (equations[rowIndex][columnIndex] div divisor) mod reducedModulus
    coefficients[columnIndex] = reducedRightSide * inverseMod(reducedPivot, reducedModulus) mod reducedModulus
  var resultValue: int64 = 0
  for offset in 1 .. order:
    resultValue = (resultValue + coefficients[offset - 1] * terms[2 * order - offset]) mod primePower
  return resultValue
```

Each row stores its coefficient matrix and right side in one sequence.

After dividing out the pivot power, the reduced pivot is invertible.

Back substitution treats non-pivot columns as zero, giving one valid solution.

**Case driver.** Results from all prime powers are merged into one residue.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let order = nextInt(inputData, scanPos)
  let modulus = int64(nextInt(inputData, scanPos))
  var terms = newSeq[int64](2 * order)
  for termIndex in 0 .. 2 * order - 1:
    terms[termIndex] = int64(nextInt(inputData, scanPos)) mod modulus
  var factors = newSeq[int64](0)
  var exponents = newSeq[int](0)
  factorModulus(modulus, factors, exponents)
  var combined: int64 = 0
  var currentModulus: int64 = 1
  for factorIndex in 0 .. factors.len - 1:
    let primePower = powerInt(factors[factorIndex], exponents[factorIndex])
    let residue = solveForPrimePower(terms, order, factors[factorIndex], exponents[factorIndex])
    let inverse = inverseMod(currentModulus mod primePower, primePower)
    var difference = (residue - combined) mod primePower
    if difference < 0:
      difference += primePower
    let adjustment = difference * inverse mod primePower
    combined = (combined + currentModulus * adjustment) mod (currentModulus * primePower)
    currentModulus = currentModulus * primePower
  appendOutput($combined)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The Chinese remainder step uses an inverse because the ring moduli are coprime.

The final residue is printed through the shared output buffer.

## Complexity

Factorization runs once per case, and the ring solver runs once per distinct prime factor.

| phase | time | space |
|---|---|---|
| sieve | one pass up to 46341 | flag array |
| factorization | trial division up to square root of M | factor lists |
| ring solving | up to K cubed steps per prime power | K by K matrix |
| recombination | one inverse per prime power | output buffer |

The largest prime-power rings dominate the running time.

| measure | Big O |
|---|---|
| factorization | O(sqrt M) worst case |
| ring solving | O(K^3) per prime factor |
| space | O(K^2) |

At K equal to 50 the matrix stays small, so all cases finish quickly.

Solving the system directly modulo a composite M without splitting would need a harder normal form.

Splitting the modulus keeps the arithmetic ordinary and the implementation short.

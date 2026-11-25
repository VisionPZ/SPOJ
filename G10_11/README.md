# G10_11 — Monkeys (SPOJ)

<https://www.spoj.com/problems/G10_11/>

## Problem

Two monkeys cross a grid from the top-left cell to the bottom-right cell.
Every move goes down or right. They may share only the start and the finish.
Some cells hold one banana, and each monkey eats every banana it visits.
Count route pairs whose two banana totals sum to at most D.
Print the count modulo MOD for every test case.

The dimensions reach one hundred thousand. The banana count reaches two hundred.

| Item | Bound |
|---|---|
| Test cases | given by T |
| Rows and columns | 2 to 100000 |
| Banana cells C | 0 to min(200, N*M-2) |
| Banana limit D | 0 to C |
| Modulus MOD | 1 to 1000000000 |
| Judge limit | 1000 ms |

The small banana count, not the huge grid, drives the design.

Sample input:

```
4
2 3 0 0 10
2 3 1 0 16
2 1
3 3 1 0 7
2 2
2 2 2 1 11
1 2
2 1
```

Sample output:

```
1
0
1
0
```

## Idea

Picture the two monkeys as runners on one staircase of diagonals.
They start together, split on the first step, and meet at the finish.
The split puts one runner on row one and the other on column one.
Their inner routes stay in two lanes, like traffic on a divided road.

Each inner route becomes a polynomial in x.
The coefficient of x^k counts routes eating k bananas.
A two by two determinant counts disjoint lane pairs by the LGV rule.
Only banana cells between the forced endpoints need attention.

Binomial values use factorials stripped of MOD's prime factors.
That trick gives exact remainders even when MOD is composite.

## Why It Works

1. A monotone route visits cells in increasing row plus column order.
2. Peeling off the first and last steps leaves two inner routes.
3. Crossing endpoints force a meeting, so the determinant keeps one pairing.
4. A polynomial coefficient records the banana total of one inner route.
5. Multiply and subtract those polynomials, then sum coefficients up to D.

| Term | Meaning |
|---|---|
| `pathPolynomial` | coefficient list for routes between two forced cells |
| `pairFree` | routes between banana cells that skip other bananas |
| `binomialCount` | binomial coefficient modulo an arbitrary MOD |
| `determinant` | signed polynomial sum for disjoint inner routes |

Forced first and last cells add a fixed banana count before the final sum.

Script-generated example from `gen.py`:

```
2x3 1
3x3 center 1
2x2 two bananas 0
```

The third line shows why two bananas break a limit of one.

## Code

**Input and output plumbing.** This block reads all bytes and scans numbers.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = int64(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner advances one index and never splits the input.
The buffer flushes after 128 KiB of text.
A final write clears any remaining bytes.

**Binomial arithmetic.** This block handles any modulus, prime or not.

```nim
proc modularInverse(value: int64, base: int64): int64 =
  var olderRemainder = value
  var remainder = base
  var olderCoefficient = int64(1)
  var coefficient = int64(0)
  while remainder != 0:
    let quotient = olderRemainder div remainder
    let nextRemainder = olderRemainder - quotient * remainder
    olderRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = olderCoefficient - quotient * coefficient
    olderCoefficient = coefficient
    coefficient = nextCoefficient
  var inverseValue = olderCoefficient mod base
  if inverseValue < 0: inverseValue += base
  return inverseValue

var currentModulus = int64(1)
var primeFactors = newSeq[int64]()
var strippedFactorial = newSeq[int64]()
var strippedInverse = newSeq[int64]()
var exponentPrefix = newSeq[seq[int]]()
var primePowers = newSeq[seq[int64]]()

proc binomialCount(steps: int, downs: int): int64 =
  if downs < 0 or downs > steps: return 0
  var product = (strippedFactorial[steps] * strippedInverse[downs]) mod currentModulus
  product = (product * strippedInverse[steps - downs]) mod currentModulus
  for factorIndex in 0..<primeFactors.len:
    let exponent = exponentPrefix[factorIndex][steps] -
                   exponentPrefix[factorIndex][downs] -
                   exponentPrefix[factorIndex][steps - downs]
    product = (product * primePowers[factorIndex][exponent]) mod currentModulus
  return product

proc normalize(value: int64): int64 =
  var remainderValue = value mod currentModulus
  if remainderValue < 0: remainderValue += currentModulus
  return remainderValue
```

Each prime factor of MOD is removed from every factorial term.
The removed exponents return as prime powers at the end.
An extended Euclidean inverse divides the coprime remainder.

**Banana route polynomial.** This block counts routes by banana total.

```nim
var bananaX = newSeq[int]()
var bananaY = newSeq[int]()
var pairTotal = newSeq[seq[int64]]()
var pairFree = newSeq[seq[int64]]()
var maxBananaDegree = 0

proc pathPolynomial(sourceX: int, sourceY: int, destX: int, destY: int): seq[int64] =
  var polynomial = newSeq[int64](maxBananaDegree + 1)
  if sourceX > destX or sourceY > destY:
    return polynomial
  if sourceX == destX and sourceY == destY:
    polynomial[0] = 1
    return polynomial

  var relevant = newSeq[int]()
  for index in 0..<bananaX.len:
    let cellX = bananaX[index]
    let cellY = bananaY[index]
    if cellX < sourceX or cellX > destX or cellY < sourceY or cellY > destY:
      continue
    if cellX == sourceX and cellY == sourceY: continue
    if cellX == destX and cellY == destY: continue
    relevant.add index

  var sourceFree = newSeq[int64](bananaX.len)
  for position in 0..<relevant.len:
    let cell = relevant[position]
    let across = bananaX[cell] - sourceX
    let downward = bananaY[cell] - sourceY
    var value = binomialCount(across + downward, across)
    for earlier in 0..<position:
      let previous = relevant[earlier]
      if bananaX[previous] <= bananaX[cell] and bananaY[previous] <= bananaY[cell]:
        let product = (sourceFree[previous] * pairTotal[previous][cell]) mod currentModulus
        value = normalize(value - product)
    sourceFree[cell] = value

  var destFree = newSeq[int64](bananaX.len)
  var reversePosition = relevant.len
  while reversePosition > 0:
    reversePosition -= 1
    let cell = relevant[reversePosition]
    let across = destX - bananaX[cell]
    let downward = destY - bananaY[cell]
    var value = binomialCount(across + downward, across)
    for later in reversePosition+1..<relevant.len:
      let following = relevant[later]
      if bananaX[cell] <= bananaX[following] and bananaY[cell] <= bananaY[following]:
        let across = destX - bananaX[following]
        let downward = destY - bananaY[following]
        let tailWays = binomialCount(across + downward, across)
        let product = (pairFree[cell][following] * tailWays) mod currentModulus
        value = normalize(value - product)
    destFree[cell] = value

  var polynomialDp = newSeq[seq[int64]](bananaX.len)
  for index in 0..<bananaX.len:
    polynomialDp[index] = newSeq[int64](maxBananaDegree + 1)
  for position in 0..<relevant.len:
    let cell = relevant[position]
    if maxBananaDegree >= 1:
      polynomialDp[cell][1] = sourceFree[cell]
    if maxBananaDegree >= 2:
      for eaten in 2..maxBananaDegree:
        var accumulated = int64(0)
        for earlier in 0..<position:
          let previous = relevant[earlier]
          if bananaX[previous] <= bananaX[cell] and bananaY[previous] <= bananaY[cell]:
            let product = (polynomialDp[previous][eaten-1] * pairFree[previous][cell]) mod currentModulus
            accumulated = (accumulated + product) mod currentModulus
        polynomialDp[cell][eaten] = accumulated

  let totalAcross = destX - sourceX
  let totalDown = destY - sourceY
  var plainWays = binomialCount(totalAcross + totalDown, totalAcross)
  for cell in relevant:
    let across = destX - bananaX[cell]
    let downward = destY - bananaY[cell]
    let product = (sourceFree[cell] * binomialCount(across + downward, across)) mod currentModulus
    plainWays = normalize(plainWays - product)
  polynomial[0] = plainWays
  if maxBananaDegree >= 1:
    for eaten in 1..maxBananaDegree:
      var accumulated = int64(0)
      for cell in relevant:
        let product = (polynomialDp[cell][eaten] * destFree[cell]) mod currentModulus
        accumulated = (accumulated + product) mod currentModulus
      polynomial[eaten] = accumulated
  return polynomial
```

`pairFree` subtracts routes that meet an earlier banana first.
The same subtraction builds source and destination coefficients.
A small convolution records the number of eaten bananas.

**Test case loop.** This block assembles the four polynomials and the answer.

```nim
let testCount = int(nextNumber(inputData, scanPos))
for caseIndex in 0..<testCount:
  let rowCount = int(nextNumber(inputData, scanPos))
  let columnCount = int(nextNumber(inputData, scanPos))
  let bananaCount = int(nextNumber(inputData, scanPos))
  let bananaLimit = int(nextNumber(inputData, scanPos))
  currentModulus = nextNumber(inputData, scanPos)

  bananaX = newSeq[int](bananaCount)
  bananaY = newSeq[int](bananaCount)
  for index in 0..<bananaCount:
    bananaX[index] = int(nextNumber(inputData, scanPos))
    bananaY[index] = int(nextNumber(inputData, scanPos))
  for outer in 1..<bananaCount:
    let heldX = bananaX[outer]
    let heldY = bananaY[outer]
    var inner = outer - 1
    while inner >= 0 and (bananaX[inner] + bananaY[inner] > heldX + heldY or
                          (bananaX[inner] + bananaY[inner] == heldX + heldY and bananaX[inner] > heldX)):
      bananaX[inner+1] = bananaX[inner]
      bananaY[inner+1] = bananaY[inner]
      inner -= 1
    bananaX[inner+1] = heldX
    bananaY[inner+1] = heldY

  if currentModulus <= 1:
    appendOutput("0\n")
    continue

  maxBananaDegree = bananaLimit
  if maxBananaDegree > bananaCount: maxBananaDegree = bananaCount

  primeFactors = newSeq[int64]()
  var residual = currentModulus
  var trial = int64(2)
  while trial <= residual div trial:
    if residual mod trial == 0:
      primeFactors.add trial
      while residual mod trial == 0:
        residual = residual div trial
    if trial == 2: trial = 3 else: trial += 2
  if residual > 1: primeFactors.add residual

  let highestStep = rowCount + columnCount + 2
  strippedFactorial = newSeq[int64](highestStep + 1)
  strippedInverse = newSeq[int64](highestStep + 1)
  exponentPrefix = newSeq[seq[int]]()
  primePowers = newSeq[seq[int64]]()
  for factorIndex in 0..<primeFactors.len:
    exponentPrefix.add newSeq[int](highestStep + 1)
    primePowers.add newSeq[int64](highestStep + 1)
    primePowers[factorIndex][0] = 1
    for exponent in 1..highestStep:
      primePowers[factorIndex][exponent] =
        (primePowers[factorIndex][exponent-1] * primeFactors[factorIndex]) mod currentModulus
  strippedFactorial[0] = 1
  for step in 1..highestStep:
    var leftover = int64(step)
    for factorIndex in 0..<primeFactors.len:
      let prime = primeFactors[factorIndex]
      var exponent = 0
      while leftover mod prime == 0:
        leftover = leftover div prime
        exponent += 1
      exponentPrefix[factorIndex][step] = exponentPrefix[factorIndex][step-1] + exponent
    strippedFactorial[step] = (strippedFactorial[step-1] * (leftover mod currentModulus)) mod currentModulus
  for step in 0..highestStep:
    strippedInverse[step] = modularInverse(strippedFactorial[step], currentModulus)

  pairTotal = newSeq[seq[int64]](bananaCount)
  pairFree = newSeq[seq[int64]](bananaCount)
  for row in 0..<bananaCount:
    pairTotal[row] = newSeq[int64](bananaCount)
    pairFree[row] = newSeq[int64](bananaCount)
  for destination in 0..<bananaCount:
    for source in 0..destination:
      if bananaX[source] <= bananaX[destination] and bananaY[source] <= bananaY[destination]:
        let across = bananaX[destination] - bananaX[source]
        let downward = bananaY[destination] - bananaY[source]
        pairTotal[source][destination] = binomialCount(across + downward, across)
  for destination in 0..<bananaCount:
    for source in 0..<destination:
      if bananaX[source] <= bananaX[destination] and bananaY[source] <= bananaY[destination]:
        var value = pairTotal[source][destination]
        for between in source+1..<destination:
          if bananaX[source] <= bananaX[between] and bananaY[source] <= bananaY[between] and
             bananaX[between] <= bananaX[destination] and bananaY[between] <= bananaY[destination]:
            let product = (pairFree[source][between] * pairTotal[between][destination]) mod currentModulus
            value = normalize(value - product)
        pairFree[source][destination] = value

  proc hasBananaAt(cellX: int, cellY: int): bool =
    for index in 0..<bananaCount:
      if bananaX[index] == cellX and bananaY[index] == cellY: return true
    return false

  let forcedX = [1, 2, rowCount-1, rowCount]
  let forcedY = [2, 1, columnCount, columnCount-1]
  var forcedBananas = 0
  for position in 0..3:
    var alreadyCounted = false
    for previous in 0..<position:
      if forcedX[previous] == forcedX[position] and forcedY[previous] == forcedY[position]:
        alreadyCounted = true
    if not alreadyCounted and hasBananaAt(forcedX[position], forcedY[position]):
      forcedBananas += 1

  let upperStartX = 1
  let upperStartY = 2
  let lowerStartX = 2
  let lowerStartY = 1
  let upperEndX = rowCount - 1
  let upperEndY = columnCount
  let lowerEndX = rowCount
  let lowerEndY = columnCount - 1

  let firstFirst = pathPolynomial(upperStartX, upperStartY, upperEndX, upperEndY)
  let firstSecond = pathPolynomial(upperStartX, upperStartY, lowerEndX, lowerEndY)
  let secondFirst = pathPolynomial(lowerStartX, lowerStartY, upperEndX, upperEndY)
  let secondSecond = pathPolynomial(lowerStartX, lowerStartY, lowerEndX, lowerEndY)

  var determinant = newSeq[int64](maxBananaDegree + 1)
  for eaten in 0..maxBananaDegree:
    var signed = int64(0)
    for part in 0..eaten:
      let direct = (firstFirst[part] * secondSecond[eaten-part]) mod currentModulus
      let crossed = (firstSecond[part] * secondFirst[eaten-part]) mod currentModulus
      signed = normalize(signed + direct - crossed)
    determinant[eaten] = signed

  var answer = int64(0)
  if forcedBananas <= bananaLimit:
    for eaten in 0..(bananaLimit - forcedBananas):
      answer = (answer + determinant[eaten]) mod currentModulus
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Bananas at forced cells are counted once, even when positions coincide.
The determinant subtracts the crossing pairing.
Only coefficients within the remaining banana limit are summed.

## Complexity

The work concentrates in banana pairs, not grid cells.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Binomial setup | O((N+M) * w) | O((N+M) * w) |
| Banana pairs | O(C^3 + C^2 * D) | O(C^2 + C*D) |
| Output | one write per 128 KiB block | block buffer |

Here w is the count of distinct prime factors of MOD.

| Measure | Big O |
|---|---|
| Time | O((N+M)*w + C^3 + C^2*D) per case |
| Space | O((N+M)*w + C*D) |

Enumerating all route pairs costs O(C(N+M,N)^2), which is hopeless here.
The banana-first DP replaces that explosion with a few hundred states.

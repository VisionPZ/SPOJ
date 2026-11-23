# IMP — The Imp (SPOJ)

<https://www.spoj.com/problems/IMP/>

## Problem

An Imp starts at the origin of an infinite chessboard. A move adds or subtracts one of two vectors, (a, b) or (c, d). Read ten cases, each holding the four components. Print the smallest |x| + |y| over all reachable squares except the origin.

| item | bound |
|---|---|
| test cases | 10 |
| each component | -100000 to 100000 |
| each move vector | nonzero |
| search radius | at most 200000 |
| judge limits | 3 s, 1536 MB |

Either move vector is reachable in one step, so the answer never exceeds 200000.

## Idea

Reachable squares form a lattice: all integer combinations of the two move vectors. The program fixes the horizontal coordinate, then finds the smallest vertical coordinate that reaches the same lattice. At most 400001 horizontal values need checking, and each costs one modulo operation.

## Why It Works

First, each move adds or subtracts a whole vector. Every reachable square equals m times the first vector plus n times the second, for integers m and n.

Second, the reachable horizontal coordinates are multiples of gcdX, the gcd of the two horizontal components. Write x as gcdX times an integer index.

Bezout coefficients give one vertical coordinate for that index. Every other vertical coordinate differs by a multiple of stepSize, the determinant divided by gcdX.

| term | meaning |
|---|---|
| gcdX | gcd of the two horizontal components |
| index | number of gcdX steps in x |
| stepY | one vertical coordinate for index equal to one |
| stepSize | gap between vertical coordinates at fixed x |
| searchRadius | bound on |x| from the one-move answers |

The gap table explains which value drives each part of the scan.

Third, the residue of index times stepY gives the closest vertical coordinate. The smaller of that residue and its complement gives the smallest |y|. At index zero the closest point is the origin, so the program uses the first nonzero gap instead.

The sample vectors 13 4 and 17 5 give gcdX = 1, stepY = 1 and stepSize = 3. The scan visits these indices:

| index | x | y residue | smallest |y| | |x| + |y| |
|---|---|---|---|---|
| -3 | -3 | 0 | 0 | 3 |
| -2 | -2 | 1 | 1 | 3 |
| -1 | -1 | 2 | 1 | 2 |
| 0 | 0 | 0 (origin) | 3 | 3 |
| 1 | 1 | 1 | 1 | 2 |
| 2 | 2 | 2 | 1 | 3 |
| 3 | 3 | 0 | 0 | 3 |

The smallest total is 2, which matches the sample output.

When the determinant is zero, the two vectors point along one line. Then stepSize is zero and each vertical coordinate is unique, which the scan handles directly. When both horizontal components are zero, the answer is the gcd of the vertical components.

## Code

**Scanner.** It reads one buffer and skips separator bytes by index. The sign branch keeps negative components intact.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextSigned(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos = scanPos + 1
  elif scanPos < inputData.len and inputData[scanPos] == '+':
    scanPos = scanPos + 1
  var value = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos = scanPos + 1
  return signValue * value
```

The scanner walks at most one byte per input character. It builds no token and allocates nothing.

**Bezout coefficients.** These solve the first-coordinate equation once per case.

```nim
proc bezoutCoefficients(firstValue, secondValue: int64): tuple[gcdValue, firstCoef, secondCoef: int64] =
  var oldRemainder = firstValue
  var remainder = secondValue
  var oldFirstCoef = 1'i64
  var firstCoef = 0'i64
  var oldSecondCoef = 0'i64
  var secondCoef = 1'i64
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextFirstCoef = oldFirstCoef - quotient * firstCoef
    oldFirstCoef = firstCoef
    firstCoef = nextFirstCoef
    let nextSecondCoef = oldSecondCoef - quotient * secondCoef
    oldSecondCoef = secondCoef
    secondCoef = nextSecondCoef
  return (oldRemainder, oldFirstCoef, oldSecondCoef)
```

The loop runs once per division step, at most O(log 100000). Its output lets the scan start from an exact solution instead of testing candidates.

**Lattice scan.** This block turns one case into one answer.

```nim
proc shortestDistance(firstX, firstY, secondX, secondY: int64): int64 =
  let absFirstX = abs(firstX)
  let absFirstY = abs(firstY)
  let absSecondX = abs(secondX)
  let absSecondY = abs(secondY)
  let searchRadius = min(absFirstX + absFirstY, absSecondX + absSecondY)
  let gcdX = gcd(absFirstX, absSecondX)
  if gcdX == 0:
    return gcd(absFirstY, absSecondY)
  var coefficients = bezoutCoefficients(absFirstX, absSecondX)
  var coefFirst = coefficients.firstCoef
  var coefSecond = coefficients.secondCoef
  if firstX < 0:
    coefFirst = -coefFirst
  if secondX < 0:
    coefSecond = -coefSecond
  let stepY = coefFirst * firstY + coefSecond * secondY
  let determinant = firstX * secondY - firstY * secondX
  let stepSize = abs(determinant div gcdX)
  var bestValue = searchRadius
  if stepSize > 0:
    bestValue = min(bestValue, stepSize)
  let maxIndex = searchRadius div gcdX
  var index = -maxIndex
  while index <= maxIndex:
    if index != 0:
      var distance: int64
      if stepSize == 0:
        distance = abs(index * stepY)
      else:
        var residue = (index * stepY) mod stepSize
        if residue < 0:
          residue = residue + stepSize
        distance = min(residue, stepSize - residue)
      let candidate = abs(gcdX * index) + distance
      if candidate < bestValue:
        bestValue = candidate
    index = index + 1
  return bestValue
```

The bound `maxIndex` is searchRadius divided by gcdX, so the loop runs at most 400001 times. Skipping index zero avoids reporting the origin, and the sign fix handles negative components. The scan costs one modulo and one comparison per index.

**Driver.** It reads the whole stream, then writes one line per case in blocks.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0
var outputBuffer: string
while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1
  if scanPos >= inputData.len:
    break
  let firstX = nextSigned(inputData, scanPos)
  let firstY = nextSigned(inputData, scanPos)
  let secondX = nextSigned(inputData, scanPos)
  let secondY = nextSigned(inputData, scanPos)
  outputBuffer.add $shortestDistance(firstX, firstY, secondX, secondY)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

Reading all lines first keeps spacing and line breaks from shifting the scanner. The last write flushes the tail, and the block flush keeps memory bounded.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over the bytes | input size |
| Bezout step | O(log 100000) per case | constant |
| lattice scan | searchRadius / gcdX steps per case | constant |
| output write | one block write per 131072 bytes | flushBlockBytes |

The scan dominates each case, and its cost falls as gcdX grows.

| measure | Big O |
|---|---|
| time per case | O((|a| + |b|) / gcd(|a|, |c|)) |
| space | O(input bytes) |

A brute search over move counts grows with the square of the search radius. The lattice scan replaces it with one linear pass over horizontal coordinates.

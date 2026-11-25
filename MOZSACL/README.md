# MOZSACL — Sharmeen and counting letters (SPOJ)

<https://www.spoj.com/problems/MOZSACL/>

## Problem

Maintain a string of `n` positions starting as `#`. An `Update X V` writes `V` at positions `d`, `d^2`, `d^3`, and so on, where `d` is the smallest divisor of `X` above one. A `Query L R V` reports how many positions from `L` to `R` hold `V`.

The first input line is the string of `#` characters. The second line holds `q`, the number of operations. Each following line is one `Update` or `Query` command.

| item | bound |
|---|---|
| string length `n` | 1 to 100000 |
| operations `q` | 1 to 100000 |
| update value `X` | 2 to 10000000 |
| range ends `L`, `R` | 1 to `n` |
| letter `V` | lowercase `a` to `z` |
| judge limit | 500 ms, 1536 MB |

A position past `n` is ignored. Updating a position replaces its current letter.

Sample input:

```
##########
4
Query 1 5 a
Update 2 a
Query 1 5 a
Query 8 8 a
```

Sample output:

```
0
2
1
```

`X = 2` gives `d = 2`, so positions 2, 4, and 8 become `a`.

## Idea

Stamping powers of a divisor is like labelling lockers 2, 4, and 8 with one tag, then asking how many tags of a color sit in a hallway. The smallest divisor above one is the smallest prime factor of `X`. Keep one Fenwick tree per letter, so a range count takes logarithmic time. Scanning the whole range for each query would cost O(n) every time. The divisor is found once per distinct `X` and cached for later updates.

## Why It Works

1. Any divisor of `X` above one has a prime factor no larger than itself, so `d` is the smallest prime factor.
2. Trial division by primes up to the square root of `X` finds `d`; a prime `X` returns `X`.
3. Position powers stop once they exceed `n`, so each update touches at most 17 spots.
4. A Fenwick tree stores one count per letter and supports prefix sums in O(log n).
5. The range answer is the prefix at `R` minus the prefix at `leftBound - 1`.
6. Overwriting a spot removes its old letter before adding the new one.

| term | meaning |
|---|---|
| `divisorCache` | remembered smallest divisor for each `X` |
| `baseDivisor` | the value `d` for one update |
| `powerPosition` | current power of `d` being written |
| `cellLetter` | letter currently stored at a position |
| `fenwick` | the 26 prefix-count trees |

The generator checks the sample update. `X = 2` gives `d = 2`, and the powers `2, 4, 8` fit inside `n = 10`. The query over `1..5` sees `a` at positions 2 and 4, so it prints 2.

| X | d | written positions in `n = 10` |
|---|---|---|
| 2 | 2 | 2, 4, 8 |
| 9 | 3 | 3, 9 |
| 49 | 7 | 7 |
| 97 | 97 | none |

A divisor above `n` writes nothing because its first power already lies outside the string.

## Code

**Input and scanning.** The reader loads the whole command stream and tokenizes it.

```nim
const flushBlockBytes = 1 shl 17
const letterCount = 26
const maxInputValue = 10000000
const rootLimit = 3163

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1
```

`nextToken` reads command words and single letters.
`nextInt` skips those words to reach the numbers.
Both scanners advance one shared position.

**Count trees.** Each letter gets its own Fenwick array of prefix counts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let initialText = nextToken(inputData, scanPos)
let stringLength = initialText.len
let queryCount = nextInt(inputData, scanPos)
let rowStride = stringLength + 1
var fenwick = newSeq[int]((letterCount + 1) * rowStride)
var cellLetter = newSeq[int](stringLength + 1)

proc fenwickAdd(position: int, letterIndex: int, deltaValue: int) =
  var treePosition = position
  while treePosition <= stringLength:
    fenwick[letterIndex * rowStride + treePosition] += deltaValue
    treePosition += treePosition and (-treePosition)

proc fenwickPrefix(position: int, letterIndex: int): int =
  result = 0
  var treePosition = position
  while treePosition > 0:
    result += fenwick[letterIndex * rowStride + treePosition]
    treePosition -= treePosition and (-treePosition)
```

The 26 trees share one flat array with a fixed stride.
Adding a delta of minus one removes an overwritten letter.
The prefix routine walks down by the lowest set bit.

**Divisor table.** A small prime sieve supports cached factorization.

```nim
var isPrime = newSeq[bool](rootLimit + 1)
for index in 0 .. rootLimit:
  isPrime[index] = true
isPrime[0] = false
isPrime[1] = false
var primeList: seq[int] = @[]
for candidate in 2 .. rootLimit:
  if isPrime[candidate]:
    primeList.add candidate
    if candidate * candidate <= rootLimit:
      var multiple = candidate * candidate
      while multiple <= rootLimit:
        isPrime[multiple] = false
        multiple += candidate

var divisorCache = newSeq[int32](maxInputValue + 1)

proc smallestDivisor(value: int): int =
  for primeValue in primeList:
    if primeValue * primeValue > value:
      return value
    if value mod primeValue == 0:
      return primeValue
  return value
```

Primes only reach the square root of 10000000.
A value with no prime divisor is itself prime.
The cache stores each answer once for repeated updates.

**Command loop.** Updates stamp powers and queries read two prefixes.

```nim
for queryIndex in 0 .. queryCount - 1:
  let commandToken = nextToken(inputData, scanPos)
  if commandToken == "Update":
    let valueX = nextInt(inputData, scanPos)
    let letterToken = nextToken(inputData, scanPos)
    let letterIndex = int(letterToken[0]) - 96
    var baseDivisor = int(divisorCache[valueX])
    if baseDivisor == 0:
      baseDivisor = smallestDivisor(valueX)
      divisorCache[valueX] = int32(baseDivisor)
    var powerPosition = baseDivisor
    while powerPosition <= stringLength:
      let previousLetter = cellLetter[powerPosition]
      if previousLetter > 0:
        fenwickAdd(powerPosition, previousLetter, -1)
      cellLetter[powerPosition] = letterIndex
      fenwickAdd(powerPosition, letterIndex, 1)
      if baseDivisor > stringLength div powerPosition:
        break
      powerPosition = powerPosition * baseDivisor
  else:
    let leftBound = nextInt(inputData, scanPos)
    let rightBound = nextInt(inputData, scanPos)
    let letterToken = nextToken(inputData, scanPos)
    let letterIndex = int(letterToken[0]) - 96
    let answer = fenwickPrefix(rightBound, letterIndex) - fenwickPrefix(leftBound - 1, letterIndex)
    appendOutput($answer)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The division guard stops before a power overflows the string.
Letters map to indexes one through 26.
Every query writes one line into the shared buffer.

## Complexity

Each update touches a short power chain and each query reads two prefixes.

| phase | time | space |
|---|---|---|
| divisor primes | one sieve up to 3163 | small prime list |
| divisor cache | trial division per distinct `X` | array over `X` |
| update | at most 17 point changes | one letter array |
| query | two prefix sums | 26 Fenwick arrays |
| output | one line per query | block buffer |

| measure | Big O |
|---|---|
| update | O(log X + log n) |
| query | O(log n) |
| space | O(26n + X) |

Scanning `L..R` on each query would cost O(n) per query.

The tree and cached divisor keep both operations small.

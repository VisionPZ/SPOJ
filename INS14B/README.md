# INS14B — TRISQRS (SPOJ)

<https://www.spoj.com/problems/INS14B/>

## Problem

Cut a square of side N into right triangles with equal integer area. Each triangle has one horizontal leg and one vertical leg. Count how many different triangle counts can occur. Two partitions count as one when they use the same number of triangles.

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| side N | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

A triangle with area A needs N²/A pieces, so A must divide N². Call that piece count K. Triangle legs may be fractional.

Sample input:

```
2
1
2
```

Sample output:

```
0
2
```

## Idea

Hypotenuses can only meet other hypotenuses, like puzzle tabs that only fit matching sockets. This forces an even number of triangles. Every even divisor of N² then works by slicing the square into equal horizontal strips and cutting each strip diagonally.

Count the even divisors of N² with prime factorization. Skip odd N, since N² has no even divisor then.

## Why It Works

1. All triangle legs are horizontal or vertical, so every hypotenuse slopes away from both axes.
2. The square boundary contains only horizontal and vertical edges, never a hypotenuse.
3. An interior hypotenuse cannot meet a leg, because every leg is axis aligned.
4. Hypotenuses therefore pair up, one per triangle, so the triangle count is even.
5. For an even count K, use K/2 strips of height 2N/K and split each strip along a diagonal.
6. Each resulting triangle has area N²/K, an integer because K divides N².

| term | meaning |
|---|---|
| K | number of triangles, an even divisor of N² |
| A | common integer triangle area, N²/K |
| exponentOfTwo | power of two in N |
| divisorCount | number of even divisors of N² |

For N = 12, N² = 144 has twelve even divisors, so the answer is twelve.

## Code

**Input and scanning.** The reader loads T and every square side.

```nim
const flushBlockBytes = 1 shl 17

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

The scanner skips line breaks between test cases.
The output buffer collects all answers in one string.

**Divisor count.** Factorization turns the square into a short product.

```nim
let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let squareSide = nextInt(inputData, scanPos)
  if squareSide mod 2 == 1:
    appendOutput("0")
  else:
    var remainingFactor = squareSide
    var exponentOfTwo = 0
    while remainingFactor mod 2 == 0:
      exponentOfTwo += 1
      remainingFactor = remainingFactor div 2
    var divisorCount = 2 * exponentOfTwo
    var trialPrime = 3
    while trialPrime * trialPrime <= remainingFactor:
      var primeExponent = 0
      while remainingFactor mod trialPrime == 0:
        primeExponent += 1
        remainingFactor = remainingFactor div trialPrime
      if primeExponent > 0:
        divisorCount = divisorCount * (2 * primeExponent + 1)
      trialPrime += 2
    if remainingFactor > 1:
      divisorCount = divisorCount * 3
    appendOutput($divisorCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Doubling each prime exponent counts divisors of N².
Dropping one factor of two keeps only the even divisors.

## Complexity

Trial division stops at the square root of the remaining factor.

| phase | time | space |
|---|---|---|
| input read | one pass over the token list | one input string |
| factorization | trial division up to sqrt(N) | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(sqrt(N)) |
| space | O(1) besides input |

Listing every divisor would cost O(N²) per case instead of a few divisions.

The strip construction proves every counted divisor is reachable, so the count is exact.

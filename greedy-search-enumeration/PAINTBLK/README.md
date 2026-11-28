# PAINTBLK — Painting Blocks (Act I) (SPOJ)

<https://www.spoj.com/problems/PAINTBLK/>

## Problem

Paint a row of blocks with `k` kinds of paint, using each kind for a fixed number of blocks. Count the colorings where neighboring blocks never share a kind, modulo 1000000007.

Ten cases follow one another with no leading count. Each case gives `k` on one line and the `k` block counts on the next line. Print one answer per case.

| item | bound |
|---|---|
| paint kinds k | 1 to 15 |
| blocks per kind c | 1 to 5 |
| cases | exactly 10 |
| judge limit | 500 ms, 1536 MB |

The small bound on `c` drives the design.

Sample input:

```
3
1 2 3
5
2 2 2 2 2
10
1 1 2 2 3 3 4 4 5 5
```

Sample output:

```
10
39480
85937576
```

## Idea

merge adjacent equal blocks and count arrangements of the merged runs. Inclusion-exclusion turns each kind into a small polynomial whose coefficients track merged pairs. Multiply the polynomials once per case, then read the answer from one convolution sum. Enumerating colorings grows exponentially, while the polynomials stay degree at most 75. Take the polynomial product as the counting engine.

## Why It Works

1. A kind with `c` blocks has `c-1` internal places where two equal blocks could touch.
2. Choosing `j` such places merges them into `c-j` runs of that kind.
3. Inclusion-exclusion gives weight `(-1)^j * C(c-1, j)` to that choice.
4. After all merges, `(n-J)! / product((c_i-j_i)!)` counts arrangements of the remaining runs.
5. Multiplying one polynomial per kind collects every term with the same `J`.

| term | meaning |
|---|---|
| `coefficients` | current product polynomial by merge count |
| `localPoly` | signed factorial weight for one kind |
| `degreeNow` | highest merge count reached so far |
| `factorialValues` | precomputed factorials modulo the prime |

A trace for counts `1 2 3` lists six merge choices. Their signed run counts are `60, -20, -60, 24, 12, -6`. The sum is `10`, matching the sample.

## Code

**Setup and scanner.** The code precomputes factorials and reads all cases at once.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const maxBlockCount = 75

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseRemainder = baseValue mod modulusValue
  var exponentLeft = exponentValue
  var resultValue = int64(1)
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      resultValue = resultValue * baseRemainder mod modulusValue
    baseRemainder = baseRemainder * baseRemainder mod modulusValue
    exponentLeft = exponentLeft div 2
  return resultValue

var factorialValues = newSeq[int64](maxBlockCount + 1)
var inverseFactorials = newSeq[int64](maxBlockCount + 1)
factorialValues[0] = 1
for indexValue in 1 .. maxBlockCount:
  factorialValues[indexValue] = factorialValues[indexValue - 1] * int64(indexValue) mod modulusValue
inverseFactorials[maxBlockCount] = powerMod(factorialValues[maxBlockCount], modulusValue - 2)
for indexValue in countdown(maxBlockCount - 1, 0):
  inverseFactorials[indexValue] = inverseFactorials[indexValue + 1] * int64(indexValue + 1) mod modulusValue

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

Factorial inverses use Fermat's theorem with the prime modulus.
The reader skips all gaps between the two lines of a case.
A zero kind count never occurs, so end of input is detected separately.

**Polynomial convolution.** Each kind contributes a degree-five factor.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc countPaintings(blockCounts: seq[int]): int64 =
  var totalBlocks = 0
  for colorCount in blockCounts:
    totalBlocks += colorCount
  var coefficients = newSeq[int64](totalBlocks + 1)
  coefficients[0] = 1
  var degreeNow = 0
  for colorCount in blockCounts:
    var localPoly = newSeq[int64](colorCount)
    for mergeCount in 0 .. colorCount - 1:
      var chooseValue = inverseFactorials[mergeCount] * inverseFactorials[colorCount - 1 - mergeCount] mod modulusValue
      chooseValue = chooseValue * factorialValues[colorCount - 1] mod modulusValue
      chooseValue = chooseValue * inverseFactorials[colorCount - mergeCount] mod modulusValue
      if (mergeCount and 1) == 1:
        localPoly[mergeCount] = modulusValue - chooseValue
      else:
        localPoly[mergeCount] = chooseValue
    var nextCoefficients = newSeq[int64](degreeNow + colorCount + 1)
    for degreeIndex in 0 .. degreeNow:
      if coefficients[degreeIndex] == 0:
        continue
      for mergeCount in 0 .. colorCount - 1:
        var addValue = coefficients[degreeIndex] * localPoly[mergeCount] mod modulusValue
        nextCoefficients[degreeIndex + mergeCount] = (nextCoefficients[degreeIndex + mergeCount] + addValue) mod modulusValue
    coefficients = nextCoefficients
    degreeNow += colorCount - 1
  var answerValue: int64 = 0
  for degreeIndex in 0 .. degreeNow:
    answerValue = (answerValue + coefficients[degreeIndex] * factorialValues[totalBlocks - degreeIndex]) mod modulusValue
  return answerValue
```

Each local polynomial has at most five terms.
The running degree never exceeds `n - k`.
Every product is reduced modulo the prime on each step.

**Case loop.** The driver emits one answer per case.

```nim
while true:
  let colorKinds = nextInt(inputData, scanPos)
  if colorKinds == 0:
    break
  var blockCounts = newSeq[int](colorKinds)
  for colorIndex in 0 .. colorKinds - 1:
    blockCounts[colorIndex] = nextInt(inputData, scanPos)
  appendOutput($countPaintings(blockCounts))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

End of input stops the loop without extra output.
The buffered writer flushes only after many lines.
The final flush writes the remaining bytes.

## Complexity

Each case multiplies at most fifteen short polynomials.

| phase | time | space |
|---|---|---|
| factorial setup | one pass to 75 | two small arrays |
| input read | one pass over all bytes | one input string |
| polynomial product | at most k short convolutions | one degree-n array |
| output | one buffered line per case | block buffer |

The short local factors keep each convolution cheap.

| measure | Big O |
|---|---|
| time per case | O(k * n * c) |
| space | O(total input bytes + n) |

Brute enumeration would visit up to `n! / product(c_i!)` colorings.
The polynomial method visits only a few hundred coefficient pairs.

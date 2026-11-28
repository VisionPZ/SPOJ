# DCEPC14F — The Toy Store (SPOJ)

<https://www.spoj.com/problems/DCEPC14F/>

## Problem

Count ordered stacks of K Lego pieces whose total height leaves remainder X modulo M. Pieces have fixed heights, supply is unlimited, and each kind counts as a choice even when two kinds share a height.

Input starts with a test count T. Each test has a kind count N, a line of N heights, then a line holding M, K, and X. Print the count modulo 1000000007, one line per test.

| item | bound |
|---|---|
| tests T | 1 to 100 |
| kinds N | 1 to 100000 |
| modulus M | 1 to 100 |
| stack size K | 1 to 1000000000 |
| target X | 0 or greater |
| piece height | 1 to 1000000000 |
| judge limit | 500 ms, 1536 MB |

Two stacks differ when some level uses a different kind, so equal-height kinds are separate choices.

Sample input:

```
2
3
1 2 3
3 1 0
3
1 2 3
3 2 0
```

Sample output:

```
1
3
```

## Idea

Track only remainders and raise the remainder-counting polynomial to the Kth power by repeated squaring, like folding a long chain of additions into logarithmically many doublings.

The algorithm builds one coefficient per residue in Z[y]/(y^M − 1), where coefficient r counts kinds of height r mod M. Multiplying two such polynomials wraps exponents modulo M and costs O(M²). Binary exponentiation needs O(log K) multiplications, so a test costs O(M² log K) after reading the heights. Enumerating K-long stacks would cost O(N^K) and fail for large K.

## Why It Works

1. A stack's height remainder is the sum of its pieces' remainders modulo M.
2. The polynomial P(y) = sum over residues r of count[r]·y^r records one-piece choices.
3. The coefficient of y^X in P(y)^K counts stacks of K pieces with remainder X.
4. Working modulo y^M − 1 wraps exponents, so coefficients stay indexed by residues.
5. Binary exponentiation computes that power with O(log K) cyclic products.

| term | meaning |
|---|---|
| `basePoly` | one-piece remainder counts |
| `answerPoly` | accumulated power while K is reduced |
| `powerPoly` | current square of `basePoly` |
| `cyclicProduct` | multiplication with exponent wraparound |
| `targetHeight` | X reduced into the residue range |

The worked example uses the second sample test, with residues 1, 2, and 0 modulo 3.

| step | current power | residue 0 | residue 1 | residue 2 |
|---|---|---|---|---|
| base | P | 1 | 1 | 1 |
| after squaring | P² | 3 | 3 | 3 |

The residue-0 coefficient of P² is 3, matching the sample output.

Each coefficient is reduced modulo 1000000007 after every product. The product of two coefficients stays below 1.1e18 and fits in int64.

## Code

**Input and helpers.** The reader loads stdin once, scans integers by hand, and defines the wrapped multiplication.

```nim
const flushBlockBytes = 1 shl 17
const primeModulus: int64 = 1000000007

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

proc cyclicProduct(leftPoly: seq[int64], rightPoly: seq[int64], ringSize: int): seq[int64] =
  result = newSeq[int64](ringSize)
  for leftIndex in 0 .. ringSize - 1:
    let leftValue = leftPoly[leftIndex]
    if leftValue == 0:
      continue
    for rightIndex in 0 .. ringSize - 1:
      let rightValue = rightPoly[rightIndex]
      if rightValue == 0:
        continue
      let targetIndex = (leftIndex + rightIndex) mod ringSize
      result[targetIndex] = (result[targetIndex] + leftValue * rightValue) mod primeModulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The exponent wrap models heights modulo M.
Zero coefficients are skipped to save work.
The buffer flushes in large blocks.

**Exponentiation.** Each test reduces the stack size one bit at a time.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let kindCount = nextInt(inputData, scanPos)
  var heights = newSeq[int](kindCount)
  for kindIndex in 0 .. kindCount - 1:
    heights[kindIndex] = nextInt(inputData, scanPos)
  let ringSize = nextInt(inputData, scanPos)
  let stackHeight = nextInt(inputData, scanPos)
  let targetHeight = nextInt(inputData, scanPos) mod ringSize
  var basePoly = newSeq[int64](ringSize)
  for kindIndex in 0 .. kindCount - 1:
    let residue = heights[kindIndex] mod ringSize
    basePoly[residue] = (basePoly[residue] + 1) mod primeModulus
  var answerPoly = newSeq[int64](ringSize)
  answerPoly[0] = 1
  var powerPoly = basePoly
  var remaining = stackHeight
  while remaining > 0:
    if remaining mod 2 == 1:
      answerPoly = cyclicProduct(answerPoly, powerPoly, ringSize)
    remaining = remaining div 2
    if remaining > 0:
      powerPoly = cyclicProduct(powerPoly, powerPoly, ringSize)
  appendOutput($answerPoly[targetHeight])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Heights are reduced when the polynomial is built.
A set bit multiplies the answer by the current power.
The final coefficient at X is the price of the set.

## Complexity

Each test reads N heights and multiplies M-coefficient polynomials O(log K) times.

| phase | time | space |
|---|---|---|
| input read | one pass over N heights | one input string |
| exponentiation | O(M² log K) wrapped products | four M-length arrays |
| output | one line per test | block buffer |

| measure | Big O |
|---|---|
| time per test | O(N + M² log K) |
| space per test | O(N + M) |

Enumerating every K-piece stack costs O(N^K) and cannot handle the stated K bound.
Repeated squaring replaces that enumeration with a few dozen small products.

The modulo wrap is needed because exponent sums can reach K times M.
Without it, coefficient indices would grow past the residue range.

# DUKKAR2 — Huge Pascal triangle (SPOJ)

<https://www.spoj.com/problems/DUKKAR2/>

## Problem

Count entries divisible by a prime P across the first N rows of Pascal's triangle. N is given as base-P digits, least significant digit first. Return the count modulo 1000000007.

| item | bound |
|---|---|
| test cases T | 1 to 299 |
| prime P | 1 to 1000000000 |
| digit count k | 1 to 999 |
| digit ai | 0 to P − 1, top digit positive |
| judge limit | 300 ms, 1536 MB |

Row n contains n + 1 entries. Row n has exactly the product of (digit + 1) entries that are not divisible by P, by Lucas' theorem.

Sample input:

```
3
5 2
0 1 
5 2
1 1
7 3
2 0 2
```

Sample output:

```
0
4
2689
```

## Idea

Subtract the non-divisible entries from all entries, like counting empty seats by counting full rows first. Row n contributes (n + 1) minus the Lucas product of its digits plus one.

Summing (n + 1) over all rows gives N(N + 1)/2. The remaining sum over Lucas products is a digit walk: fix higher digits, let the current digit fall short, and let lower digits roam freely. Each free digit position contributes the constant sum P(P + 1)/2.

## Why It Works

1. Lucas' theorem says C(n, r) is nonzero modulo P exactly when every base-P digit of r is at most the matching digit of n.
2. That gives product(digit + 1) non-divisible entries in row n.
3. The first N rows hold N(N + 1)/2 entries in total.
4. Fix all digits above position j and choose a smaller digit there.
5. Lower j digits are free, and their product sum equals (P(P + 1)/2)^j.
6. Adding every position once gives the total non-divisible count.
7. Horner evaluation gives N modulo 1000000007 without building N.

| term | meaning |
|---|---|
| fullBlockSum | P(P + 1)/2 modulo the answer modulus |
| blockPowers | fullBlockSum raised to each lower digit count |
| higherProduct | product of (digit + 1) above the current digit |
| nondivisibleSum | non-divisible entries in the first N rows |

For P = 5 and digits 1, 1, N = 6. Total entries are 6 × 7 / 2 = 21. The walk gives 17 non-divisible entries, so the answer is 4.

## Code

**Input and scanning.** The reader takes every test case as P, k, then k digits.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus: int64 = 1000000007
const inverseOfTwo: int64 = 500000004

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

All products stay in int64 so values up to 1e18 remain exact.
The modulus is prime, so multiplying by inverseOfTwo divides by two.

**Digit walk.** Powers and a descending scan price every short digit.

```nim
let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let primeBase = nextInt(inputData, scanPos)
  let digitCount = nextInt(inputData, scanPos)
  var baseDigits = newSeq[int](digitCount)
  for digitIndex in 0 .. digitCount - 1:
    baseDigits[digitIndex] = nextInt(inputData, scanPos)
  let baseModulo = int64(primeBase) mod answerModulus
  let basePlusOneModulo = (int64(primeBase) + 1) mod answerModulus
  let fullBlockSum = baseModulo * basePlusOneModulo mod answerModulus * inverseOfTwo mod answerModulus
  var blockPowers = newSeq[int64](digitCount)
  blockPowers[0] = 1
  for powerIndex in 1 .. digitCount - 1:
    blockPowers[powerIndex] = blockPowers[powerIndex - 1] * fullBlockSum mod answerModulus
  var nondivisibleSum: int64 = 0
  var higherProduct: int64 = 1
  var position = digitCount - 1
  while position >= 0:
    let digitModulo = int64(baseDigits[position]) mod answerModulus
    let digitPlusOne = (digitModulo + 1) mod answerModulus
    let smallerDigitsSum = digitModulo * digitPlusOne mod answerModulus * inverseOfTwo mod answerModulus
    nondivisibleSum = (nondivisibleSum + higherProduct * smallerDigitsSum mod answerModulus * blockPowers[position]) mod answerModulus
    higherProduct = higherProduct * digitPlusOne mod answerModulus
    position -= 1
  var valueModulo: int64 = 0
  position = digitCount - 1
  while position >= 0:
    valueModulo = (valueModulo * baseModulo + int64(baseDigits[position]) mod answerModulus) mod answerModulus
    position -= 1
  let totalEntries = valueModulo * ((valueModulo + 1) mod answerModulus) mod answerModulus * inverseOfTwo mod answerModulus
  let answer = (totalEntries - nondivisibleSum + answerModulus) mod answerModulus
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The digit walk visits each position once from high to low.
Horner evaluation follows in the same direction to recover N modulo the modulus.
One subtraction produces the required count.

## Complexity

Powers and the digit walk dominate each case.

| phase | time | space |
|---|---|---|
| input read | one pass over k digits | one input string |
| power table | k modular products | k integers |
| digit walk | k modular steps | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(k) |
| space per case | O(k) |

Building every row up to N would take exponential time in k.

The digit walk replaces all rows with one pass over the base-P representation.

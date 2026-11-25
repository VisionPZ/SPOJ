# POLTOPOL — Polynomial f(x) to Polynomial h(x) (SPOJ)

<https://www.spoj.com/problems/POLTOPOL/>

## Problem

Given a polynomial `f`, find the polynomial `h` whose product with `x` has forward difference `f`. In other words, `g(x) - g(x-1) = f(x)`, `g(0) = 0`, and `h(x) = g(x)/x`.

Each test case starts with the degree `d`, followed by `d + 1` integer coefficients `c0` to `cd`. Print the `d + 1` integer coefficients of `h` on one line, separated by single spaces.

| item | bound |
|---|---|
| test cases T | 1 to 10000 |
| degree d | 0 to 18 |
| input coefficients | between `-2^31` and `2^31` |
| output coefficients | guaranteed integers |
| judge limit | 3000 ms, 1536 MB |

The small degree keeps every coefficient inside 64-bit arithmetic.

Sample input:

```
5
0
13
1
-1 2
1
0 2
2
2 -5 9
3
23 9 21 104
```

Sample output:

```
13
0 1
1 1
1 2 3
31 41 59 26
```

## Idea

Write `g(x) = x h(x)` and expand the forward difference one degree at a time, like unpacking nested boxes from the largest box down to the smallest.

If `h` has coefficient `a_r` on `x^r`, the term `a_r(x^{r+1} - (x-1)^{r+1})` contributes to every power up to `r`. The coefficient `c_s` of `f` equals the sum of `a_r (-1)^{r-s} C(r+1,s)` over all `r >= s`.

The highest unknown appears alone in the equation for `c_d`, so divide by `d + 1`. Substituting that value into the next equation frees the next unknown. Continue down to `a_0`. This triangular solve costs `O(d^2)` per case. Building `g` by summing powers and then interpolating costs far more work and needs rational arithmetic.

## Why It Works

1. Since `g(0) = 0` and `g(x) = x h(x)`, dividing `g` by `x` loses no polynomial terms.
2. Expanding `(x-1)^{r+1}` with the binomial theorem gives the contribution of `a_r`.
3. The coefficient of `x^s` in `x^{r+1} - (x-1)^{r+1}` is `(-1)^{r-s} C(r+1,s)`.
4. The coefficient of `x^d` comes only from `a_d`, so `a_d = c_d/(d+1)`.
5. After fixing all unknowns above `r`, the equation for `c_r` has one unknown and divides by `r + 1`.
6. The statement guarantees integer results, so each division has remainder zero.

| term | meaning |
|---|---|
| `sourceCoefficients` | input values `c0` through `cd` |
| `resultCoefficients` | output values `a0` through `ad` |
| `binomial` | Pascal table of binomial coefficients |
| `residual` | right-hand side after subtracting known higher-degree terms |
| `sourceDegree` | current power being solved, from `d` down to `0` |

The table names the pieces of the triangular solve.

A script-traced example for `f = 2 - 5x + 9x^2`:

| step | computation | value |
|---|---|---|
| degree 2 | `c2 / 3 = 9/3` | `a2 = 3` |
| degree 1 | `(c1 - (-1)*C(3,1)*a2)/2 = (-5 + 9)/2` | `a1 = 2` |
| degree 0 | `c0 - (-1)*C(2,0)*a1 - C(3,0)*a2 = 2 + 2 - 3` | `a0 = 1` |
| answer | coefficients from low to high | `1 2 3` |

The trace reproduces the fourth sample line.

Signs alternate with the distance between the source degree and the unknown. Pascal's triangle supplies each binomial coefficient exactly. Working from high degrees down keeps every intermediate value an integer.

## Code

**Shared input and output helpers.** The reader handles negative coefficients, and the writer flushes in blocks.

```nim
const flushBlockBytes = 1 shl 17
const maximumDegree = 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner stops at a minus sign as well as a digit.
The Pascal table is built once, up to degree 19.
Entries beyond a row's length stay zero and are never read.

```nim
var binomial = newSeq[seq[int64]](maximumDegree + 2)
for rowIndex in 0 .. maximumDegree + 1:
  binomial[rowIndex] = newSeq[int64](maximumDegree + 2)
  binomial[rowIndex][0] = 1
  for columnIndex in 1 .. rowIndex:
    binomial[rowIndex][columnIndex] = binomial[rowIndex - 1][columnIndex - 1] +
                                      binomial[rowIndex - 1][columnIndex]
```

**Triangular solve.** Each pass fixes one coefficient of `h`.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let degree = nextInt(inputData, scanPos)
  var sourceCoefficients = newSeq[int64](degree + 1)
  for coefficientIndex in 0 .. degree:
    sourceCoefficients[coefficientIndex] = int64(nextInt(inputData, scanPos))
  var resultCoefficients = newSeq[int64](degree + 1)
  for sourceDegree in countdown(degree, 0):
    var residual = sourceCoefficients[sourceDegree]
    for higherDegree in sourceDegree + 1 .. degree:
      let sign = if (higherDegree - sourceDegree) mod 2 == 0: int64(1) else: int64(-1)
      residual = residual - sign * binomial[higherDegree + 1][sourceDegree] *
                 resultCoefficients[higherDegree]
    resultCoefficients[sourceDegree] = residual div binomial[sourceDegree + 1][sourceDegree]
  for coefficientIndex in 0 .. degree:
    if coefficientIndex > 0:
      outputBuffer.add ' '
    appendOutput($resultCoefficients[coefficientIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop walks degrees from `d` down to `0`.
Known higher-degree terms are subtracted before each division.
Spaces are written between coefficients, and one newline ends each case.

## Complexity

The Pascal table is built once, and each case solves a triangular system of size `d + 1`.

| phase | time | space |
|---|---|---|
| Pascal table | constant, at most 19 rows | 20 by 20 integers |
| triangular solve | about `d^2/2` multiply-subtract steps | two arrays of `d + 1` integers |
| output | one buffered write per block | one output string |

The phase table shows that the degree, not the case count, drives the inner work.

| measure | Big O |
|---|---|
| time | O(T * d^2) |
| space | O(d^2) for the binomial table |

Interpolating `g` from sample points would need rational arithmetic and more operations; the triangular solve stays in integers.

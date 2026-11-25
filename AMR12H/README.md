<https://www.spoj.com/problems/AMR12H/>

## Problem

An expression combines uniform random values with min and max; report its expected value. Input gives the test count and one preorder expression per line, using `M`, `m` and `x`. Output one value per line with error below `1e-6`.
| item | bound |
|---|---|
| tests | 1 to 1000 |
| expression length | 1 to 100 |
| random value range | 0 to 1 inclusive |
| judge limit | 1000 ms, 1536 MB |

Each operator has exactly two children, and every leaf is an `x`.

Sample input:

```
4
x
mxx
Mxx
MmxxMxx 
```

Sample output:

```
0.500000
0.333333
0.666667
0.700000
```

## Idea

Treat the search for the mean like measuring a rope by weighing it at evenly spaced marks: sample a polynomial at fixed points and combine those samples exactly. The cumulative distribution of a subtree is a polynomial over zero to one. Its mean is the integral of one minus that polynomial.

Max multiplies two distribution polynomials. Min adds them and subtracts their product. Gauss-Legendre quadrature integrates any polynomial of degree at most sixty-three with thirty-two nodes, and an expression of length one hundred has at most fifty leaves.

The integral replaces a growing symbolic expansion with a fixed sampling cost.

## Why It Works

1. A leaf has cumulative distribution `t` on the interval from zero to one.
2. For independent values, max has distribution `F_A * F_B` at every point.
3. Min has distribution `F_A + F_B - F_A * F_B` at every point.
4. The mean equals the integral of one minus the distribution over the interval.
5. Thirty-two Gauss-Legendre nodes integrate polynomials through degree sixty-three exactly.
6. Evaluating a subtree at one point uses only products and sums, so no cancellation grows.

| term | meaning |
|---|---|
| `evaluateCdf` | distribution value of a subtree at one sample point |
| `quadNodes` | fixed sample points on the interval from zero to one |
| `quadWeights` | matching integration weights |
| `expectedValue` | accumulated mean from the weighted samples |

For `MmxxMxx`, min has distribution `2t - t*t` and max has distribution `t*t`. Their product is `2t^3 - t^4`. The integral of one minus that product is `1 - 1/2 + 1/5 = 0.7`.

All sample points lie inside zero to one, so the evaluation stays stable. Rounding affects only the sixth decimal place.

## Code

**Reader and fixed nodes.** The scanner skips the test count and reads each expression as a token.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const quadNodes = [
  1.36806907525921506164e-03, 7.19424422736580915227e-03, 1.76188722062468050567e-02, 3.25469620311301666149e-02,
  5.18394221169739544131e-02, 7.53161931337150147847e-02, 1.02758102016028807224e-01, 1.33908940629855144344e-01,
  1.68477866534892384287e-01, 2.06142121379618847854e-01, 2.46550045533885320292e-01, 2.89324361934682361408e-01,
  3.34065698858936166449e-01, 3.80356318873931453783e-01, 4.27764019208601742328e-01, 4.75846167156130817055e-01,
  5.24153832843869182945e-01, 5.72235980791398257672e-01, 6.19643681126068490705e-01, 6.65934301141063889062e-01,
  7.10675638065317638592e-01, 7.53449954466114624196e-01, 7.93857878620381152146e-01, 8.31522133465107615713e-01,
  8.66091059370144855656e-01, 8.97241897983971137265e-01, 9.24683806866285040726e-01, 9.48160577883025990076e-01,
  9.67453037968869833385e-01, 9.82381127793753194943e-01, 9.92805755772634190848e-01, 9.98631930924740784938e-01
]
const quadWeights = [
  3.50930500473525287808e-03, 8.13719736545287161689e-03, 1.26960326546310120488e-02, 1.71369314565108822601e-02,
  2.14179490111134178398e-02, 2.54990296311880457192e-02, 2.93420467392677825069e-02, 3.29111113881808414749e-02,
  3.61728970544241690277e-02, 3.90969478935351139048e-02, 4.16559621134733534809e-02, 4.38260465022018916303e-02,
  4.55869393478818898946e-02, 4.69221995404022554355e-02, 4.78193600396373541539e-02, 4.82700442573638296984e-02,
  4.82700442573638296984e-02, 4.78193600396373541539e-02, 4.69221995404022554355e-02, 4.55869393478818898946e-02,
  4.38260465022018916303e-02, 4.16559621134733534809e-02, 3.90969478935351139048e-02, 3.61728970544241690277e-02,
  3.29111113881808414749e-02, 2.93420467392677825069e-02, 2.54990296311880457192e-02, 2.14179490111134178398e-02,
  1.71369314565108822601e-02, 1.26960326546310120488e-02, 8.13719736545287161689e-03, 3.50930500473525287808e-03
]

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
  while pos < data.len and data[pos] != 'M' and data[pos] != 'm' and data[pos] != 'x':
    pos += 1
  var token = ""
  while pos < data.len and (data[pos] == 'M' or data[pos] == 'm' or data[pos] == 'x'):
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The token reader keeps only the three symbols.
The quadrature constants are computed once outside the driver.
One output buffer collects every answer line.

**Distribution evaluation.** One recursive walk computes the distribution at a sample point.

```nim
proc evaluateCdf(expression: string, pos: var int, point: float): float =
  let symbol = expression[pos]
  pos += 1
  if symbol == 'x':
    return point
  let leftValue = evaluateCdf(expression, pos, point)
  let rightValue = evaluateCdf(expression, pos, point)
  if symbol == 'M':
    return leftValue * rightValue
  return leftValue + rightValue - leftValue * rightValue
```

A leaf returns the sample point.
Max multiplies two child distributions.
Min adds the children and subtracts their product.

**Integration loop.** Thirty-two samples give the expected value for one expression.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let expression = nextToken(inputData, scanPos)
  var expectedValue: float = 0.0
  for nodeIndex in 0 .. 31:
    var parsePos = 0
    let cdfValue = evaluateCdf(expression, parsePos, quadNodes[nodeIndex])
    expectedValue += quadWeights[nodeIndex] * (1.0 - cdfValue)
  appendOutput(formatFloat(expectedValue, ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The parser restarts at the first symbol for each node.
Weights turn the samples into an integral.
Six decimals match the required error range.

## Complexity

Each test pays a fixed sampling cost.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| distribution evaluation | constant samples times expression length | recursion depth |
| output | one line per test | block buffer |

| measure | Big O |
|---|---|
| time | O(L) per test, with a fixed factor of 32 |
| space | O(L) for the expression |

Expanding the full distribution polynomial costs quadratic work in the number of leaves.

The fixed quadrature keeps every test fast.

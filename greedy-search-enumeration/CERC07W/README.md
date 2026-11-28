# CERC07W — Tough Water Level (SPOJ)

<https://www.spoj.com/problems/CERC07W/>

## Problem

Find the water level that lowers the center of mass of a cup as far as possible, then print the water volume and that level. The cup is a solid of revolution with outer radius R(x) and horizontal glass thickness T(x).

Input holds cup descriptions. Each has H and B on one line, then an expression for R(x), then an expression for T(x). Expressions use digits, dots, `+`, `-`, `*`, `/`, parentheses, and `x`. A line with two zeros ends the input. Output holds one sentence per cup with three decimals for liters and water depth.

| item | bound |
|---|---|
| cup height H | 0 < H <= 100 cm |
| bottom thickness B | 0 < B < H |
| outer radius R(x) | 0.1 < R(x) <= 100 |
| glass thickness T(x) | 0.1 <= T(x) < R(x) |
| judge limit | 1000 ms, 1536 MB |

Water depth is printed from the inner bottom, so it equals the water level minus B.

Sample input:

```
9 1
3+x/6
17/8-x/8
10 1
(x+10)
10/(x+10)
0 0
```

Sample output:

```
Pour 0.030 litres / 3.365 cm of water.
Pour 0.878 litres / 2.193 cm of water.
```

## Idea

Adding water at a level above the current center of mass raises it; adding water below lowers it, like balancing a seesaw by pouring sand onto one side. Compute the glass center once from the outer cylinder minus the inner cavity. Add water up to a trial level and take the mass-weighted average. Binary search the level where adding water at that level leaves the average unchanged. Evaluating the cup on a dense grid and testing every level would be far slower. Integrate three times per trial and halve the interval.

## Why It Works

1. Glass occupies the outer solid from 0 to H minus the cavity from B to H.
2. Water occupies the cavity from B to the trial level L.
3. Cross-section area scales with radius squared; slice mass scales with area times density.
4. The center of mass is the area-weighted average of slice height.
5. Adding a slice at height L moves the average down when L is below it, and up when L is above it.
6. The minimum occurs where L equals the combined center; binary search finds that crossing.

| term | meaning |
|---|---|
| `outerSquareRoot` | expression node for R(x) squared |
| `innerSquareRoot` | expression node for (R(x) - T(x)) squared |
| `glassMassCenter` | height of the glass center of mass |
| `glassWeight` | glass mass without the common factor pi |
| `combinedCenter` | center of glass plus water filled to a trial level |
| `heightPrecision` | stopping width of the level search |

The table maps each physical quantity to its code name.

A script trace of the first sample:

```
outer area 128.25, inner area 47.19
glass weight 202.66, glass center 4.4293
trial level 4.36547: water weight 9.516, water center 3.0055
combined center 4.3654 -> level stays near 4.36547
liters 0.0299 -> 0.030, depth 4.36547 - 1 = 3.365
```

The trace reproduces the first sample answer.

## Code

**Input and shared constants.** Bulk read feeds the integer scanner and the line reader.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const integrationPrecision = 10000
const glassDensity = 2.5
const waterDensity = 1.0
const heightPrecision = 0.00001
const piValue = 3.14159265358979323846
const opNumber = 0
const opAdd = 1
const opSubtract = 2
const opMultiply = 3
const opDivide = 4
const opVariable = 5
const opNegate = 6
const opSquare = 7

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextLine(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    pos += 1
  var lineText = ""
  while pos < data.len and data[pos] != '\n' and data[pos] != '\r':
    lineText.add data[pos]
    pos += 1
  return lineText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextLine` returns an expression without its newline.
Density and precision constants match the physical model.
One buffer collects all cup sentences.

**Expression nodes.** A tree stores numbers, operators, and unary signs.

```nim
type ExpressionParser = object
  text: string
  position: int
  opCodes: seq[int]
  values: seq[float]
  leftChild: seq[int]
  rightChild: seq[int]

proc addNode(parser: var ExpressionParser, opCode: int, leftIndex: int, rightIndex: int): int =
  parser.opCodes.add opCode
  parser.values.add 0.0
  parser.leftChild.add leftIndex
  parser.rightChild.add rightIndex
  return parser.opCodes.len - 1

proc peekChar(parser: var ExpressionParser): char =
  while parser.position < parser.text.len and parser.text[parser.position] == ' ':
    parser.position += 1
  if parser.position < parser.text.len:
    return parser.text[parser.position]
  return '\0'

proc takeChar(parser: var ExpressionParser): char =
  let currentChar = peekChar(parser)
  if currentChar != '\0':
    parser.position += 1
  return currentChar

proc parseNumberNode(parser: var ExpressionParser): int =
  let nodeIndex = addNode(parser, opNumber, 0, 0)
  var numberValue = 0.0
  var decimalWeight = 0.1
  var decimalPart = false
  while true:
    let currentChar = peekChar(parser)
    if currentChar >= '0' and currentChar <= '9':
      if decimalPart:
        numberValue = numberValue + float(int(currentChar) - firstDigitValue) * decimalWeight
        decimalWeight = decimalWeight * 0.1
      else:
        numberValue = numberValue * 10.0 + float(int(currentChar) - firstDigitValue)
    elif currentChar == '.':
      decimalPart = true
    else:
      break
    discard takeChar(parser)
  parser.values[nodeIndex] = numberValue
  return nodeIndex
```

Spaces are skipped before every token.
Decimal digits use a shrinking weight.
Each node keeps children by index.

**Recursive descent.** Multiplication binds tighter than addition, with unary signs handled first.

```nim
proc parseExpression(parser: var ExpressionParser): int

proc parseOperand(parser: var ExpressionParser): int =
  var negate = false
  var nodeIndex = 0
  while true:
    let currentChar = peekChar(parser)
    if currentChar == '+':
      discard takeChar(parser)
    elif currentChar == '-':
      negate = not negate
      discard takeChar(parser)
    elif currentChar == '(':
      discard takeChar(parser)
      nodeIndex = parseExpression(parser)
      break
    elif currentChar == 'x':
      discard takeChar(parser)
      nodeIndex = addNode(parser, opVariable, 0, 0)
      break
    else:
      nodeIndex = parseNumberNode(parser)
      if negate:
        parser.values[nodeIndex] = -parser.values[nodeIndex]
      return nodeIndex
  if negate:
    nodeIndex = addNode(parser, opNegate, nodeIndex, 0)
  return nodeIndex

proc parseProduct(parser: var ExpressionParser): int =
  var leftIndex = parseOperand(parser)
  while true:
    let currentChar = peekChar(parser)
    if currentChar != '*' and currentChar != '/':
      return leftIndex
    discard takeChar(parser)
    let rightIndex = parseOperand(parser)
    if currentChar == '*':
      leftIndex = addNode(parser, opMultiply, leftIndex, rightIndex)
    else:
      leftIndex = addNode(parser, opDivide, leftIndex, rightIndex)

proc parseExpression(parser: var ExpressionParser): int =
  var leftIndex = parseProduct(parser)
  while true:
    let currentChar = takeChar(parser)
    if currentChar != '+' and currentChar != '-':
      return leftIndex
    let rightIndex = parseProduct(parser)
    if currentChar == '+':
      leftIndex = addNode(parser, opAdd, leftIndex, rightIndex)
    else:
      leftIndex = addNode(parser, opSubtract, leftIndex, rightIndex)
```

Repeated unary signs cancel in pairs.
Parentheses call the top-level parser again.
The forward declaration closes the recursion.

**Evaluation and integration.** Simpson's rule integrates each node tree over a height range.

```nim
proc evaluateNode(parser: ExpressionParser, nodeIndex: int, xValue: float): float =
  case parser.opCodes[nodeIndex]
  of opNumber:
    return parser.values[nodeIndex]
  of opVariable:
    return xValue
  of opNegate:
    return -evaluateNode(parser, parser.leftChild[nodeIndex], xValue)
  of opAdd:
    return evaluateNode(parser, parser.leftChild[nodeIndex], xValue) +
           evaluateNode(parser, parser.rightChild[nodeIndex], xValue)
  of opSubtract:
    return evaluateNode(parser, parser.leftChild[nodeIndex], xValue) -
           evaluateNode(parser, parser.rightChild[nodeIndex], xValue)
  of opMultiply:
    return evaluateNode(parser, parser.leftChild[nodeIndex], xValue) *
           evaluateNode(parser, parser.rightChild[nodeIndex], xValue)
  of opDivide:
    return evaluateNode(parser, parser.leftChild[nodeIndex], xValue) /
           evaluateNode(parser, parser.rightChild[nodeIndex], xValue)
  of opSquare:
    let squaredValue = evaluateNode(parser, parser.leftChild[nodeIndex], xValue)
    return squaredValue * squaredValue
  else:
    return 0.0

proc integrateSimpson(parser: ExpressionParser, rootIndex: int, lowerBound: float, upperBound: float): float =
  let subintervals = 2 * integrationPrecision
  let deltaWidth = (upperBound - lowerBound) / float(subintervals)
  var accumulated = evaluateNode(parser, rootIndex, lowerBound) +
                    evaluateNode(parser, rootIndex, upperBound)
  for stepIndex in 1 .. integrationPrecision - 1:
    let samplePoint = lowerBound + float(2 * stepIndex - 1) * deltaWidth
    accumulated = accumulated + 4.0 * evaluateNode(parser, rootIndex, samplePoint)
    accumulated = accumulated + 2.0 * evaluateNode(parser, rootIndex, samplePoint + deltaWidth)
  accumulated = accumulated + 4.0 * evaluateNode(parser, rootIndex, upperBound - deltaWidth)
  return deltaWidth * accumulated / 3.0

proc combinedCenter(parser: ExpressionParser, innerSquareRoot: int, weightedInnerRoot: int,
                    glassMassCenter: float, glassWeight: float, bottomValue: float, levelValue: float): float =
  let waterWeight = waterDensity * integrateSimpson(parser, innerSquareRoot, bottomValue, levelValue)
  if waterWeight <= 0.0:
    return glassMassCenter
  let waterCenter = integrateSimpson(parser, weightedInnerRoot, bottomValue, levelValue) / waterWeight
  return (glassMassCenter * glassWeight + waterCenter * waterWeight) / (glassWeight + waterWeight)
```

Simpson uses 20000 subintervals per integral.
The weighted node multiplies radius squared by height x.
`combinedCenter` guards the empty-water case.

**Cup driver.** The loop builds nodes, solves the level, and writes the sentence.

```nim
while true:
  let cupHeight = nextInt(inputData, scanPos)
  let bottomThickness = nextInt(inputData, scanPos)
  if cupHeight == 0:
    break
  let radiusExpression = nextLine(inputData, scanPos)
  let thicknessExpression = nextLine(inputData, scanPos)

  var parser: ExpressionParser
  parser.position = 0
  parser.opCodes = @[]
  parser.values = @[]
  parser.leftChild = @[]
  parser.rightChild = @[]
  parser.text = radiusExpression
  let outerRoot = parseExpression(parser)
  parser.text = thicknessExpression
  parser.position = 0
  let thicknessRoot = parseExpression(parser)
  let innerRoot = addNode(parser, opSubtract, outerRoot, thicknessRoot)
  let innerSquareRoot = addNode(parser, opSquare, innerRoot, 0)
  let outerSquareRoot = addNode(parser, opSquare, outerRoot, 0)
  let variableRoot = addNode(parser, opVariable, 0, 0)
  let weightedOuterRoot = addNode(parser, opMultiply, variableRoot, outerSquareRoot)
  let weightedInnerRoot = addNode(parser, opMultiply, variableRoot, innerSquareRoot)

  let heightValue = float(cupHeight)
  let bottomValue = float(bottomThickness)
  let outerIntegral = integrateSimpson(parser, outerSquareRoot, 0.0, heightValue)
  let innerIntegral = integrateSimpson(parser, innerSquareRoot, bottomValue, heightValue)
  let fullWeight = glassDensity * outerIntegral
  let airWeight = glassDensity * innerIntegral
  let fullMassCenter = integrateSimpson(parser, weightedOuterRoot, 0.0, heightValue) / outerIntegral
  let airMassCenter = integrateSimpson(parser, weightedInnerRoot, bottomValue, heightValue) / innerIntegral
  let glassWeight = fullWeight - airWeight
  let glassMassCenter = (fullMassCenter * fullWeight - airMassCenter * airWeight) / glassWeight

  var lowLevel = bottomValue
  var highLevel = heightValue
  var waterLevel: float
  if glassMassCenter < lowLevel:
    waterLevel = lowLevel
  elif combinedCenter(parser, innerSquareRoot, weightedInnerRoot, glassMassCenter,
                      glassWeight, bottomValue, highLevel) > highLevel:
    waterLevel = highLevel
  else:
    while highLevel - lowLevel > heightPrecision:
      let middleLevel = (lowLevel + highLevel) / 2.0
      let centerValue = combinedCenter(parser, innerSquareRoot, weightedInnerRoot,
                                      glassMassCenter, glassWeight, bottomValue, middleLevel)
      if middleLevel < centerValue:
        lowLevel = middleLevel
      else:
        highLevel = middleLevel
    waterLevel = (lowLevel + highLevel) / 2.0

  let waterVolume = waterDensity * integrateSimpson(parser, innerSquareRoot, bottomValue, waterLevel)
  let literCount = piValue * waterVolume / 1000.0
  appendOutput("Pour " & formatFloat(literCount, ffDecimal, 3) & " litres / " &
               formatFloat(waterLevel - bottomValue, ffDecimal, 3) & " cm of water.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both expression trees share one node store.
Subtracting cavity mass leaves the glass mass.
The search narrows the level to 0.00001 cm.
One final write flushes every cup line.

## Complexity

Expression evaluation happens once per integration sample.

| phase | time | space |
|---|---|---|
| expression parse | one pass over each expression | one node per token |
| glass integrals | four fixed quadrature passes | node arrays |
| level search | about 24 steps with two integrals each | a few float values |
| output | one buffered sentence per cup | block buffer |

The search stops after roughly 24 halvings of a 100 cm span.

| measure | Big O |
|---|---|
| time | O(P) per integral, with P fixed by `integrationPrecision` |
| space | O(T) for T expression tokens |

Scanning a fine height grid for every trial level would multiply the work. Fixed quadrature plus binary search is the takeaway.

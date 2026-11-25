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

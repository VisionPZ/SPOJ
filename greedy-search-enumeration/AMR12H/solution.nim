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

const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseNow = baseValue mod modulusValue
  var exponentNow = exponentValue
  var resultValue: int64 = 1
  while exponentNow > 0:
    if exponentNow mod 2 == 1:
      resultValue = (resultValue * baseNow) mod modulusValue
    baseNow = (baseNow * baseNow) mod modulusValue
    exponentNow = exponentNow div 2
  return resultValue

proc addChildren(nodeCount: int64, nodeValue: int64, lowValue: int64, highValue: int64, lowTotal: var int64, highTotal: var int64) =
  if nodeCount == 0:
    return
  let firstChild = nodeValue div 2
  let secondChild = (nodeValue + 1) div 2
  if lowValue == highValue:
    lowTotal = lowTotal + nodeCount * 2
  else:
    if firstChild == lowValue:
      lowTotal = lowTotal + nodeCount
    else:
      highTotal = highTotal + nodeCount
    if secondChild == lowValue:
      lowTotal = lowTotal + nodeCount
    else:
      highTotal = highTotal + nodeCount

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let towerHeight = nextInt(inputData, scanPos)
  let flowerCount = nextInt(inputData, scanPos)
  if towerHeight <= 1:
    appendOutput("1")
  else:
    var oddExponent: int64 = 0
    var lowCount: int64 = 1
    var highCount: int64 = 0
    var depth = 0
    while depth < towerHeight - 1:
      let powerAtDepth: int64 = 1 shl depth
      let lowValue: int64 = int64(flowerCount) div powerAtDepth
      let remainder: int64 = int64(flowerCount) mod powerAtDepth
      var highValue = lowValue
      if remainder != 0:
        highValue = highValue + 1
      if lowValue mod 2 == 1:
        oddExponent = oddExponent + lowCount
      if highValue mod 2 == 1:
        oddExponent = oddExponent + highCount
      let nextLowValue = lowValue div 2
      var nextHighValue = (highValue + 1) div 2
      var nextLowCount: int64 = 0
      var nextHighCount: int64 = 0
      addChildren(lowCount, lowValue, nextLowValue, nextHighValue, nextLowCount, nextHighCount)
      addChildren(highCount, highValue, nextLowValue, nextHighValue, nextLowCount, nextHighCount)
      lowCount = nextLowCount
      highCount = nextHighCount
      depth += 1
    appendOutput($(powerMod(2, oddExponent)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

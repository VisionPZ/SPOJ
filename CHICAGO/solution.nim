const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxNodeCount = 100
const stride = maxNodeCount + 1

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc appendProbability(value: float, outputBuffer: var string) =
  let roundedUnits = int(value * 1000000.0 + 0.5)
  let wholePart = roundedUnits div 1000000
  let fractionPart = roundedUnits mod 1000000
  outputBuffer.add $wholePart
  outputBuffer.add '.'
  var divisor = 100000
  while divisor >= 1:
    outputBuffer.add chr(firstDigitValue + (fractionPart div divisor) mod 10)
    divisor = divisor div 10
  outputBuffer.add " percent\n"

var edgeProb: array[stride * stride, float]
var bestProb: array[stride, float]
var visited: array[stride, bool]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

while true:
  let nodeCount = nextInt(inputData, scanPos)
  if nodeCount == 0: break
  let streetCount = nextInt(inputData, scanPos)
  for index in 0 .. stride * stride - 1:
    edgeProb[index] = 0.0
  for streetIndex in 0 ..< streetCount:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let percent = nextInt(inputData, scanPos)
    let chance = float(percent) / 100.0
    let forwardIndex = fromNode * stride + toNode
    let reverseIndex = toNode * stride + fromNode
    if chance > edgeProb[forwardIndex]: edgeProb[forwardIndex] = chance
    if chance > edgeProb[reverseIndex]: edgeProb[reverseIndex] = chance
  for nodeIndex in 0 .. nodeCount:
    bestProb[nodeIndex] = 0.0
    visited[nodeIndex] = false
  bestProb[1] = 1.0
  for pickIndex in 0 ..< nodeCount:
    var chosenNode = 0
    var chosenProb = 0.0
    for nodeIndex in 1 .. nodeCount:
      if not visited[nodeIndex] and bestProb[nodeIndex] > chosenProb:
        chosenProb = bestProb[nodeIndex]
        chosenNode = nodeIndex
    if chosenNode == 0: break
    visited[chosenNode] = true
    if chosenNode == nodeCount: break
    for nodeIndex in 1 .. nodeCount:
      let edgeChance = edgeProb[chosenNode * stride + nodeIndex]
      if edgeChance > 0.0:
        let candidateProb = chosenProb * edgeChance
        if candidateProb > bestProb[nodeIndex]:
          bestProb[nodeIndex] = candidateProb
  appendProbability(bestProb[nodeCount] * 100.0, outputBuffer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

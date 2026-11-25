const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const lowerCaseOffset = 32

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextIntInLine(data: string, pos: var int, lineEnd: int): int =
  while pos < lineEnd and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < lineEnd and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var parentNode = newSeq[int](1)
var componentSize = newSeq[int](1)

proc findRoot(node: int): int =
  var current = node
  while parentNode[current] != current:
    parentNode[current] = parentNode[parentNode[current]]
    current = parentNode[current]
  return current

proc uniteNodes(firstNode: int, secondNode: int) =
  var firstRoot = findRoot(firstNode)
  var secondRoot = findRoot(secondNode)
  if firstRoot == secondRoot:
    return
  if componentSize[firstRoot] < componentSize[secondRoot]:
    let swapRoot = firstRoot
    firstRoot = secondRoot
    secondRoot = swapRoot
  parentNode[secondRoot] = firstRoot
  componentSize[firstRoot] = componentSize[firstRoot] + componentSize[secondRoot]

var lineValues = newSeq[int]()

while scanPos < inputData.len:
  var lineEnd = scanPos
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var cursor = scanPos
  while cursor < lineEnd and inputData[cursor] <= ' ':
    cursor += 1
  if cursor < lineEnd:
    var command = inputData[cursor]
    cursor += 1
    if command >= 'a' and command <= 'z':
      command = chr(int(command) - lowerCaseOffset)
    lineValues.setLen(0)
    while cursor < lineEnd:
      while cursor < lineEnd and inputData[cursor] <= ' ':
        cursor += 1
      if cursor >= lineEnd:
        break
      lineValues.add nextIntInLine(inputData, cursor, lineEnd)
    if command == 'D':
      let planetCount = lineValues[0]
      parentNode.setLen(planetCount + 1)
      componentSize.setLen(planetCount + 1)
      for planetIndex in 0 .. planetCount:
        parentNode[planetIndex] = planetIndex
        componentSize[planetIndex] = 1
    else:
      let sourcePlanet = lineValues[0]
      let destinationPlanet = lineValues[1]
      var pairCount = 1
      var destinationStep = 0
      var sourceStep = 0
      if lineValues.len >= 3:
        pairCount = lineValues[2]
        destinationStep = 1
      if lineValues.len >= 4:
        destinationStep = lineValues[3]
      if lineValues.len >= 5:
        sourceStep = lineValues[4]
      var connectedPairs: int64 = 0
      var disconnectedPairs: int64 = 0
      for pairIndex in 0 .. pairCount - 1:
        let firstPlanet = sourcePlanet + pairIndex * sourceStep
        let secondPlanet = destinationPlanet + pairIndex * destinationStep
        if command == 'C':
          uniteNodes(firstPlanet, secondPlanet)
        else:
          if findRoot(firstPlanet) == findRoot(secondPlanet):
            connectedPairs += 1
          else:
            disconnectedPairs += 1
      if command == 'Q':
        appendOutput($connectedPairs)
        outputBuffer.add ' '
        appendOutput($disconnectedPairs)
        outputBuffer.add '\n'
  scanPos = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0

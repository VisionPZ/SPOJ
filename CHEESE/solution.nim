const flushBlockBytes = 1 shl 17
const uppercaseShift = 32

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

proc isLetter(character: char): bool =
  return (character >= 'A' and character <= 'Z') or (character >= 'a' and character <= 'z')

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not isLetter(data[pos]):
    pos += 1
  var word = ""
  while pos < data.len and isLetter(data[pos]):
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc lowercaseCopy(text: string): string =
  var loweredText = ""
  for character in text:
    if character >= 'A' and character <= 'Z':
      loweredText.add char(int(character) + uppercaseShift)
    else:
      loweredText.add character
  return loweredText

proc evenPalindromePower(text: string): int64 =
  let textLength = text.len
  var radii = newSeq[int](textLength)
  var leftEdge = 0
  var rightEdge = -1
  for center in 0 .. textLength - 1:
    var radius = 0
    if center <= rightEdge:
      let mirror = leftEdge + rightEdge - center + 1
      let available = rightEdge - center + 1
      radius = radii[mirror]
      if radius > available:
        radius = available
    while center + radius < textLength and center - radius - 1 >= 0 and text[center + radius] == text[center - radius - 1]:
      radius += 1
    radii[center] = radius
    if center + radius - 1 > rightEdge:
      leftEdge = center - radius
      rightEdge = center + radius - 1
  var total: int64 = 0
  for radius in radii:
    total = total + int64(radius) * int64(radius + 1)
  return total

proc containsPower(powerList: seq[int64], value: int64): bool =
  for power in powerList:
    if power == value:
      return true
  return false

var flowHead: seq[int]
var flowTarget: seq[int]
var flowNext: seq[int]
var flowCapacity: seq[int64]
var flowLevel: seq[int]
var flowQueue: seq[int]

proc resetFlowGraph(cityCount: int) =
  flowTarget.setLen 0
  flowNext.setLen 0
  flowCapacity.setLen 0
  flowHead = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    flowHead[cityIndex] = -1

proc addFlowEdge(source: int, target: int, capacity: int64) =
  flowTarget.add target
  flowCapacity.add capacity
  flowNext.add flowHead[source]
  flowHead[source] = flowTarget.len - 1
  flowTarget.add source
  flowCapacity.add 0
  flowNext.add flowHead[target]
  flowHead[target] = flowTarget.len - 1

proc buildFlowLevels(source: int, sink: int): bool =
  for cityIndex in 0 .. flowLevel.len - 1:
    flowLevel[cityIndex] = -1
  var queueHead = 0
  var queueTail = 0
  flowLevel[source] = 0
  flowQueue[queueTail] = source
  queueTail += 1
  while queueHead < queueTail:
    let currentCity = flowQueue[queueHead]
    queueHead += 1
    var edgeIndex = flowHead[currentCity]
    while edgeIndex >= 0:
      let targetCity = flowTarget[edgeIndex]
      if flowCapacity[edgeIndex] > 0 and flowLevel[targetCity] < 0:
        flowLevel[targetCity] = flowLevel[currentCity] + 1
        flowQueue[queueTail] = targetCity
        queueTail += 1
      edgeIndex = flowNext[edgeIndex]
  return flowLevel[sink] >= 0

proc sendFlow(currentCity: int, sink: int, available: int64): int64 =
  if currentCity == sink:
    return available
  var edgeIndex = flowHead[currentCity]
  while edgeIndex >= 0:
    let targetCity = flowTarget[edgeIndex]
    if flowCapacity[edgeIndex] > 0 and flowLevel[targetCity] == flowLevel[currentCity] + 1:
      let pushed = sendFlow(targetCity, sink, min(available, flowCapacity[edgeIndex]))
      if pushed > 0:
        flowCapacity[edgeIndex] = flowCapacity[edgeIndex] - pushed
        flowCapacity[edgeIndex xor 1] = flowCapacity[edgeIndex xor 1] + pushed
        return pushed
    edgeIndex = flowNext[edgeIndex]
  return 0

proc maximumFlow(source: int, sink: int): int64 =
  var totalFlow: int64 = 0
  while buildFlowLevels(source, sink):
    while true:
      let pushed = sendFlow(source, sink, int64.high div 4)
      if pushed == 0:
        break
      totalFlow = totalFlow + pushed
  return totalFlow

while true:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let thresholdCount = nextInt(inputData, scanPos)
  if cityCount == 0 and roadCount == 0 and thresholdCount == 0:
    break
  var cityNames = newSeq[string](cityCount)
  var pronunciationPowers = newSeq[int64](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    cityNames[cityIndex] = nextWord(inputData, scanPos)
    pronunciationPowers[cityIndex] = evenPalindromePower(lowercaseCopy(cityNames[cityIndex]))
  var roadStarts = newSeq[int](roadCount)
  var roadEnds = newSeq[int](roadCount)
  var roadLimits = newSeq[int64](roadCount)
  for roadIndex in 0 .. roadCount - 1:
    roadStarts[roadIndex] = nextInt(inputData, scanPos)
    roadEnds[roadIndex] = nextInt(inputData, scanPos)
    roadLimits[roadIndex] = int64(nextInt(inputData, scanPos))
  var topPowers = newSeq[int64]()
  var smallestPower = pronunciationPowers[0]
  for power in pronunciationPowers:
    if power < smallestPower:
      smallestPower = power
  for rankIndex in 0 .. thresholdCount - 1:
    var candidate: int64 = -1
    for cityIndex in 0 .. cityCount - 1:
      let power = pronunciationPowers[cityIndex]
      if power > candidate and not containsPower(topPowers, power):
        candidate = power
    if candidate < 0:
      break
    topPowers.add candidate
  var cutoff = smallestPower
  if topPowers.len >= thresholdCount:
    cutoff = topPowers[topPowers.len - 1]
  var chosenCount = 0
  for cityIndex in 0 .. cityCount - 1:
    if pronunciationPowers[cityIndex] >= cutoff:
      chosenCount += 1
  appendOutput($chosenCount)
  outputBuffer.add '\n'
  flowLevel = newSeq[int](cityCount)
  flowQueue = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    if pronunciationPowers[cityIndex] >= cutoff:
      appendOutput(cityNames[cityIndex])
      appendOutput(" (")
      appendOutput($pronunciationPowers[cityIndex])
      appendOutput(") ")
      if cityIndex == 0:
        appendOutput("0")
      else:
        resetFlowGraph(cityCount)
        for roadIndex in 0 .. roadCount - 1:
          addFlowEdge(roadStarts[roadIndex], roadEnds[roadIndex], roadLimits[roadIndex])
        appendOutput($maximumFlow(0, cityIndex))
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

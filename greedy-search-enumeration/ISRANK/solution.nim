import algorithm

const flushBlockBytes = 1 shl 17
const missingAnswer = -1
const maximumSchools = 10

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

proc compareMarks(leftValue: int, rightValue: int): int =
  return leftValue - rightValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let schoolCount = nextInt(inputData, scanPos)
var schoolSizes = newSeq[int](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  schoolSizes[schoolIndex] = nextInt(inputData, scanPos)
var predictedRanks = newSeq[seq[int]](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  var ranks = newSeq[int](schoolSizes[schoolIndex])
  for studentIndex in 0 .. schoolSizes[schoolIndex] - 1:
    ranks[studentIndex] = nextInt(inputData, scanPos)
  predictedRanks[schoolIndex] = ranks
var actualMarks = newSeq[seq[int]](schoolCount)
var allMarks = newSeq[int](0)
for schoolIndex in 0 .. schoolCount - 1:
  var marks = newSeq[int](schoolSizes[schoolIndex])
  for studentIndex in 0 .. schoolSizes[schoolIndex] - 1:
    marks[studentIndex] = nextInt(inputData, scanPos)
    allMarks.add marks[studentIndex]
  actualMarks[schoolIndex] = marks
allMarks.sort(compareMarks)
var sortedMarks = newSeq[int](0)
for markValue in allMarks:
  if sortedMarks.len == 0 or sortedMarks[sortedMarks.len - 1] != markValue:
    sortedMarks.add markValue
let markCount = sortedMarks.len
var markAtRank = newSeq[seq[int]](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  var rankMarks = newSeq[int](schoolSizes[schoolIndex] + 1)
  for studentIndex in 0 .. schoolSizes[schoolIndex] - 1:
    rankMarks[predictedRanks[schoolIndex][studentIndex]] = actualMarks[schoolIndex][studentIndex]
  markAtRank[schoolIndex] = rankMarks

var leftChild = newSeq[int](1)
var rightChild = newSeq[int](1)
var nodeCounts = newSeq[int](1)
leftChild.add 0
rightChild.add 0
nodeCounts.add 0

proc insertMark(previousRoot: int, domainLow: int, domainHigh: int, position: int): int =
  let newNode = leftChild.len
  leftChild.add 0
  rightChild.add 0
  nodeCounts.add 0
  leftChild[newNode] = leftChild[previousRoot]
  rightChild[newNode] = rightChild[previousRoot]
  nodeCounts[newNode] = nodeCounts[previousRoot] + 1
  if domainLow != domainHigh:
    let domainMiddle = (domainLow + domainHigh) div 2
    if position <= domainMiddle:
      let insertedLeft = insertMark(leftChild[previousRoot], domainLow, domainMiddle, position)
      leftChild[newNode] = insertedLeft
    else:
      let insertedRight = insertMark(rightChild[previousRoot], domainMiddle + 1, domainHigh, position)
      rightChild[newNode] = insertedRight
  return newNode

var versionRoots = newSeq[seq[int]](schoolCount)
for schoolIndex in 0 .. schoolCount - 1:
  var roots = newSeq[int](schoolSizes[schoolIndex] + 1)
  for rankIndex in 1 .. schoolSizes[schoolIndex]:
    let markValue = markAtRank[schoolIndex][rankIndex]
    var markPosition = 1
    var lowBound = 0
    var highBound = markCount - 1
    while lowBound <= highBound:
      let middle = (lowBound + highBound) div 2
      if sortedMarks[middle] < markValue:
        lowBound = middle + 1
      else:
        highBound = middle - 1
    markPosition = lowBound + 1
    roots[rankIndex] = insertMark(roots[rankIndex - 1], 1, markCount, markPosition)
  versionRoots[schoolIndex] = roots

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let selectedCount = nextInt(inputData, scanPos)
  var selectedSchools = newSeq[int](selectedCount)
  for selectedIndex in 0 .. selectedCount - 1:
    selectedSchools[selectedIndex] = nextInt(inputData, scanPos) - 1
  let rankLow = nextInt(inputData, scanPos)
  let rankHigh = nextInt(inputData, scanPos)
  let desiredRank = nextInt(inputData, scanPos)
  var candidateTotal = 0
  for selectedIndex in 0 .. selectedCount - 1:
    let schoolIndex = selectedSchools[selectedIndex]
    let effectiveHigh = rankHigh
    if effectiveHigh >= rankLow and rankLow <= schoolSizes[schoolIndex]:
      let actualHigh = effectiveHigh
      if actualHigh > schoolSizes[schoolIndex]:
        candidateTotal = candidateTotal + schoolSizes[schoolIndex] - rankLow + 1
      else:
        candidateTotal = candidateTotal + actualHigh - rankLow + 1
  if candidateTotal < desiredRank:
    appendOutput($missingAnswer)
    outputBuffer.add '\n'
    continue
  var currentHighRoots = newSeq[int](selectedCount)
  var currentLowRoots = newSeq[int](selectedCount)
  for selectedIndex in 0 .. selectedCount - 1:
    let schoolIndex = selectedSchools[selectedIndex]
    var lowIndex = rankLow - 1
    var highIndex = rankHigh
    if lowIndex > schoolSizes[schoolIndex]:
      lowIndex = schoolSizes[schoolIndex]
    if highIndex > schoolSizes[schoolIndex]:
      highIndex = schoolSizes[schoolIndex]
    if lowIndex < 0:
      lowIndex = 0
    currentLowRoots[selectedIndex] = versionRoots[schoolIndex][lowIndex]
    currentHighRoots[selectedIndex] = versionRoots[schoolIndex][highIndex]
  var domainLow = 1
  var domainHigh = markCount
  var remainingRank = candidateTotal - desiredRank + 1
  while domainLow < domainHigh:
    let domainMiddle = (domainLow + domainHigh) div 2
    var leftTotal = 0
    for selectedIndex in 0 .. selectedCount - 1:
      let highLeft = leftChild[currentHighRoots[selectedIndex]]
      let lowLeft = leftChild[currentLowRoots[selectedIndex]]
      leftTotal = leftTotal + nodeCounts[highLeft] - nodeCounts[lowLeft]
    if remainingRank <= leftTotal:
      for selectedIndex in 0 .. selectedCount - 1:
        currentHighRoots[selectedIndex] = leftChild[currentHighRoots[selectedIndex]]
        currentLowRoots[selectedIndex] = leftChild[currentLowRoots[selectedIndex]]
      domainHigh = domainMiddle
    else:
      remainingRank = remainingRank - leftTotal
      for selectedIndex in 0 .. selectedCount - 1:
        currentHighRoots[selectedIndex] = rightChild[currentHighRoots[selectedIndex]]
        currentLowRoots[selectedIndex] = rightChild[currentLowRoots[selectedIndex]]
      domainLow = domainMiddle + 1
  appendOutput($sortedMarks[domainLow - 1])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

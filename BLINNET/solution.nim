import sequtils
import algorithm

const flushBlockBytes = 1 shl 17

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0

proc nextInt(): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc nextWord(): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var wordStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ': scanPos = scanPos + 1
  return inputData[wordStart .. scanPos - 1]

var parentIndex: seq[int]
var rankLevel: seq[int]

proc findRoot(vertex: int): int =
  var walker = vertex
  while parentIndex[walker] != walker: walker = parentIndex[walker]
  var climber = vertex
  while parentIndex[climber] != walker:
    var nextCity = parentIndex[climber]
    parentIndex[climber] = walker
    climber = nextCity
  return walker

type Connection = tuple[connectionCost: int; firstCity: int; secondCity: int]

proc cheaperConnection(first, second: Connection): int =
  if first.connectionCost < second.connectionCost: return -1
  if first.connectionCost > second.connectionCost: return 1
  return 0

var connectionList: seq[Connection]

var testCount = nextInt()
var outputBuffer: string
for _ in 1 .. testCount:
  var cityCount = nextInt()
  connectionList = newSeq[Connection]()
  for cityIndex in 0 .. cityCount - 1:
    discard nextWord()
    var neighbourCount = nextInt()
    for _ in 1 .. neighbourCount:
      var neighbourIndex = nextInt() - 1
      var connectionCost = nextInt()
      connectionList.add (connectionCost, cityIndex, neighbourIndex)
  var edgeTotal = connectionList.len
  sort(connectionList, cheaperConnection)
  parentIndex = repeat(0, cityCount)
  rankLevel = repeat(0, cityCount)
  for index in 0 .. cityCount - 1: parentIndex[index] = index
  var treeCost = 0
  var treeEdges = 0
  for position in 0 .. edgeTotal - 1:
    var connectionCost = connectionList[position].connectionCost
    var firstRoot = findRoot(connectionList[position].firstCity)
    var secondRoot = findRoot(connectionList[position].secondCity)
    if firstRoot == secondRoot: continue
    if rankLevel[firstRoot] < rankLevel[secondRoot]:
      swap(firstRoot, secondRoot)
    parentIndex[secondRoot] = firstRoot
    if rankLevel[firstRoot] == rankLevel[secondRoot]: rankLevel[firstRoot] += 1
    treeCost = treeCost + connectionCost
    treeEdges = treeEdges + 1
    if treeEdges == cityCount - 1: break
  outputBuffer.add $treeCost
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

import sequtils
import algorithm

const flushBlockBytes = 1 shl 17

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0

proc nextInt(): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc nextWord(): string =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var j = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  return inputData[j .. i - 1]

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
  for j in 0 .. cityCount - 1:
    discard nextWord()
    var neighbourCount = nextInt()
    for _ in 1 .. neighbourCount:
      var neighbourIndex = nextInt() - 1
      var connectionCost = nextInt()
      connectionList.add (connectionCost, j, neighbourIndex)
  var edgeTotal = connectionList.len
  sort(connectionList, cheaperConnection)
  parentIndex = repeat(0, cityCount)
  rankLevel = repeat(0, cityCount)
  for j in 0 .. cityCount - 1: parentIndex[j] = j
  var treeCost = 0
  var treeEdges = 0
  for j in 0 .. edgeTotal - 1:
    var connectionCost = connectionList[j].connectionCost
    var firstRoot = findRoot(connectionList[j].firstCity)
    var secondRoot = findRoot(connectionList[j].secondCity)
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

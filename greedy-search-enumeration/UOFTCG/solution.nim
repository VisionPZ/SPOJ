const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc reverseArc(arc: int): int =
  if (arc mod 2) == 1:
    return arc + 1
  return arc - 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let friendshipCount = nextInt(inputData, scanPos)
  var firstArc = newSeq[int](studentCount + 1)
  var arcTarget = newSeq[int](2 * friendshipCount + 2)
  var nextArc = newSeq[int](2 * friendshipCount + 2)
  var degreeCount = newSeq[int](studentCount + 1)
  var arcCount = 0
  for edgeIndex in 0 .. friendshipCount - 1:
    let leftStudent = nextInt(inputData, scanPos)
    let rightStudent = nextInt(inputData, scanPos)
    arcCount += 1
    arcTarget[arcCount] = rightStudent
    nextArc[arcCount] = firstArc[leftStudent]
    firstArc[leftStudent] = arcCount
    arcCount += 1
    arcTarget[arcCount] = leftStudent
    nextArc[arcCount] = firstArc[rightStudent]
    firstArc[rightStudent] = arcCount
    degreeCount[leftStudent] += 1
    degreeCount[rightStudent] += 1
  var visited = newSeq[int](studentCount + 1)
  var parentVertex = newSeq[int](studentCount + 1)
  var parentArc = newSeq[int](studentCount + 1)
  var traversalOrder = newSeq[int](studentCount + 1)
  var stackNodes = newSeq[int](studentCount + 1)
  var orderSize = 0
  var componentCount = 0
  for startStudent in 1 .. studentCount:
    if visited[startStudent] != 0:
      continue
    componentCount += 1
    var stackTop = 0
    stackTop += 1
    stackNodes[stackTop] = startStudent
    visited[startStudent] = 1
    parentVertex[startStudent] = 0
    parentArc[startStudent] = 0
    while stackTop > 0:
      let currentStudent = stackNodes[stackTop]
      stackTop -= 1
      orderSize += 1
      traversalOrder[orderSize] = currentStudent
      var arc = firstArc[currentStudent]
      while arc != 0:
        let neighbor = arcTarget[arc]
        if parentArc[currentStudent] != 0 and arc == reverseArc(parentArc[currentStudent]):
          arc = nextArc[arc]
          continue
        if visited[neighbor] == 0:
          visited[neighbor] = 1
          parentVertex[neighbor] = currentStudent
          parentArc[neighbor] = arc
          stackTop += 1
          stackNodes[stackTop] = neighbor
        arc = nextArc[arc]
  var passToParent = newSeq[int](studentCount + 1)
  var deletionCount = 0
  for orderIndex in countdown(orderSize, 1):
    let currentStudent = traversalOrder[orderIndex]
    var needed = degreeCount[currentStudent] - 2
    if needed < 0:
      needed = 0
    let covered = passToParent[currentStudent]
    if covered < needed:
      let deficit = needed - covered
      if parentVertex[currentStudent] != 0:
        deletionCount += deficit
        passToParent[parentVertex[currentStudent]] += 1
      else:
        deletionCount += deficit
  let pathCount = componentCount + deletionCount
  let deskCount = studentCount + pathCount - 1
  appendOutput($deskCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const dieFaces = 6
const unreachable = -1

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

proc hasMoreData(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreData(inputData, scanPos):
  let boardRows = nextInt(inputData, scanPos)
  let boardColumns = nextInt(inputData, scanPos)
  let snakeCount = nextInt(inputData, scanPos)
  let ladderCount = nextInt(inputData, scanPos)
  let topSquare = boardRows * boardColumns
  var destination = newSeq[int](topSquare + 1)
  for snakeIndex in 0 ..< snakeCount:
    let snakeHead = nextInt(inputData, scanPos)
    let snakeTail = nextInt(inputData, scanPos)
    destination[snakeHead] = snakeTail
  for ladderIndex in 0 ..< ladderCount:
    let ladderBottom = nextInt(inputData, scanPos)
    let ladderTop = nextInt(inputData, scanPos)
    destination[ladderBottom] = ladderTop
  var finalSquare = newSeq[int](topSquare + 1)
  for square in 1 .. topSquare:
    if finalSquare[square] != 0:
      continue
    var path: seq[int] = @[]
    var current = square
    var steps = 0
    while steps <= topSquare:
      if finalSquare[current] != 0 or destination[current] == 0:
        break
      path.add current
      current = destination[current]
      steps += 1
    var baseSquare = current
    if finalSquare[current] != 0:
      baseSquare = finalSquare[current]
    for node in path:
      finalSquare[node] = baseSquare
    finalSquare[square] = baseSquare
  var distance = newSeq[int](topSquare + 1)
  for square in 0 .. topSquare:
    distance[square] = unreachable
  var queue = newSeq[int](topSquare + 1)
  var queueHead = 0
  var queueTail = 0
  distance[0] = 0
  queue[queueTail] = 0
  queueTail += 1
  while queueHead < queueTail:
    let current = queue[queueHead]
    queueHead += 1
    for dieFace in 1 .. dieFaces:
      let rawSquare = current + dieFace
      if rawSquare > topSquare:
        break
      let landing = finalSquare[rawSquare]
      if distance[landing] == unreachable:
        distance[landing] = distance[current] + 1
        queue[queueTail] = landing
        queueTail += 1
  if distance[topSquare] == unreachable:
    appendOutput("-1")
  else:
    appendOutput($distance[topSquare])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

{.push checks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextField(data: string, pos: var int): char =
  while pos < data.len:
    let c = data[pos]
    if c == 'S' or c == 'M' or c == 'P' or c == 'K' or c == 'w':
      pos += 1
      return c
    pos += 1
  return 'S'

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var stride = 0
var delta: array[4, int]
var blocked: seq[bool]
var edgeBlock: seq[int]
var disc: seq[int]
var lowLink: seq[int]
var parentCell: seq[int]
var edgeStack: seq[int]
var visitStamp: seq[int]
var floodQueue: seq[int]
var distArr: seq[int]
var stateQueue: seq[int]
var stateHead = 0
var stateTail = 0
var stampCounter = 0
var dfsTime = 0
var blockCount = 0

proc tarjanDfs(cell: int) =
  dfsTime += 1
  disc[cell] = dfsTime
  lowLink[cell] = dfsTime
  for d in 0..3:
    let neighbor = cell + delta[d]
    if blocked[neighbor]:
      continue
    if disc[neighbor] == 0:
      parentCell[neighbor] = cell
      let stackTop = edgeStack.len
      edgeStack.add(cell * 4 + d)
      tarjanDfs(neighbor)
      if lowLink[neighbor] < lowLink[cell]:
        lowLink[cell] = lowLink[neighbor]
      if lowLink[neighbor] >= disc[cell]:
        blockCount += 1
        while edgeStack.len > stackTop:
          let edge = edgeStack[edgeStack.len - 1]
          edgeStack.setLen(edgeStack.len - 1)
          let fromCell = edge div 4
          let fromDir = edge mod 4
          let toCell = fromCell + delta[fromDir]
          edgeBlock[fromCell * 4 + fromDir] = blockCount
          edgeBlock[toCell * 4 + (fromDir xor 1)] = blockCount
    elif neighbor != parentCell[cell] and disc[neighbor] < disc[cell]:
      edgeStack.add(cell * 4 + d)
      if disc[neighbor] < lowLink[cell]:
        lowLink[cell] = disc[neighbor]

proc initStart(parcelCell: int, keeperCell: int) =
  blocked[parcelCell] = true
  stampCounter += 1
  let stamp = stampCounter
  var head = 0
  var tail = 0
  floodQueue[tail] = keeperCell
  tail += 1
  visitStamp[keeperCell] = stamp
  while head < tail:
    let cell = floodQueue[head]
    head += 1
    for e in 0..3:
      let nextCell = cell + delta[e]
      if not blocked[nextCell] and visitStamp[nextCell] != stamp:
        visitStamp[nextCell] = stamp
        floodQueue[tail] = nextCell
        tail += 1
  blocked[parcelCell] = false
  for d in 0..3:
    if not blocked[parcelCell + delta[d]] and visitStamp[parcelCell + delta[d]] == stamp:
      let state = parcelCell * 4 + d
      distArr[state] = 0
      stateQueue[stateTail] = state
      stateTail += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let rows = nextInt(inputData, scanPos)
  let cols = nextInt(inputData, scanPos)
  stride = cols + 2
  let cellTotal = (rows + 2) * stride
  delta[0] = -stride
  delta[1] = stride
  delta[2] = -1
  delta[3] = 1
  blocked = newSeq[bool](cellTotal)
  for i in 0..<cellTotal:
    blocked[i] = true
  var parcelCell = 0
  var keeperCell = 0
  var targetCell = 0
  for i in 1..rows:
    for j in 1..cols:
      let field = nextField(inputData, scanPos)
      let cell = i * stride + j
      blocked[cell] = (field == 'S')
      if field == 'P':
        parcelCell = cell
      elif field == 'M':
        keeperCell = cell
      elif field == 'K':
        targetCell = cell
  edgeBlock = newSeq[int](cellTotal * 4)
  for i in 0..<edgeBlock.len:
    edgeBlock[i] = -1
  disc = newSeq[int](cellTotal)
  lowLink = newSeq[int](cellTotal)
  parentCell = newSeq[int](cellTotal)
  for i in 0..<cellTotal:
    parentCell[i] = -1
  edgeStack = newSeq[int](cellTotal * 4)
  dfsTime = 0
  blockCount = 0
  for i in 0..<cellTotal:
    if not blocked[i] and disc[i] == 0:
      tarjanDfs(i)
  visitStamp = newSeq[int](cellTotal)
  floodQueue = newSeq[int](cellTotal)
  distArr = newSeq[int](cellTotal * 4)
  for i in 0..<distArr.len:
    distArr[i] = -1
  stateQueue = newSeq[int](cellTotal * 4)
  stateHead = 0
  stateTail = 0
  var answer = -1
  if parcelCell == targetCell:
    answer = 0
  else:
    initStart(parcelCell, keeperCell)
    while stateHead < stateTail and answer == -1:
      let state = stateQueue[stateHead]
      stateHead += 1
      let parcelHere = state div 4
      let prevDir = state mod 4
      let pushCount = distArr[state]
      for d in 0..3:
        let landingCell = parcelHere + delta[d]
        if blocked[landingCell]:
          continue
        let standDir = d xor 1
        let standCell = parcelHere + delta[standDir]
        if blocked[standCell]:
          continue
        if edgeBlock[parcelHere * 4 + prevDir] != edgeBlock[parcelHere * 4 + standDir]:
          continue
        let nextState = landingCell * 4 + standDir
        if distArr[nextState] == -1:
          distArr[nextState] = pushCount + 1
          if landingCell == targetCell:
            answer = pushCount + 1
            break
          stateQueue[stateTail] = nextState
          stateTail += 1
  if answer == -1:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
{.pop.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const stateSpaceSize = 6250000
const strides = [125000, 2500, 50, 1]

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var distances = newSeq[int](stateSpaceSize)
var queue = newSeq[int](stateSpaceSize)
var visitedStates = newSeq[int](0)

proc minimalMoves(targets: array[4, int], capacities: array[4, int], containerCount: int): int =
  var targetState = 0
  var startState = 0
  for i in 0..<containerCount:
    targetState += targets[i] * strides[i]
    startState += capacities[i] * strides[i]
  if startState == targetState:
    return 0
  let firstVisited = visitedStates.len
  distances[startState] = 1
  queue[0] = startState
  visitedStates.add startState
  var head = 0
  var tail = 1
  var answer = -1
  block search:
    while head < tail:
      let currentState = queue[head]
      head += 1
      let nextDistance = distances[currentState] + 1
      var decoded = currentState
      let amount3 = decoded mod 50
      decoded = decoded div 50
      let amount2 = decoded mod 50
      decoded = decoded div 50
      let amount1 = decoded mod 50
      decoded = decoded div 50
      let amount0 = decoded
      var amounts = [amount0, amount1, amount2, amount3]
      for i in 0..<containerCount:
        let amountI = amounts[i]
        if amountI == 0:
          continue
        let drainedState = currentState - amountI * strides[i]
        if distances[drainedState] == 0:
          if drainedState == targetState:
            answer = nextDistance - 1
            break search
          distances[drainedState] = nextDistance
          queue[tail] = drainedState
          tail += 1
          visitedStates.add drainedState
        for j in 0..<containerCount:
          if j == i:
            continue
          let room = capacities[j] - amounts[j]
          if room == 0:
            continue
          let moved = if amountI < room: amountI else: room
          let pouredState = currentState - moved * strides[i] + moved * strides[j]
          if distances[pouredState] == 0:
            if pouredState == targetState:
              answer = nextDistance - 1
              break search
            distances[pouredState] = nextDistance
            queue[tail] = pouredState
            tail += 1
            visitedStates.add pouredState
  for i in firstVisited..<visitedStates.len:
    distances[visitedStates[i]] = 0
  visitedStates.setLen firstVisited
  return answer

let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let containerCount = nextInt(inputData, scanPos)
  var capacities = [0, 0, 0, 0]
  var targets = [0, 0, 0, 0]
  for i in 0..<containerCount:
    capacities[i] = nextInt(inputData, scanPos)
  for i in 0..<containerCount:
    targets[i] = nextInt(inputData, scanPos)
  let answer = minimalMoves(targets, capacities, containerCount)
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

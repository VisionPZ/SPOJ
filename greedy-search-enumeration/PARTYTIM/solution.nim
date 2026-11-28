const flushBlockBytes = 1 shl 17
const infiniteCost = int64(1000000000000000000)

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let floorCount = nextInt(inputData, scanPos)
  var elevatorAValues = newSeq[int64](floorCount + 1)
  var elevatorBValues = newSeq[int64](floorCount + 1)
  for floorIndex in 0 .. floorCount:
    elevatorAValues[floorIndex] = int64(nextInt(inputData, scanPos))
  for floorIndex in 0 .. floorCount:
    elevatorBValues[floorIndex] = int64(nextInt(inputData, scanPos))
  var waitingPeople = newSeq[int](floorCount)
  for floorIndex in 0 .. floorCount - 1:
    waitingPeople[floorIndex] = nextInt(inputData, scanPos)
  var costActiveA = infiniteCost
  var costActiveB = infiniteCost
  var costActiveBoth: int64 = 0
  var totalPeople = 0
  for floorIndex in 0 .. floorCount - 1:
    totalPeople = totalPeople + waitingPeople[floorIndex]
    let xorStepA = elevatorAValues[floorIndex] xor elevatorAValues[floorIndex + 1]
    let xorStepB = elevatorBValues[floorIndex] xor elevatorBValues[floorIndex + 1]
    var nextA = infiniteCost
    var nextB = infiniteCost
    var nextBoth = infiniteCost
    if costActiveA < infiniteCost:
      nextA = costActiveA + (xorStepA xor int64(totalPeople))
    if costActiveB < infiniteCost:
      nextB = costActiveB + (xorStepB xor int64(totalPeople))
    if costActiveBoth < infiniteCost:
      let aloneA = costActiveBoth + (xorStepA xor int64(totalPeople))
      let aloneB = costActiveBoth + (xorStepB xor int64(totalPeople))
      if aloneA < nextA:
        nextA = aloneA
      if aloneB < nextB:
        nextB = aloneB
      var bestShared = infiniteCost
      for passengersA in 0 .. totalPeople:
        let passengersB = totalPeople - passengersA
        let legCost = (xorStepA xor int64(passengersA)) +
                      (xorStepB xor int64(passengersB))
        if legCost < bestShared:
          bestShared = legCost
      nextBoth = costActiveBoth + bestShared
    costActiveA = nextA
    costActiveB = nextB
    costActiveBoth = nextBoth
  var bestCost = costActiveA
  if costActiveB < bestCost:
    bestCost = costActiveB
  if costActiveBoth < bestCost:
    bestCost = costActiveBoth
  appendOutput($bestCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

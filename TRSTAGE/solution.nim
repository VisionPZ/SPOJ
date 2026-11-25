const flushBlockBytes = 1 shl 17
const timeScale = 2520
const infiniteTime = high(int64) div 4

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

while true:
  let ticketCount = nextInt(inputData, scanPos)
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let startCity = nextInt(inputData, scanPos)
  let targetCity = nextInt(inputData, scanPos)
  if ticketCount == 0 and cityCount == 0 and roadCount == 0 and startCity == 0 and targetCity == 0:
    break
  var ticketFactors = newSeq[int](ticketCount)
  for ticketIndex in 0 .. ticketCount - 1:
    let horseCount = nextInt(inputData, scanPos)
    ticketFactors[ticketIndex] = timeScale div horseCount
  var adjacency = newSeq[seq[int]](cityCount + 1)
  for roadIndex in 0 .. roadCount - 1:
    let firstCity = nextInt(inputData, scanPos)
    let secondCity = nextInt(inputData, scanPos)
    let roadLength = nextInt(inputData, scanPos)
    adjacency[firstCity].add secondCity
    adjacency[firstCity].add roadLength
    adjacency[secondCity].add firstCity
    adjacency[secondCity].add roadLength
  let maskCount = 1 shl ticketCount
  let rowWidth = cityCount + 1
  var bestTimes = newSeq[int64](maskCount * rowWidth)
  for stateIndex in 0 .. bestTimes.len - 1:
    bestTimes[stateIndex] = infiniteTime
  bestTimes[startCity] = 0
  for usedMask in 0 .. maskCount - 1:
    for currentCity in 1 .. cityCount:
      let baseIndex = usedMask * rowWidth + currentCity
      let baseTime = bestTimes[baseIndex]
      if baseTime == infiniteTime:
        continue
      for ticketIndex in 0 .. ticketCount - 1:
        if (usedMask and (1 shl ticketIndex)) != 0:
          continue
        let nextMask = usedMask or (1 shl ticketIndex)
        let rideFactor = ticketFactors[ticketIndex]
        let neighborList = adjacency[currentCity]
        var neighborPos = 0
        while neighborPos < neighborList.len:
          let neighborCity = neighborList[neighborPos]
          let roadLength = neighborList[neighborPos + 1]
          neighborPos += 2
          let candidateTime = baseTime + int64(roadLength * rideFactor)
          let candidateIndex = nextMask * rowWidth + neighborCity
          if candidateTime < bestTimes[candidateIndex]:
            bestTimes[candidateIndex] = candidateTime
  var bestAnswer = infiniteTime
  for usedMask in 0 .. maskCount - 1:
    let candidateTime = bestTimes[usedMask * rowWidth + targetCity]
    if candidateTime < bestAnswer:
      bestAnswer = candidateTime
  if bestAnswer == infiniteTime:
    appendOutput("Impossible\n")
  else:
    let thousandths = (bestAnswer * 1000 + int64(timeScale div 2)) div int64(timeScale)
    let wholePart = thousandths div 1000
    var fractionPart = $(thousandths mod 1000)
    while fractionPart.len < 3:
      fractionPart = "0" & fractionPart
    appendOutput($wholePart & "." & fractionPart & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0

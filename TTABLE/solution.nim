const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const minuteCount = 1440

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendClockTime(minutesValue: int) =
  let hourPart = minutesValue div 60
  let minutePart = minutesValue mod 60
  outputBuffer.add char(firstDigitValue + hourPart div 10)
  outputBuffer.add char(firstDigitValue + hourPart mod 10)
  outputBuffer.add ':'
  outputBuffer.add char(firstDigitValue + minutePart div 10)
  outputBuffer.add char(firstDigitValue + minutePart mod 10)

type JourneyFrontier = seq[tuple[departure: int; arrival: int]]

proc earliestSuffixArrival(frontier: JourneyFrontier, earliestDeparture: int): int =
  if frontier.len == 0: return high(int)
  var lowIndex = 0
  var highIndex = frontier.len - 1
  var foundIndex = -1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if frontier[middleIndex].departure >= earliestDeparture:
      foundIndex = middleIndex
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  if foundIndex < 0: return high(int)
  return frontier[foundIndex].arrival

var departureTimes: seq[int] = @[]
var arrivalTimes: seq[int] = @[]
var sourceCities: seq[int] = @[]
var destinationCities: seq[int] = @[]
var trainOrder: seq[int] = @[]
var departureCounts: array[minuteCount, int]
var nextSlot: array[minuteCount, int]
var cityFrontiers: seq[JourneyFrontier] = @[]
var bestArrivalByCity: seq[int] = @[]
var cityStamp: seq[int] = @[]
var touchedCities: seq[int] = @[]
var stampValue = 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  departureTimes.setLen 0
  arrivalTimes.setLen 0
  sourceCities.setLen 0
  destinationCities.setLen 0
  for cityNumber in 1..cityCount:
    let positionCount = nextInt(inputData, scanPos)
    for positionIndex in 0..<positionCount:
      let departHour = nextInt(inputData, scanPos)
      let departMinute = nextInt(inputData, scanPos)
      let arriveHour = nextInt(inputData, scanPos)
      let arriveMinute = nextInt(inputData, scanPos)
      let targetCity = nextInt(inputData, scanPos)
      departureTimes.add departHour * 60 + departMinute
      arrivalTimes.add arriveHour * 60 + arriveMinute
      sourceCities.add cityNumber
      destinationCities.add targetCity
  let trainCount = departureTimes.len

  for minuteIndex in 0..<minuteCount: departureCounts[minuteIndex] = 0
  for trainIndex in 0..<trainCount:
    departureCounts[departureTimes[trainIndex]] += 1
  var runningSlot = 0
  var minuteIndex = minuteCount - 1
  while minuteIndex >= 0:
    nextSlot[minuteIndex] = runningSlot
    runningSlot += departureCounts[minuteIndex]
    minuteIndex -= 1
  trainOrder.setLen trainCount
  for trainIndex in 0..<trainCount:
    let departTime = departureTimes[trainIndex]
    trainOrder[nextSlot[departTime]] = trainIndex
    nextSlot[departTime] += 1

  cityFrontiers.setLen cityCount + 1
  for cityNumber in 0..cityCount: cityFrontiers[cityNumber].setLen 0
  bestArrivalByCity.setLen cityCount + 1
  cityStamp.setLen cityCount + 1

  var orderIndex = 0
  while orderIndex < trainCount:
    let currentDeparture = departureTimes[trainOrder[orderIndex]]
    var groupEnd = orderIndex
    while groupEnd < trainCount and departureTimes[trainOrder[groupEnd]] == currentDeparture:
      groupEnd += 1
    stampValue += 1
    touchedCities.setLen 0
    for scanIndex in orderIndex..<groupEnd:
      let trainIndex = trainOrder[scanIndex]
      let sourceCity = sourceCities[trainIndex]
      if sourceCity == cityCount: continue
      let targetCity = destinationCities[trainIndex]
      let arrivalTime = arrivalTimes[trainIndex]
      var suffixArrival: int
      if targetCity == cityCount:
        suffixArrival = arrivalTime
      else:
        suffixArrival = earliestSuffixArrival(cityFrontiers[targetCity], arrivalTime)
      if suffixArrival == high(int): continue
      if cityStamp[sourceCity] != stampValue:
        cityStamp[sourceCity] = stampValue
        bestArrivalByCity[sourceCity] = suffixArrival
        touchedCities.add sourceCity
      elif suffixArrival < bestArrivalByCity[sourceCity]:
        bestArrivalByCity[sourceCity] = suffixArrival
    for sourceCity in touchedCities:
      let candidateArrival = bestArrivalByCity[sourceCity]
      let frontierSize = cityFrontiers[sourceCity].len
      if frontierSize > 0 and candidateArrival >= cityFrontiers[sourceCity][frontierSize - 1].arrival: continue
      cityFrontiers[sourceCity].add (currentDeparture, candidateArrival)
    orderIndex = groupEnd

  let answerFrontier = cityFrontiers[1]
  appendOutput($(answerFrontier.len))
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for frontierIndex in 0..<answerFrontier.len:
    let storedIndex = answerFrontier.len - 1 - frontierIndex
    appendClockTime(answerFrontier[storedIndex].departure)
    outputBuffer.add ' '
    appendClockTime(answerFrontier[storedIndex].arrival)
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

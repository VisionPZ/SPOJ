const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const minuteCount = 1440

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
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
  var i = 0
  var j = frontier.len - 1
  var l = -1
  while i <= j:
    let k = (i + j) div 2
    if frontier[k].departure >= earliestDeparture:
      l = k
      i = k + 1
    else:
      j = k - 1
  if l < 0: return high(int)
  return frontier[l].arrival

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

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let cityCount = nextInt(inputData, i)
  departureTimes.setLen 0
  arrivalTimes.setLen 0
  sourceCities.setLen 0
  destinationCities.setLen 0
  for k in 1..cityCount:
    let positionCount = nextInt(inputData, i)
    for l in 0..<positionCount:
      let departHour = nextInt(inputData, i)
      let departMinute = nextInt(inputData, i)
      let arriveHour = nextInt(inputData, i)
      let arriveMinute = nextInt(inputData, i)
      let targetCity = nextInt(inputData, i)
      departureTimes.add departHour * 60 + departMinute
      arrivalTimes.add arriveHour * 60 + arriveMinute
      sourceCities.add k
      destinationCities.add targetCity
  let trainCount = departureTimes.len

  for k in 0..<minuteCount: departureCounts[k] = 0
  for k in 0..<trainCount:
    departureCounts[departureTimes[k]] += 1
  var runningSlot = 0
  var k = minuteCount - 1
  while k >= 0:
    nextSlot[k] = runningSlot
    runningSlot += departureCounts[k]
    k -= 1
  trainOrder.setLen trainCount
  for k in 0..<trainCount:
    let departTime = departureTimes[k]
    trainOrder[nextSlot[departTime]] = k
    nextSlot[departTime] += 1

  cityFrontiers.setLen cityCount + 1
  for k in 0..cityCount: cityFrontiers[k].setLen 0
  bestArrivalByCity.setLen cityCount + 1
  cityStamp.setLen cityCount + 1

  var l = 0
  while l < trainCount:
    let currentDeparture = departureTimes[trainOrder[l]]
    var k = l
    while k < trainCount and departureTimes[trainOrder[k]] == currentDeparture:
      k += 1
    stampValue += 1
    touchedCities.setLen 0
    for i in l..<k:
      let k = trainOrder[i]
      let sourceCity = sourceCities[k]
      if sourceCity == cityCount: continue
      let targetCity = destinationCities[k]
      let arrivalTime = arrivalTimes[k]
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
    l = k

  let answerFrontier = cityFrontiers[1]
  appendOutput($(answerFrontier.len))
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for k in 0..<answerFrontier.len:
    let l = answerFrontier.len - 1 - k
    appendClockTime(answerFrontier[l].departure)
    outputBuffer.add ' '
    appendClockTime(answerFrontier[l].arrival)
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

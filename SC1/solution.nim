const flushBlockBytes = 1 shl 17
const constructionTime = 3
const maximumBuilds = 100

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

proc ceilDivide(value: int, divisor: int): int =
  return (value + divisor - 1) div divisor

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let initialProbes = nextInt(inputData, scanPos)
  let mineralRate = nextInt(inputData, scanPos)
  let gasRate = nextInt(inputData, scanPos)
  let probeCost = nextInt(inputData, scanPos)
  let mineralGoal = nextInt(inputData, scanPos)
  let gasGoal = nextInt(inputData, scanPos)
  var bestTime = maximumBuilds * constructionTime + mineralGoal + gasGoal
  var buildCount = 0
  while buildCount <= maximumBuilds:
    var elapsed = 0
    var savedMinerals = 0
    var activeProbes = initialProbes
    var completionSum = 0
    var lastCompletion = 0
    var usable = true
    for buildIndex in 0 .. buildCount - 1:
      if savedMinerals < probeCost:
        let waitingTime = ceilDivide(probeCost - savedMinerals, activeProbes * mineralRate)
        elapsed += waitingTime
        savedMinerals += activeProbes * mineralRate * waitingTime
      savedMinerals -= probeCost
      savedMinerals += activeProbes * mineralRate * constructionTime
      elapsed += constructionTime
      activeProbes += 1
      completionSum += elapsed
      lastCompletion = elapsed
      if lastCompletion >= bestTime:
        usable = false
        break
    if usable:
      let mineralWork = ceilDivide(mineralGoal + buildCount * probeCost, mineralRate)
      let gasWork = ceilDivide(gasGoal, gasRate)
      let finishingTime = ceilDivide(mineralWork + gasWork + completionSum, initialProbes + buildCount)
      let candidateTime = lastCompletion
      if finishingTime > candidateTime:
        bestTime = min(bestTime, finishingTime)
      else:
        bestTime = min(bestTime, candidateTime)
    buildCount += 1
  appendOutput($(bestTime))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

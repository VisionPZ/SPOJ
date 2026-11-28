const flushBlockBytes = 1 shl 17

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
  let priorityCount = nextInt(inputData, scanPos)
  let grapeCount = nextInt(inputData, scanPos)
  var priorities = newSeq[int](priorityCount)
  var grapes = newSeq[int](grapeCount)
  for priorityIndex in 0 .. priorityCount - 1:
    priorities[priorityIndex] = nextInt(inputData, scanPos)
  for grapeIndex in 0 .. grapeCount - 1:
    grapes[grapeIndex] = nextInt(inputData, scanPos)

  var previousSum = newSeq[int64](grapeCount + 1)
  var previousLength = newSeq[int](grapeCount + 1)
  var currentSum = newSeq[int64](grapeCount + 1)
  var currentLength = newSeq[int](grapeCount + 1)

  for priorityIndex in 1 .. priorityCount:
    currentSum[0] = 0
    currentLength[0] = 0
    for grapeIndex in 1 .. grapeCount:
      var bestSum = previousSum[grapeIndex]
      var bestLength = previousLength[grapeIndex]
      if currentSum[grapeIndex - 1] > bestSum or
         (currentSum[grapeIndex - 1] == bestSum and currentLength[grapeIndex - 1] > bestLength):
        bestSum = currentSum[grapeIndex - 1]
        bestLength = currentLength[grapeIndex - 1]
      if priorities[priorityIndex - 1] == grapes[grapeIndex - 1]:
        let pairedSum = previousSum[grapeIndex - 1] + int64(priorities[priorityIndex - 1])
        let pairedLength = previousLength[grapeIndex - 1] + 1
        if pairedSum > bestSum or (pairedSum == bestSum and pairedLength > bestLength):
          bestSum = pairedSum
          bestLength = pairedLength
      currentSum[grapeIndex] = bestSum
      currentLength[grapeIndex] = bestLength
    swap previousSum, currentSum
    swap previousLength, currentLength

  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $previousSum[grapeCount] & " " & $previousLength[grapeCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

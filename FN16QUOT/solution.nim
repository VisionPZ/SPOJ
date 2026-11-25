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

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreData(inputData, scanPos):
  let runCount = nextInt(inputData, scanPos)
  var quoteRuns = newSeq[int](runCount)
  var totalQuotes = 0
  for runIndex in 0 .. runCount - 1:
    quoteRuns[runIndex] = nextInt(inputData, scanPos)
    totalQuotes += quoteRuns[runIndex]
  var runOfQuote = newSeq[int](totalQuotes)
  var quoteIndex = 0
  for runIndex in 0 .. runCount - 1:
    for quoteInRun in 0 .. quoteRuns[runIndex] - 1:
      runOfQuote[quoteIndex] = runIndex
      quoteIndex += 1
  var maxLevelValue = 1
  while (maxLevelValue + 1) * (maxLevelValue + 2) <= totalQuotes:
    maxLevelValue += 1
  var bestLevel = 0
  var candidateLevel = maxLevelValue
  while candidateLevel >= 2 and bestLevel == 0:
    var feasible = true
    var frontPos = 0
    var frontSize = candidateLevel
    while frontSize >= 1:
      if frontPos + frontSize > totalQuotes:
        feasible = false
        break
      if runOfQuote[frontPos] != runOfQuote[frontPos + frontSize - 1]:
        feasible = false
        break
      frontPos += frontSize
      frontSize -= 1
    if feasible:
      var backPos = totalQuotes
      var backSize = candidateLevel
      while backSize >= 1:
        if backPos - backSize < frontPos:
          feasible = false
          break
        if runOfQuote[backPos - backSize] != runOfQuote[backPos - 1]:
          feasible = false
          break
        backPos -= backSize
        backSize -= 1
      if feasible and (backPos - frontPos) mod 2 == 0:
        bestLevel = candidateLevel
    candidateLevel -= 1
  if bestLevel == 0 and totalQuotes == 2:
    bestLevel = 1
  if bestLevel == 0:
    appendOutput("no quotation")
  else:
    appendOutput($bestLevel)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

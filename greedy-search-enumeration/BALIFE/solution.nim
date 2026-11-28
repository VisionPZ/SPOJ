const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let processorCount = nextInt(inputData, scanPos)
  if processorCount == -1:
    break
  var totalJobs: int64 = 0
  var jobCounts = newSeq[int64](processorCount)
  for processorIndex in 0 .. processorCount - 1:
    let jobCount = int64(nextInt(inputData, scanPos))
    jobCounts[processorIndex] = jobCount
    totalJobs += jobCount
  if (totalJobs mod int64(processorCount)) != 0:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  let targetJobs = totalJobs div int64(processorCount)
  var runningFlow: int64 = 0
  var largestFlow: int64 = 0
  for processorIndex in 0 .. processorCount - 2:
    runningFlow += jobCounts[processorIndex] - targetJobs
    let flowSize = if runningFlow < 0: -runningFlow else: runningFlow
    if flowSize > largestFlow:
      largestFlow = flowSize
  appendOutput($largestFlow)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

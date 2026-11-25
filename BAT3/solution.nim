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
  let peakCount = nextInt(inputData, scanPos)
  let robinIndex = nextInt(inputData, scanPos)
  var peakHeights = newSeq[int](peakCount)
  for peakIndex in 0 .. peakCount - 1:
    peakHeights[peakIndex] = nextInt(inputData, scanPos)
  var downhillEnding = newSeq[int](peakCount)
  for peakIndex in 0 .. peakCount - 1:
    downhillEnding[peakIndex] = 1
    for earlierPeak in 0 .. peakIndex - 1:
      if peakHeights[earlierPeak] > peakHeights[peakIndex]:
        if downhillEnding[earlierPeak] + 1 > downhillEnding[peakIndex]:
          downhillEnding[peakIndex] = downhillEnding[earlierPeak] + 1
  var downhillStarting = newSeq[int](peakCount)
  var reverseIndex = peakCount - 1
  while reverseIndex >= 0:
    downhillStarting[reverseIndex] = 1
    for laterPeak in reverseIndex + 1 .. peakCount - 1:
      if peakHeights[laterPeak] < peakHeights[reverseIndex]:
        if downhillStarting[laterPeak] + 1 > downhillStarting[reverseIndex]:
          downhillStarting[reverseIndex] = downhillStarting[laterPeak] + 1
    reverseIndex -= 1
  var bestStrength = 0
  for peakIndex in 0 .. peakCount - 1:
    if downhillEnding[peakIndex] > bestStrength:
      bestStrength = downhillEnding[peakIndex]
  for landingPeak in robinIndex + 1 .. peakCount - 1:
    let batRoute = downhillEnding[robinIndex] + downhillStarting[landingPeak]
    if batRoute > bestStrength:
      bestStrength = batRoute
  appendOutput($bestStrength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

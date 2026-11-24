const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

let dataSetCount = nextInt(inputData, i)
for j in 0..<dataSetCount:
  let pairCount = nextInt(inputData, i)
  let fixedCount = nextInt(inputData, i)
  var mustOpen = newSeq[bool](2 * pairCount + 1)
  for k in 0..<fixedCount:
    let l = nextInt(inputData, i)
    mustOpen[l] = true
  var ways = newSeq[int64](pairCount + 1)
  ways[0] = 1
  for k in 1..(2 * pairCount):
    var nextWays = newSeq[int64](pairCount + 1)
    for balance in 0..pairCount:
      if ways[balance] == 0:
        continue
      if not mustOpen[k]:
        if balance > 0:
          nextWays[balance - 1] += ways[balance]
      if balance < pairCount:
        nextWays[balance + 1] += ways[balance]
    ways = nextWays
  appendOutput($ways[0])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

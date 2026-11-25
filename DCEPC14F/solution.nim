const flushBlockBytes = 1 shl 17
const primeModulus: int64 = 1000000007

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

proc cyclicProduct(leftPoly: seq[int64], rightPoly: seq[int64], ringSize: int): seq[int64] =
  result = newSeq[int64](ringSize)
  for leftIndex in 0 .. ringSize - 1:
    let leftValue = leftPoly[leftIndex]
    if leftValue == 0:
      continue
    for rightIndex in 0 .. ringSize - 1:
      let rightValue = rightPoly[rightIndex]
      if rightValue == 0:
        continue
      let targetIndex = (leftIndex + rightIndex) mod ringSize
      result[targetIndex] = (result[targetIndex] + leftValue * rightValue) mod primeModulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let kindCount = nextInt(inputData, scanPos)
  var heights = newSeq[int](kindCount)
  for kindIndex in 0 .. kindCount - 1:
    heights[kindIndex] = nextInt(inputData, scanPos)
  let ringSize = nextInt(inputData, scanPos)
  let stackHeight = nextInt(inputData, scanPos)
  let targetHeight = nextInt(inputData, scanPos) mod ringSize
  var basePoly = newSeq[int64](ringSize)
  for kindIndex in 0 .. kindCount - 1:
    let residue = heights[kindIndex] mod ringSize
    basePoly[residue] = (basePoly[residue] + 1) mod primeModulus
  var answerPoly = newSeq[int64](ringSize)
  answerPoly[0] = 1
  var powerPoly = basePoly
  var remaining = stackHeight
  while remaining > 0:
    if remaining mod 2 == 1:
      answerPoly = cyclicProduct(answerPoly, powerPoly, ringSize)
    remaining = remaining div 2
    if remaining > 0:
      powerPoly = cyclicProduct(powerPoly, powerPoly, ringSize)
  appendOutput($answerPoly[targetHeight])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

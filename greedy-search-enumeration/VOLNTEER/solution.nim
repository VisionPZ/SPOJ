import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let studentCount = nextInt(inputData, scanPos)
let chosenCount = nextInt(inputData, scanPos)
var positiveAbs = newSeq[int]()
var negativeAbs = newSeq[int]()
for studentIndex in 0 .. studentCount - 1:
  let score = nextInt(inputData, scanPos)
  if score < 0:
    negativeAbs.add(-score)
  else:
    positiveAbs.add(score)

proc descending(left, right: int): int =
  return right - left

positiveAbs.sort(descending)
negativeAbs.sort(descending)

var positivePrefix = newSeq[int64](positiveAbs.len + 1)
for index in 0 .. positiveAbs.len - 1:
  positivePrefix[index + 1] = positivePrefix[index] + int64(positiveAbs[index])
var negativePrefix = newSeq[int64](negativeAbs.len + 1)
for index in 0 .. negativeAbs.len - 1:
  negativePrefix[index + 1] = negativePrefix[index] + int64(negativeAbs[index])

var bestScore: int64 = -9000000000000000000
var negativeChosen = 0
let highestNegative = if negativeAbs.len < chosenCount: negativeAbs.len else: chosenCount
while negativeChosen <= highestNegative:
  let positiveChosen = chosenCount - negativeChosen
  if positiveChosen <= positiveAbs.len:
    var totalAbs: int64 = 0
    if negativeChosen mod 2 == 0:
      totalAbs = positivePrefix[positiveChosen] + negativePrefix[negativeChosen]
    else:
      let smallestPositives = positivePrefix[positiveAbs.len] - positivePrefix[positiveAbs.len - positiveChosen]
      let smallestNegatives = negativePrefix[negativeAbs.len] - negativePrefix[negativeAbs.len - negativeChosen]
      totalAbs = smallestPositives + smallestNegatives
    let signedScore = if negativeChosen mod 2 == 0: totalAbs else: -totalAbs
    if signedScore > bestScore:
      bestScore = signedScore
  negativeChosen += 1

appendOutput($bestScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

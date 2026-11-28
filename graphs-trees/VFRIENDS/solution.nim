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
  let dogCount = nextInt(inputData, scanPos)
  var wishes = newSeq[int](dogCount)
  var wishTotal: int64 = 0
  var maxWish = -1
  for dogIndex in 0 .. dogCount - 1:
    let currentWish = nextInt(inputData, scanPos)
    wishes[dogIndex] = currentWish
    wishTotal = wishTotal + int64(currentWish)
    if currentWish > maxWish:
      maxWish = currentWish
  var impossible = false
  if wishTotal mod 2 != 0:
    impossible = true
  if maxWish >= dogCount:
    impossible = true
  var degreeCounts = newSeq[int](maxWish + 1)
  for dogIndex in 0 .. dogCount - 1:
    degreeCounts[wishes[dogIndex]] += 1
  var sortedWishes = newSeq[int](dogCount)
  var writeIndex = 0
  var degreeValue = maxWish
  while degreeValue >= 0:
    var repeatCount = degreeCounts[degreeValue]
    while repeatCount > 0:
      sortedWishes[writeIndex] = degreeValue
      writeIndex += 1
      repeatCount -= 1
    degreeValue -= 1
  var prefixSums = newSeq[int64](dogCount + 1)
  for dogIndex in 0 .. dogCount - 1:
    prefixSums[dogIndex + 1] = prefixSums[dogIndex] + int64(sortedWishes[dogIndex])
  var largeCount = dogCount
  for position in 1 .. dogCount:
    while largeCount > 0 and sortedWishes[largeCount - 1] <= position:
      largeCount -= 1
    let leftSum = prefixSums[position]
    var rightSum: int64 = 0
    if largeCount <= position:
      rightSum = wishTotal - prefixSums[position]
    else:
      rightSum = (wishTotal - prefixSums[largeCount]) + int64(position) * int64(largeCount - position)
    let allowance = int64(position) * int64(position - 1) + rightSum
    if leftSum > allowance:
      impossible = true
  if impossible:
    appendOutput("SAD\n")
  else:
    appendOutput("HAPPY\n")
stdout.write outputBuffer
outputBuffer.setLen 0

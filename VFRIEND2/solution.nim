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
  let multiplier = nextInt(inputData, scanPos)
  let increment = nextInt(inputData, scanPos)
  let offsetValue = nextInt(inputData, scanPos)
  let modulus = nextInt(inputData, scanPos)
  var impossible = false
  var wishTotal: int64 = 0
  var maxWish = -1
  var degreeCounts = newSeq[int](0)
  if dogCount > 0:
    degreeCounts = newSeq[int](dogCount)
    var stateValue: int64 = 0
    for dogIndex in 0 .. dogCount - 1:
      let currentWish = int(stateValue) + offsetValue
      if currentWish >= dogCount:
        impossible = true
        break
      degreeCounts[currentWish] += 1
      wishTotal = wishTotal + int64(currentWish)
      if currentWish > maxWish:
        maxWish = currentWish
      stateValue = (int64(multiplier) * stateValue + int64(increment)) mod int64(modulus)
  if not impossible and wishTotal mod 2 != 0:
    impossible = true
  if not impossible and dogCount > 0:
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

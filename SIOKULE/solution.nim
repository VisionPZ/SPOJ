const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigits(data: string, pos: var int): seq[int] =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var reversedDigits = newSeq[int]()
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    reversedDigits.insert(int(data[pos]) - 48, 0)
    pos += 1
  while reversedDigits.len > 1 and reversedDigits[reversedDigits.len - 1] == 0:
    reversedDigits.setLen(reversedDigits.len - 1)
  return reversedDigits

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc addNumbers(leftNumber: seq[int], rightNumber: seq[int]): seq[int] =
  var sumDigits = newSeq[int]()
  var carry = 0
  var digitIndex = 0
  while digitIndex < leftNumber.len or digitIndex < rightNumber.len:
    var digitTotal = carry
    if digitIndex < leftNumber.len:
      digitTotal += leftNumber[digitIndex]
    if digitIndex < rightNumber.len:
      digitTotal += rightNumber[digitIndex]
    sumDigits.add digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1
  if carry > 0:
    sumDigits.add carry
  return sumDigits

proc compareNumbers(leftNumber: seq[int], rightNumber: seq[int]): int =
  if leftNumber.len < rightNumber.len:
    return -1
  if leftNumber.len > rightNumber.len:
    return 1
  for digitIndex in countdown(leftNumber.len - 1, 0):
    if leftNumber[digitIndex] < rightNumber[digitIndex]:
      return -1
    if leftNumber[digitIndex] > rightNumber[digitIndex]:
      return 1
  return 0

proc numberToString(value: seq[int]): string =
  var result = ""
  for digitIndex in countdown(value.len - 1, 0):
    result.add char(48 + value[digitIndex])
  return result

let cubeCount = nextDigits(inputData, scanPos)
var capacityByCost = newSeq[seq[int]]()
capacityByCost.add @[1]
capacityByCost.add @[1]
capacityByCost.add @[1]
capacityByCost.add @[1]

var answerCost = 0
var currentCost = 4
while true:
  var rootPart = 0
  while (rootPart + 1) * (rootPart + 1) <= currentCost:
    rootPart += 1
  var capacity = newSeq[int]()
  for splitIndex in 1 .. rootPart:
    capacity = addNumbers(capacity, capacityByCost[currentCost - splitIndex * splitIndex])
  capacityByCost.add capacity
  if compareNumbers(capacity, cubeCount) >= 0:
    answerCost = currentCost
    break
  currentCost += 1

appendOutput($answerCost)
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

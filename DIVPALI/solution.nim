const flushBlockBytes = 1 shl 17

proc isPalindrome(value: int64): bool =
  let digits = $value
  var leftIndex = 0
  var rightIndex = digits.len - 1
  while leftIndex < rightIndex:
    if digits[leftIndex] != digits[rightIndex]:
      return false
    leftIndex += 1
    rightIndex -= 1
  return true

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

let numberValue = int64(nextInt(inputData, scanPos))
var palindromicDivisors = newSeq[int64]()
var divisorCandidate: int64 = 1
while divisorCandidate * divisorCandidate <= numberValue:
  if numberValue mod divisorCandidate == 0:
    if isPalindrome(divisorCandidate):
      palindromicDivisors.add divisorCandidate
    let pairedDivisor = numberValue div divisorCandidate
    if pairedDivisor != divisorCandidate and isPalindrome(pairedDivisor):
      palindromicDivisors.add pairedDivisor
  divisorCandidate += 1
for outerIndex in 1 .. palindromicDivisors.len - 1:
  let sortValue = palindromicDivisors[outerIndex]
  var innerIndex = outerIndex - 1
  while innerIndex >= 0 and palindromicDivisors[innerIndex] > sortValue:
    palindromicDivisors[innerIndex + 1] = palindromicDivisors[innerIndex]
    innerIndex -= 1
  palindromicDivisors[innerIndex + 1] = sortValue
for divisorIndex in 0 .. palindromicDivisors.len - 1:
  if divisorIndex > 0:
    appendOutput(",")
  appendOutput($palindromicDivisors[divisorIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

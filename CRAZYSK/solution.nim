const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextUInt(data: string, pos: var int): uint64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: uint64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * uint64(10) + uint64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc addDecimalStrings(left: string, right: string): string =
  var leftPos = left.len - 1
  var rightPos = right.len - 1
  var carry = 0
  var reversedDigits = newSeq[char]()
  while leftPos >= 0 or rightPos >= 0 or carry > 0:
    var sum = carry
    if leftPos >= 0:
      sum = sum + int(left[leftPos]) - 48
      leftPos -= 1
    if rightPos >= 0:
      sum = sum + int(right[rightPos]) - 48
      rightPos -= 1
    reversedDigits.add char(sum mod 10 + 48)
    carry = sum div 10
  var sumText = ""
  for digitIndex in 0 .. reversedDigits.len - 1:
    sumText.add reversedDigits[reversedDigits.len - 1 - digitIndex]
  return sumText

let caseCount = int(nextUInt(inputData, scanPos))
for caseNumber in 1 .. caseCount:
  let itemsBought = nextUInt(inputData, scanPos)
  let returnCards = nextUInt(inputData, scanPos)
  let extraItems = (itemsBought - uint64(1)) div (returnCards - uint64(1))
  appendOutput(addDecimalStrings($itemsBought, $extraItems))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

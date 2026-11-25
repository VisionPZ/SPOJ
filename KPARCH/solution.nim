const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var textData = ""
for inputChar in inputData:
  if (inputChar >= 'A' and inputChar <= 'Z') or (inputChar >= 'a' and inputChar <= 'z'):
    textData.add inputChar

proc zFunction(source: string): seq[int] =
  let sourceLength = source.len
  var zValues = newSeq[int](sourceLength)
  var matchLeft = 0
  var matchRight = 0
  var position = 1
  while position < sourceLength:
    if position <= matchRight:
      var candidate = matchRight - position + 1
      if zValues[position - matchLeft] < candidate:
        candidate = zValues[position - matchLeft]
      zValues[position] = candidate
    while position + zValues[position] < sourceLength and
          source[zValues[position]] == source[position + zValues[position]]:
      zValues[position] += 1
    if position + zValues[position] - 1 > matchRight:
      matchLeft = position
      matchRight = position + zValues[position] - 1
    position += 1
  return zValues

proc zValueAt(zValues: seq[int], index: int): int =
  if index >= 0 and index < zValues.len:
    return zValues[index]
  return 0

proc countAtCenter(isLeftSide: bool, halfLength: int, firstMatch: int,
                   secondMatch: int): int64 =
  var lowSplit = halfLength - secondMatch
  if lowSplit < 1:
    lowSplit = 1
  var highSplit = firstMatch
  if highSplit > halfLength:
    highSplit = halfLength
  if highSplit < lowSplit:
    return 0
  var foundCount = highSplit - lowSplit + 1
  if isLeftSide and highSplit == halfLength:
    foundCount -= 1
  return int64(foundCount)

proc countCrossing(text: string, shiftValue: int): int64 =
  let textLength = text.len
  if textLength <= 1:
    return 0
  let leftLength = textLength div 2
  let rightLength = textLength - leftLength
  let leftPart = text[0 ..< leftLength]
  let rightPart = text[leftLength ..< textLength]
  var reversedLeft = ""
  var reversedRight = ""
  var reverseIndex = leftLength - 1
  while reverseIndex >= 0:
    reversedLeft.add leftPart[reverseIndex]
    reverseIndex -= 1
  reverseIndex = rightLength - 1
  while reverseIndex >= 0:
    reversedRight.add rightPart[reverseIndex]
    reverseIndex -= 1

  var total = countCrossing(leftPart, shiftValue) +
              countCrossing(rightPart, shiftValue + leftLength)

  let zReversedLeft = zFunction(reversedLeft)
  let zAcross = zFunction(rightPart & "#" & leftPart)
  let zBothReversed = zFunction(reversedLeft & "#" & reversedRight)
  let zRight = zFunction(rightPart)

  var centerIndex = 0
  while centerIndex < textLength:
    var halfLength: int
    var firstMatch: int
    var secondMatch: int
    if centerIndex < leftLength:
      halfLength = leftLength - centerIndex
      firstMatch = zValueAt(zReversedLeft, leftLength - centerIndex)
      secondMatch = zValueAt(zAcross, rightLength + 1 + centerIndex)
    else:
      halfLength = centerIndex - leftLength + 1
      firstMatch = zValueAt(zBothReversed, leftLength + rightLength -
                            (centerIndex - leftLength))
      secondMatch = zValueAt(zRight, centerIndex - leftLength + 1)
    if firstMatch + secondMatch >= halfLength:
      total += countAtCenter(centerIndex < leftLength, halfLength,
                             firstMatch, secondMatch)
    centerIndex += 1
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let squareCount = countCrossing(textData, 0)
appendOutput($squareCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

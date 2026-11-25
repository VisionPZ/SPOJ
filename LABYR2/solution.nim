const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc reverseDigits(valueToReverse: int): int =
  var reversedValue = 0
  var remainingValue = valueToReverse
  while remainingValue > 0:
    reversedValue = reversedValue * 10 + remainingValue mod 10
    remainingValue = remainingValue div 10
  return reversedValue

proc countDigits(valueToCount: int): int =
  var digitTotal = 0
  var remainingValue = valueToCount
  while remainingValue > 0:
    digitTotal += 1
    remainingValue = remainingValue div 10
  return digitTotal

proc experimentResult(initialValue: int): int =
  var currentValue = initialValue
  var currentNode = 0
  var previousNode = 0
  while true:
    var nextNode = 0
    case currentNode
    of 0:
      if (currentValue div 100) mod 10 <= 7:
        nextNode = 7
      else:
        nextNode = 9
    of 2:
      case currentValue mod 3
      of 0:
        nextNode = 7
      of 1:
        nextNode = 1
      else:
        nextNode = 4
    of 4:
      if reverseDigits(currentValue) > currentValue:
        nextNode = 6
      else:
        nextNode = 2
    of 6:
      if countDigits(currentValue) mod 2 == 0:
        nextNode = 4
      else:
        nextNode = 7
    of 7:
      let squareValue = int64(currentValue) * int64(currentValue) mod 7
      case squareValue
      of 0:
        nextNode = 2
      of 1:
        nextNode = 6
      of 2:
        nextNode = 8
      of 4:
        nextNode = 0
      else:
        nextNode = 2
    of 8:
      let remainderValue = currentValue mod 5
      if remainderValue == 2 or remainderValue == 3:
        nextNode = 7
      else:
        nextNode = 9
    of 9:
      if previousNode == 8:
        nextNode = 0
      else:
        nextNode = 8
    else:
      nextNode = 0
    currentValue = currentValue - 1
    if currentValue == 0:
      return -1
    previousNode = currentNode
    currentNode = nextNode
    if currentNode == 1:
      return currentValue

proc applyWord(wordText: string, smallerPart: var int, totalValue: var int) =
  case wordText
  of "and":
    discard
  of "zero":
    discard
  of "one":
    smallerPart += 1
  of "two":
    smallerPart += 2
  of "three":
    smallerPart += 3
  of "four":
    smallerPart += 4
  of "five":
    smallerPart += 5
  of "six":
    smallerPart += 6
  of "seven":
    smallerPart += 7
  of "eight":
    smallerPart += 8
  of "nine":
    smallerPart += 9
  of "ten":
    smallerPart += 10
  of "eleven":
    smallerPart += 11
  of "twelve":
    smallerPart += 12
  of "thirteen":
    smallerPart += 13
  of "fourteen":
    smallerPart += 14
  of "fifteen":
    smallerPart += 15
  of "sixteen":
    smallerPart += 16
  of "seventeen":
    smallerPart += 17
  of "eighteen":
    smallerPart += 18
  of "nineteen":
    smallerPart += 19
  of "twenty":
    smallerPart += 20
  of "thirty":
    smallerPart += 30
  of "forty":
    smallerPart += 40
  of "fifty":
    smallerPart += 50
  of "sixty":
    smallerPart += 60
  of "seventy":
    smallerPart += 70
  of "eighty":
    smallerPart += 80
  of "ninety":
    smallerPart += 90
  of "hundred":
    smallerPart = smallerPart * 100
  of "thousand":
    totalValue = totalValue + smallerPart * 1000
    smallerPart = 0
  of "million":
    totalValue = totalValue + smallerPart * 1000000
    smallerPart = 0
  else:
    discard

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var currentWord = ""
var smallerPart = 0
var totalValue = 0
var phraseHasWords = false
for inputChar in inputData:
  if inputChar >= 'a' and inputChar <= 'z':
    currentWord.add inputChar
  else:
    if currentWord.len > 0:
      applyWord(currentWord, smallerPart, totalValue)
      currentWord.setLen 0
      phraseHasWords = true
    if inputChar == ' ' or inputChar == '\n' or inputChar == '\r' or inputChar == '\t':
      if phraseHasWords:
        let initialValue = totalValue + smallerPart
        appendOutput($experimentResult(initialValue))
        outputBuffer.add '\n'
        totalValue = 0
        smallerPart = 0
        phraseHasWords = false

stdout.write outputBuffer
outputBuffer.setLen 0

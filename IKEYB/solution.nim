const maxKeyCount = 90
const maxLetterCount = 90
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const infiniteCost = high(int64) div 4

var inputData = ""
var scanPosition = 0
var outputBuffer = ""

var minimumCost: array[0..maxKeyCount + 1, array[0..maxLetterCount + 1, int64]]
var bestSplitAt: array[0..maxKeyCount + 1, array[0..maxLetterCount + 1, int]]
var segmentCost: array[0..maxLetterCount + 1, array[0..maxLetterCount + 1, int64]]
var prefixFrequency: array[0..maxLetterCount + 1, int64]
var prefixWeighted: array[0..maxLetterCount + 1, int64]
var frequencyValues: array[0..maxLetterCount + 1, int64]
var keyCharacters: array[0..maxKeyCount + 1, char]
var letterCharacters: array[0..maxLetterCount + 1, char]
var groupStart: array[0..maxKeyCount + 1, int]
var groupEnd: array[0..maxKeyCount + 1, int]

proc flushOutput() =
  stdout.write outputBuffer
  outputBuffer.setLen 0

proc appendText(textValue: string) =
  outputBuffer.add textValue
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

proc appendCharacter(characterValue: char) =
  outputBuffer.add characterValue
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

proc nextInteger(): int =
  let dataLength = inputData.len
  while scanPosition < dataLength and inputData[scanPosition] != '-' and
      (inputData[scanPosition] < '0' or inputData[scanPosition] > '9'):
    inc scanPosition
  var isNegative = false
  if scanPosition < dataLength and inputData[scanPosition] == '-':
    isNegative = true
    inc scanPosition
  var numberValue = 0
  while scanPosition < dataLength and inputData[scanPosition] >= '0' and
      inputData[scanPosition] <= '9':
    numberValue = numberValue * 10 + (ord(inputData[scanPosition]) - firstDigitValue)
    inc scanPosition
  if isNegative:
    return -numberValue
  return numberValue

proc nextCharacter(): char =
  let dataLength = inputData.len
  while scanPosition < dataLength and inputData[scanPosition] <= ' ':
    inc scanPosition
  result = inputData[scanPosition]
  inc scanPosition

proc main() =
  var lineBuffer = ""
  while readLine(stdin, lineBuffer):
    inputData.add lineBuffer
    inputData.add '\n'

  let testCount = nextInteger()
  for caseIndex in 1..testCount:
    let keyCount = nextInteger()
    let letterCount = nextInteger()

    for keyIndex in 1..keyCount:
      keyCharacters[keyIndex] = nextCharacter()
    for letterIndex in 1..letterCount:
      letterCharacters[letterIndex] = nextCharacter()

    prefixFrequency[0] = 0
    prefixWeighted[0] = 0
    for letterIndex in 1..letterCount:
      frequencyValues[letterIndex] = int64(nextInteger())
      prefixFrequency[letterIndex] = prefixFrequency[letterIndex - 1] + frequencyValues[letterIndex]
      prefixWeighted[letterIndex] = prefixWeighted[letterIndex - 1] +
          frequencyValues[letterIndex] * int64(letterIndex)

    for leftIndex in 1..letterCount:
      for rightIndex in leftIndex..letterCount:
        let frequencySum = prefixFrequency[rightIndex] - prefixFrequency[leftIndex - 1]
        let weightedSum = prefixWeighted[rightIndex] - prefixWeighted[leftIndex - 1]
        segmentCost[leftIndex][rightIndex] = weightedSum - int64(leftIndex - 1) * frequencySum

    for keyIndex in 0..keyCount:
      for letterIndex in 0..letterCount:
        minimumCost[keyIndex][letterIndex] = infiniteCost
        bestSplitAt[keyIndex][letterIndex] = -1
    minimumCost[0][0] = 0
    for keyIndex in 1..keyCount:
      for letterIndex in keyIndex..letterCount:
        var chosenCost = infiniteCost
        var chosenSplit = -1
        for splitIndex in (keyIndex - 1)..(letterIndex - 1):
          if minimumCost[keyIndex - 1][splitIndex] >= infiniteCost:
            continue
          let candidateCost = minimumCost[keyIndex - 1][splitIndex] +
              segmentCost[splitIndex + 1][letterIndex]
          if candidateCost < chosenCost:
            chosenCost = candidateCost
            chosenSplit = splitIndex
        minimumCost[keyIndex][letterIndex] = chosenCost
        bestSplitAt[keyIndex][letterIndex] = chosenSplit

    appendText("Keypad #")
    appendText($caseIndex)
    appendText(":\n")

    var remainingLetters = letterCount
    var keyIndex = keyCount
    while keyIndex >= 1:
      let splitIndex = bestSplitAt[keyIndex][remainingLetters]
      groupStart[keyIndex] = splitIndex + 1
      groupEnd[keyIndex] = remainingLetters
      remainingLetters = splitIndex
      dec keyIndex

    for outputKeyIndex in 1..keyCount:
      appendCharacter(keyCharacters[outputKeyIndex])
      appendText(": ")
      if groupStart[outputKeyIndex] <= groupEnd[outputKeyIndex]:
        for letterIndex in groupStart[outputKeyIndex]..groupEnd[outputKeyIndex]:
          appendCharacter(letterCharacters[letterIndex])
      appendText("\n")
    appendText("\n")

  flushOutput()

main()

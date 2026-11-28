const maxKeyCount = 90
const maxLetterCount = 90
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const infiniteCost = high(int64) div 4

var inputData = ""
var i = 0
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
  while i < dataLength and inputData[i] != '-' and
      (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  var isNegative = false
  if i < dataLength and inputData[i] == '-':
    isNegative = true
    inc i
  var numberValue = 0
  while i < dataLength and inputData[i] >= '0' and
      inputData[i] <= '9':
    numberValue = numberValue * 10 + (ord(inputData[i]) - firstDigitValue)
    inc i
  if isNegative:
    return -numberValue
  return numberValue

proc nextCharacter(): char =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] <= ' ':
    inc i
  result = inputData[i]
  inc i

proc main() =
  var lineBuffer = ""
  while readLine(stdin, lineBuffer):
    inputData.add lineBuffer
    inputData.add '\n'

  let testCount = nextInteger()
  for j in 1..testCount:
    let keyCount = nextInteger()
    let letterCount = nextInteger()

    for k in 1..keyCount:
      keyCharacters[k] = nextCharacter()
    for l in 1..letterCount:
      letterCharacters[l] = nextCharacter()

    prefixFrequency[0] = 0
    prefixWeighted[0] = 0
    for l in 1..letterCount:
      frequencyValues[l] = int64(nextInteger())
      prefixFrequency[l] = prefixFrequency[l - 1] + frequencyValues[l]
      prefixWeighted[l] = prefixWeighted[l - 1] +
          frequencyValues[l] * int64(l)

    for k in 1..letterCount:
      for l in k..letterCount:
        let frequencySum = prefixFrequency[l] - prefixFrequency[k - 1]
        let weightedSum = prefixWeighted[l] - prefixWeighted[k - 1]
        segmentCost[k][l] = weightedSum - int64(k - 1) * frequencySum

    for k in 0..keyCount:
      for l in 0..letterCount:
        minimumCost[k][l] = infiniteCost
        bestSplitAt[k][l] = -1
    minimumCost[0][0] = 0
    for k in 1..keyCount:
      for l in k..letterCount:
        var chosenCost = infiniteCost
        var chosenSplit = -1
        for i in (k - 1)..(l - 1):
          if minimumCost[k - 1][i] >= infiniteCost:
            continue
          let candidateCost = minimumCost[k - 1][i] +
              segmentCost[i + 1][l]
          if candidateCost < chosenCost:
            chosenCost = candidateCost
            chosenSplit = i
        minimumCost[k][l] = chosenCost
        bestSplitAt[k][l] = chosenSplit

    appendText("Keypad #")
    appendText($j)
    appendText(":\n")

    var remainingLetters = letterCount
    var k = keyCount
    while k >= 1:
      let i = bestSplitAt[k][remainingLetters]
      groupStart[k] = i + 1
      groupEnd[k] = remainingLetters
      remainingLetters = i
      dec k

    for l in 1..keyCount:
      appendCharacter(keyCharacters[l])
      appendText(": ")
      if groupStart[l] <= groupEnd[l]:
        for k in groupStart[l]..groupEnd[l]:
          appendCharacter(letterCharacters[k])
      appendText("\n")
    appendText("\n")

  flushOutput()

main()

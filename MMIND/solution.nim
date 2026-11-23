const maxPins = 10
const maxColours = 100
const maxGuesses = 100
const colourStride = maxColours + 1
const flushBlockBytes = 1 shl 18

var inputData = ""
var scanPos = 0
var outputBuffer = ""
var pinCount = 0
var colourCount = 0
var guessCount = 0
var secretColour: array[maxPins, int]
var secretCount: array[colourStride, int]
var guessColour: array[maxGuesses * maxPins, int]
var needCount: array[maxGuesses * colourStride, int]
var requiredBlack: array[maxGuesses, int]
var requiredTotal: array[maxGuesses, int]
var blackSoFar: array[maxGuesses, int]
var totalSoFar: array[maxGuesses, int]

proc readNextInt(): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    inc scanPos
  value

proc searchSecret(depth: int): bool =
  if depth == pinCount:
    return true
  for candidateColour in 1 .. colourCount:
    secretColour[depth] = candidateColour
    inc secretCount[candidateColour]
    var checkedGuesses = 0
    var feasible = true
    while checkedGuesses < guessCount:
      let guessAtPin = guessColour[checkedGuesses * pinCount + depth]
      if guessAtPin == candidateColour:
        inc blackSoFar[checkedGuesses]
      if secretCount[candidateColour] <= needCount[checkedGuesses * colourStride + candidateColour]:
        inc totalSoFar[checkedGuesses]
      inc checkedGuesses
      let remainingPins = pinCount - depth - 1
      if blackSoFar[checkedGuesses - 1] > requiredBlack[checkedGuesses - 1] or
         requiredBlack[checkedGuesses - 1] - blackSoFar[checkedGuesses - 1] > remainingPins or
         totalSoFar[checkedGuesses - 1] > requiredTotal[checkedGuesses - 1] or
         requiredTotal[checkedGuesses - 1] - totalSoFar[checkedGuesses - 1] > remainingPins:
        feasible = false
        break
    if feasible and searchSecret(depth + 1):
      return true
    for guessIndex in 0 ..< checkedGuesses:
      let guessAtPin = guessColour[guessIndex * pinCount + depth]
      if guessAtPin == candidateColour:
        dec blackSoFar[guessIndex]
      if secretCount[candidateColour] <= needCount[guessIndex * colourStride + candidateColour]:
        dec totalSoFar[guessIndex]
    dec secretCount[candidateColour]
  false

var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

let testCount = readNextInt()
for caseIndex in 0 ..< testCount:
  pinCount = readNextInt()
  colourCount = readNextInt()
  guessCount = readNextInt()
  for colourIndex in 0 .. colourCount:
    secretCount[colourIndex] = 0
  for guessIndex in 0 ..< guessCount:
    let needBase = guessIndex * colourStride
    let colourBase = guessIndex * pinCount
    blackSoFar[guessIndex] = 0
    totalSoFar[guessIndex] = 0
    for entryIndex in 0 .. colourCount:
      needCount[needBase + entryIndex] = 0
    for pinIndex in 0 ..< pinCount:
      let guessAtPin = readNextInt()
      guessColour[colourBase + pinIndex] = guessAtPin
      inc needCount[needBase + guessAtPin]
    let blackHint = readNextInt()
    let whiteHint = readNextInt()
    requiredBlack[guessIndex] = blackHint
    requiredTotal[guessIndex] = blackHint + whiteHint
  if not searchSecret(0):
    outputBuffer.add "You are cheating!"
  else:
    for pinIndex in 0 ..< pinCount:
      if pinIndex > 0:
        outputBuffer.add ' '
      outputBuffer.add $secretColour[pinIndex]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

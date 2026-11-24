const maxPins = 10
const maxColours = 100
const maxGuesses = 100
const colourStride = maxColours + 1
const flushBlockBytes = 1 shl 18

var inputData = ""
var i = 0
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
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    inc i
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
    for j in 0 ..< checkedGuesses:
      let guessAtPin = guessColour[j * pinCount + depth]
      if guessAtPin == candidateColour:
        dec blackSoFar[j]
      if secretCount[candidateColour] <= needCount[j * colourStride + candidateColour]:
        dec totalSoFar[j]
    dec secretCount[candidateColour]
  false

var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

let testCount = readNextInt()
for j in 0 ..< testCount:
  pinCount = readNextInt()
  colourCount = readNextInt()
  guessCount = readNextInt()
  for k in 0 .. colourCount:
    secretCount[k] = 0
  for j in 0 ..< guessCount:
    let needBase = j * colourStride
    let colourBase = j * pinCount
    blackSoFar[j] = 0
    totalSoFar[j] = 0
    for l in 0 .. colourCount:
      needCount[needBase + l] = 0
    for l in 0 ..< pinCount:
      let guessAtPin = readNextInt()
      guessColour[colourBase + l] = guessAtPin
      inc needCount[needBase + guessAtPin]
    let blackHint = readNextInt()
    let whiteHint = readNextInt()
    requiredBlack[j] = blackHint
    requiredTotal[j] = blackHint + whiteHint
  if not searchSecret(0):
    outputBuffer.add "You are cheating!"
  else:
    for l in 0 ..< pinCount:
      if l > 0:
        outputBuffer.add ' '
      outputBuffer.add $secretColour[l]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

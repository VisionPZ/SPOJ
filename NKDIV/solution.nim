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

let roundCount = nextInt(inputData, scanPos)
var roundValues = newSeq[int64](roundCount)
var allowedDistinctCounts = newSeq[int](roundCount)
var largestValue: int64 = 0
for roundIndex in 0 .. roundCount - 1:
  roundValues[roundIndex] = int64(nextInt(inputData, scanPos))
  allowedDistinctCounts[roundIndex] = nextInt(inputData, scanPos)
  if roundValues[roundIndex] > largestValue:
    largestValue = roundValues[roundIndex]

var divisorLimit = 1
while int64(divisorLimit) * int64(divisorLimit) <= largestValue:
  divisorLimit += 1

var compositeFlags = newSeq[bool](divisorLimit + 1)
var primeList = newSeq[int]()
var candidate = 2
while candidate <= divisorLimit:
  if not compositeFlags[candidate]:
    primeList.add candidate
    if int64(candidate) * int64(candidate) <= int64(divisorLimit):
      var multiple = candidate * candidate
      while multiple <= divisorLimit:
        compositeFlags[multiple] = true
        multiple += candidate
  candidate += 1

var monaWins = 0
var currentPlayerIsMona = true
for roundIndex in 0 .. roundCount - 1:
  var remaining = roundValues[roundIndex]
  var exponents = newSeq[int]()
  var primeIndex = 0
  while primeIndex < primeList.len and int64(primeList[primeIndex]) * int64(primeList[primeIndex]) <= remaining:
    let primeValue = int64(primeList[primeIndex])
    if remaining mod primeValue == 0:
      var exponentCount = 0
      while remaining mod primeValue == 0:
        remaining = remaining div primeValue
        exponentCount += 1
      exponents.add exponentCount
    primeIndex += 1
  if remaining > 1:
    exponents.add 1
  let modulus = allowedDistinctCounts[roundIndex] + 1
  var winningPosition = false
  var bitPosition = 0
  while bitPosition < 52:
    var bitTotal = 0
    for exponentValue in exponents:
      bitTotal = bitTotal + ((exponentValue shr bitPosition) and 1)
    if bitTotal mod modulus != 0:
      winningPosition = true
      break
    bitPosition += 1
  var roundWinnerIsMona = false
  if winningPosition:
    roundWinnerIsMona = currentPlayerIsMona
  else:
    roundWinnerIsMona = not currentPlayerIsMona
  if roundWinnerIsMona:
    monaWins += 1
    appendOutput("Mona\n")
    currentPlayerIsMona = true
  else:
    appendOutput("Alaa\n")
    currentPlayerIsMona = false

appendOutput("\n")
if monaWins * 2 >= roundCount:
  appendOutput("Mona\n")
else:
  appendOutput("Alaa\n")
stdout.write outputBuffer
outputBuffer.setLen 0

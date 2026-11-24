{.passC: "-O3".}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRoofLevel = 60
const chunkPowers: array[19, int64] = [
  1'i64, 9'i64, 81'i64, 729'i64, 6561'i64, 59049'i64, 531441'i64,
  4782969'i64, 43046721'i64, 387420489'i64, 3486784401'i64,
  31381059609'i64, 282429536481'i64, 2541865828329'i64,
  22876792454961'i64, 205891132094649'i64, 1853020188851841'i64,
  16677181699666569'i64, 150094635296999121'i64
]

const blockOrder: array[3, array[3, int]] = [
  [0, 1, 2],
  [7, 6, 3],
  [8, 5, 4]
]

const blockTransform: array[3, array[3, int]] = [
  [1, 1, 0],
  [2, 2, 0],
  [0, 3, 0]
]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc parseCoordinate(data: string, pos: var int, levelCount: int,
                      digits: var seq[int]) =
  for i in 0 .. levelCount:
    digits[i] = 0
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var usedLen = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    var carry = int(data[pos]) - firstDigitValue
    var i = 0
    while i < usedLen or carry > 0:
      let value = digits[i] * 10 + carry
      digits[i] = value mod 3
      carry = value div 3
      i += 1
    if i > usedLen:
      usedLen = i
    pos += 1
  var i = 0
  while digits[i] == 0:
    digits[i] = 2
    i += 1
  digits[i] -= 1

proc traceSteps(xDigits: seq[int], yDigits: seq[int],
                levelCount: int, steps: var seq[int]) =
  var swapped = false
  var xComplement = false
  var yComplement = false
  for i in 0 .. levelCount - 1:
    let topIndex = levelCount - i - 1
    var colDigit = 0
    var rowDigit = 0
    if swapped:
      colDigit = yDigits[topIndex]
      rowDigit = xDigits[topIndex]
      if yComplement:
        colDigit = 2 - colDigit
      if xComplement:
        rowDigit = 2 - rowDigit
    else:
      colDigit = xDigits[topIndex]
      rowDigit = yDigits[topIndex]
      if xComplement:
        colDigit = 2 - colDigit
      if yComplement:
        rowDigit = 2 - rowDigit
    steps[i] = blockOrder[rowDigit][colDigit]
    let transform = blockTransform[rowDigit][colDigit]
    case transform
    of 1:
      swapped = not swapped
    of 2:
      swapped = not swapped
      xComplement = not xComplement
      yComplement = not yComplement
    of 3:
      xComplement = not xComplement
      yComplement = not yComplement
    else:
      discard

proc appendAnswer(startSteps: seq[int], holeSteps: seq[int], levelCount: int,
                  diffDigits: var seq[int], decimalDigits: var seq[int],
                  outputBuffer: var string) =
  var borrow = 0
  var i = levelCount - 1
  while i >= 0:
    var value = holeSteps[i] - startSteps[i] - borrow
    if value < 0:
      value += 9
      borrow = 1
    else:
      borrow = 0
    diffDigits[i] = value
    i -= 1
  var decimalLen = 1
  decimalDigits[0] = 0
  var chunkStart = 0
  var remaining = levelCount
  while remaining > 0:
    var chunkLen = 18
    if remaining < 18:
      chunkLen = remaining
    let chunkEnd = chunkStart + chunkLen
    var chunkValue: int64 = 0
    for k in chunkStart .. chunkEnd - 1:
      chunkValue = chunkValue * 9 + int64(diffDigits[k])
    let multiplier = chunkPowers[chunkLen]
    var carry = chunkValue
    var j = 0
    while j < decimalLen:
      let value = int64(decimalDigits[j]) * multiplier + carry
      decimalDigits[j] = int(value mod 10)
      carry = value div 10
      j += 1
    while carry > 0:
      decimalDigits[j] = int(carry mod 10)
      carry = carry div 10
      j += 1
    decimalLen = j
    chunkStart = chunkEnd
    remaining -= chunkLen
  i = decimalLen - 1
  while i >= 0:
    outputBuffer.add char(firstDigitValue + decimalDigits[i])
    i -= 1
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var xDigits = newSeq[int](maxRoofLevel + 1)
var yDigits = newSeq[int](maxRoofLevel + 1)
var startSteps = newSeq[int](maxRoofLevel)
var holeSteps = newSeq[int](maxRoofLevel)
var diffDigits = newSeq[int](maxRoofLevel)
var decimalDigits = newSeq[int](maxRoofLevel + 1)
var outputBuffer = ""
for caseIndex in 0 .. caseCount - 1:
  let roofLevel = nextInt(inputData, scanPos)
  parseCoordinate(inputData, scanPos, roofLevel, xDigits)
  parseCoordinate(inputData, scanPos, roofLevel, yDigits)
  traceSteps(xDigits, yDigits, roofLevel, startSteps)
  parseCoordinate(inputData, scanPos, roofLevel, xDigits)
  parseCoordinate(inputData, scanPos, roofLevel, yDigits)
  traceSteps(xDigits, yDigits, roofLevel, holeSteps)
  appendAnswer(startSteps, holeSteps, roofLevel, diffDigits, decimalDigits,
               outputBuffer)
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}

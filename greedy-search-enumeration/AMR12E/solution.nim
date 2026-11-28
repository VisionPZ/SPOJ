const flushBlockBytes = 1 shl 17
const maxLength = 400
const maxTolerance = 10
const answerMod = 1000000007

proc isBitPalindrome(bits: int, width: int): bool =
  var leftIndex = 0
  var rightIndex = width - 1
  while leftIndex < rightIndex:
    if ((bits shr leftIndex) and 1) != ((bits shr rightIndex) and 1):
      return false
    leftIndex += 1
    rightIndex -= 1
  return true

var answerTable: array[maxTolerance + 1, array[maxLength + 1, int64]]
var powerOfTwo: array[maxLength + 1, int64]
powerOfTwo[0] = 1
for lengthIndex in 1 .. maxLength:
  powerOfTwo[lengthIndex] = (powerOfTwo[lengthIndex - 1] * 2) mod answerMod

for tolerance in 1 .. maxTolerance:
  let stateLimit = 1 shl tolerance
  let stateMask = stateLimit - 1
  for lengthIndex in 0 .. tolerance - 1:
    answerTable[tolerance][lengthIndex] = powerOfTwo[lengthIndex]
  var current = newSeq[int64](stateLimit)
  var following = newSeq[int64](stateLimit)
  for state in 0 .. stateLimit - 1:
    if not isBitPalindrome(state, tolerance):
      current[state] = 1
  var initialTotal: int64 = 0
  for state in 0 .. stateLimit - 1:
    initialTotal += current[state]
  answerTable[tolerance][tolerance] = initialTotal mod answerMod
  for lengthIndex in tolerance + 1 .. maxLength:
    for state in 0 .. stateLimit - 1:
      following[state] = 0
    for state in 0 .. stateLimit - 1:
      if current[state] == 0:
        continue
      for bit in 0 .. 1:
        let extended = (state shl 1) or bit
        if isBitPalindrome(extended, tolerance + 1):
          continue
        let nextState = extended and stateMask
        if isBitPalindrome(nextState, tolerance):
          continue
        following[nextState] = (following[nextState] + current[state]) mod answerMod
    for state in 0 .. stateLimit - 1:
      current[state] = following[state]
    var lengthTotal: int64 = 0
    for state in 0 .. stateLimit - 1:
      lengthTotal = (lengthTotal + current[state]) mod answerMod
    answerTable[tolerance][lengthIndex] = lengthTotal

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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let wordLength = nextInt(inputData, scanPos)
  let tolerance = nextInt(inputData, scanPos)
  appendOutput($answerTable[tolerance][wordLength])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

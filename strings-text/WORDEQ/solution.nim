const firstDigitValue = 48
const firstLetterValue = 97
const flushBlockBytes = 1 shl 18
const maxVariableCount = 26
const maxWordSize = 10000
const digitBase = int64(1000000000000000000)
const limbWidth = 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var variableLengths: array[0..maxVariableCount - 1, int]
var variableBase: array[0..maxVariableCount - 1, int]
var totalBits = 0
var bitParent = newSeq[int](maxWordSize + 2)
var bitFixed = newSeq[int](maxWordSize + 2)
var leftBits = newSeq[int](0)
var rightBits = newSeq[int](0)
var cachedExponent = -1
var cachedPower = ""

proc findRoot(bit: int): int =
  var node = bit
  while bitParent[node] != node:
    bitParent[node] = bitParent[bitParent[node]]
    node = bitParent[node]
  return node

proc fixBit(bit: int, value: int, possible: var bool) =
  let root = findRoot(bit)
  if bitFixed[root] == -1:
    bitFixed[root] = value
  elif bitFixed[root] != value:
    possible = false

proc mergeBits(firstBit: int, secondBit: int, possible: var bool) =
  let rootFirst = findRoot(firstBit)
  let rootSecond = findRoot(secondBit)
  if rootFirst == rootSecond: return
  let fixedFirst = bitFixed[rootFirst]
  let fixedSecond = bitFixed[rootSecond]
  if fixedFirst != -1 and fixedSecond != -1 and fixedFirst != fixedSecond:
    possible = false
    return
  bitParent[rootSecond] = rootFirst
  if fixedFirst == -1:
    bitFixed[rootFirst] = fixedSecond

proc buildBits(data: string, position: var int, tokenCount: int, bits: var seq[int]) =
  bits.setLen 0
  for i in 0..<tokenCount:
    while position < data.len and data[position] <= ' ':
      position += 1
    let tokenChar = data[position]
    position += 1
    if tokenChar == '0' or tokenChar == '1':
      bits.add(totalBits + int(tokenChar) - firstDigitValue)
    else:
      let variableIndex = int(tokenChar) - firstLetterValue
      let startBit = variableBase[variableIndex]
      for j in 0..<variableLengths[variableIndex]:
        bits.add(startBit + j)

proc powerText(exponent: int): string =
  var limbs = newSeq[int64](1)
  limbs[0] = 1
  for i in 0..<exponent:
    var carry = int64(0)
    for j in 0..<limbs.len:
      let doubled = limbs[j] * int64(2) + carry
      if doubled >= digitBase:
        limbs[j] = doubled - digitBase
        carry = int64(1)
      else:
        limbs[j] = doubled
        carry = int64(0)
    if carry != 0: limbs.add int64(1)
  var text = $limbs[limbs.len - 1]
  var j = limbs.len - 2
  while j >= 0:
    var limbText = $limbs[j]
    while limbText.len < limbWidth:
      limbText = "0" & limbText
    text.add limbText
    j -= 1
  return text

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let variableCount = nextInt(inputData, scanPos)
  totalBits = 0
  for i in 0..<variableCount:
    variableLengths[i] = nextInt(inputData, scanPos)
    variableBase[i] = totalBits
    totalBits += variableLengths[i]
  if totalBits >= bitParent.len:
    bitParent.setLen(totalBits + 1)
    bitFixed.setLen(totalBits + 1)
  for i in 0..<totalBits:
    bitParent[i] = i
    bitFixed[i] = -1
  let leftTokenCount = nextInt(inputData, scanPos)
  buildBits(inputData, scanPos, leftTokenCount, leftBits)
  let rightTokenCount = nextInt(inputData, scanPos)
  buildBits(inputData, scanPos, rightTokenCount, rightBits)
  var possible = true
  if leftBits.len == rightBits.len:
    for i in 0..<leftBits.len:
      let leftCode = leftBits[i]
      let rightCode = rightBits[i]
      if leftCode >= totalBits:
        if rightCode >= totalBits:
          if leftCode != rightCode: possible = false
        else:
          fixBit(rightCode, leftCode - totalBits, possible)
      else:
        if rightCode >= totalBits:
          fixBit(leftCode, rightCode - totalBits, possible)
        else:
          mergeBits(leftCode, rightCode, possible)
  else:
    possible = false
  if not possible:
    appendOutput("0")
  else:
    var freeCount = 0
    for i in 0..<totalBits:
      if bitParent[i] == i and bitFixed[i] == -1:
        freeCount += 1
    if freeCount != cachedExponent:
      cachedPower = powerText(freeCount)
      cachedExponent = freeCount
    appendOutput(cachedPower)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

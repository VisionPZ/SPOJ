const firstDigitValue = 48
const decimalBase = 1000000000
const topDigitPlace = 100000000
const limbCapacity = 8
const stateCount = 4
const flushBlockBytes = 1 shl 18

type Big = object
  limb: array[0..limbCapacity-1, int]
  used: int

proc bigAdd(dst: var Big, src: Big) =
  if src.used == 0: return
  var carry = 0
  var k = 0
  while k < src.used or carry != 0:
    var value = carry
    if k < dst.used: value += dst.limb[k]
    if k < src.used: value += src.limb[k]
    if value >= decimalBase:
      value -= decimalBase
      carry = 1
    else:
      carry = 0
    dst.limb[k] = value
    k += 1
  if k > dst.used: dst.used = k

proc scanNumber(data: string, position: var int): seq[int] =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  result = @[0]
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    var carry = int(data[position]) - firstDigitValue
    for k in 0..<result.len:
      var value = result[k] * 10 + carry
      result[k] = value mod decimalBase
      carry = value div decimalBase
    if carry > 0: result.add carry
    position += 1

proc limbsToInt(limbs: seq[int]): int =
  if limbs.len > 0: limbs[0] else: 0

proc numberBits(limbs: seq[int], bitTotal: int): seq[int] =
  var work = limbs
  result.setLen(bitTotal)
  for i in 0..<bitTotal:
    var remainder = 0
    var k = work.len - 1
    while k >= 0:
      var value = remainder * decimalBase + work[k]
      work[k] = value div 2
      remainder = value mod 2
      k -= 1
    result[i] = remainder

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = limbsToInt(scanNumber(inputData, scanPos))

var dp: array[0..stateCount-1, Big]
var nextDp: array[0..stateCount-1, Big]
var outputBuffer = ""
var answerLine = ""

proc appendBig(dst: var string, value: Big) =
  if value.used == 0:
    dst.add '0'
    return
  var k = value.used - 1
  dst.add $value.limb[k]
  k -= 1
  while k >= 0:
    var limbValue = value.limb[k]
    var place = topDigitPlace
    while place > 0:
      dst.add char(limbValue div place + firstDigitValue)
      limbValue = limbValue mod place
      place = place div 10
    k -= 1

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0..<caseCount:
  let sizeLimbs = scanNumber(inputData, scanPos)
  let matrixSize = limbsToInt(sizeLimbs)
  let shiftDownBits = numberBits(scanNumber(inputData, scanPos), matrixSize + 1)
  let shiftRightBits = numberBits(scanNumber(inputData, scanPos), matrixSize + 1)
  var answer: Big
  if shiftRightBits[matrixSize] == 1 or shiftDownBits[matrixSize] == 1:
    answer.used = 0
  else:
    for j in 0..<stateCount:
      dp[j].used = 0
    dp[0].limb[0] = 1
    dp[0].used = 1
    for i in 0..<matrixSize:
      for j in 0..<stateCount: nextDp[j].used = 0
      let downBit = shiftDownBits[i]
      let rightBit = shiftRightBits[i]
      for j in 0..<stateCount:
        if dp[j].used == 0: continue
        let carryIn = j div 2
        let borrowIn = j mod 2
        for l in 0..2:
          let rowBit = if l == 0: 0 else: 1
          let colBit = if l == 1: 0 else: 1
          let sumValue = rowBit + downBit + carryIn
          let primeRowBit = sumValue mod 2
          let carryOut = sumValue div 2
          let diffValue = colBit - rightBit - borrowIn
          var primeColBit: int
          var borrowOut: int
          if diffValue >= 0:
            primeColBit = diffValue
            borrowOut = 0
          else:
            primeColBit = diffValue + 2
            borrowOut = 1
          if primeRowBit == 0 and primeColBit == 0: continue
          bigAdd(nextDp[carryOut * 2 + borrowOut], dp[j])
      dp = nextDp
    answer = dp[0]
  answerLine.setLen 0
  appendBig(answerLine, answer)
  answerLine.add '\n'
  appendOutput(answerLine)

stdout.write outputBuffer
outputBuffer.setLen 0

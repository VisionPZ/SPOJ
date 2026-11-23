const flushBlockBytes = 1 shl 18
const limbBase = 1000000000
const firstDigitValue = 48

type BigInt = seq[int64]

var inputData = ""
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = result * 10 + int(data[pos]) - firstDigitValue
    pos += 1

proc addBig(left, right: BigInt): BigInt =
  let maxLen = max(left.len, right.len)
  result = newSeq[int64](maxLen + 1)
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < maxLen:
    var partSum: int64 = carry
    if limbIndex < left.len: partSum += left[limbIndex]
    if limbIndex < right.len: partSum += right[limbIndex]
    if partSum >= limbBase:
      partSum -= limbBase
      carry = 1
    else:
      carry = 0
    result[limbIndex] = partSum
    limbIndex += 1
  result[maxLen] = carry
  if carry == 0: result.setLen(maxLen)

proc appendBig(output: var string, value: BigInt) =
  if value.len == 0:
    output.add char(firstDigitValue)
    return
  var highest = value.len - 1
  output.add $value[highest]
  while highest > 0:
    highest -= 1
    var place = limbBase div 10
    while place > 0:
      output.add char(firstDigitValue + (value[highest] div place) mod 10)
      place = place div 10

var scanPos = 0
var datasetCount = nextInt(inputData, scanPos)
var queryN = newSeq[int](datasetCount)
var queryK = newSeq[int](datasetCount)
var maxN = 0
var maxK = 0
for queryIndex in 0..<datasetCount:
  let currentN = nextInt(inputData, scanPos)
  let currentK = nextInt(inputData, scanPos)
  queryN[queryIndex] = currentN
  queryK[queryIndex] = currentK
  if currentN > maxN: maxN = currentN
  if currentK > maxK: maxK = currentK

var dp = newSeq[seq[BigInt]](maxN + 1)
for lengthIndex in 0..maxN:
  dp[lengthIndex] = newSeq[BigInt](maxK + 1)
dp[0][0] = @[1'i64]
for lengthIndex in 1..maxN:
  dp[lengthIndex][0] = @[1'i64]
  for invCount in 1..maxK:
    var total: BigInt = @[]
    let upperAdded = min(invCount, lengthIndex - 1)
    for added in 0..upperAdded:
      total = addBig(total, dp[lengthIndex - 1][invCount - added])
    dp[lengthIndex][invCount] = total

var outputBuffer = ""
for queryIndex in 0..<datasetCount:
  appendBig(outputBuffer, dp[queryN[queryIndex]][queryK[queryIndex]])
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

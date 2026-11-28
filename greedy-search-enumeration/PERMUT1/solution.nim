const flushBlockBytes = 1 shl 18
const limbBase = 1000000000
const firstDigitValue = 48

type BigInt = seq[int64]

var inputData = ""
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + int(data[i]) - firstDigitValue
    i += 1

proc addBig(left, right: BigInt): BigInt =
  let maxLen = max(left.len, right.len)
  result = newSeq[int64](maxLen + 1)
  var carry: int64 = 0
  var i = 0
  while i < maxLen:
    var partSum: int64 = carry
    if i < left.len: partSum += left[i]
    if i < right.len: partSum += right[i]
    if partSum >= limbBase:
      partSum -= limbBase
      carry = 1
    else:
      carry = 0
    result[i] = partSum
    i += 1
  result[maxLen] = carry
  if carry == 0: result.setLen(maxLen)

proc appendBig(output: var string, value: BigInt) =
  if value.len == 0:
    output.add char(firstDigitValue)
    return
  var i = value.len - 1
  output.add $value[i]
  while i > 0:
    i -= 1
    var j = limbBase div 10
    while j > 0:
      output.add char(firstDigitValue + (value[i] div j) mod 10)
      j = j div 10

var i = 0
var datasetCount = nextInt(inputData, i)
var queryN = newSeq[int](datasetCount)
var queryK = newSeq[int](datasetCount)
var maxN = 0
var maxK = 0
for j in 0..<datasetCount:
  let currentN = nextInt(inputData, i)
  let currentK = nextInt(inputData, i)
  queryN[j] = currentN
  queryK[j] = currentK
  if currentN > maxN: maxN = currentN
  if currentK > maxK: maxK = currentK

var dp = newSeq[seq[BigInt]](maxN + 1)
for j in 0..maxN:
  dp[j] = newSeq[BigInt](maxK + 1)
dp[0][0] = @[1'i64]
for j in 1..maxN:
  dp[j][0] = @[1'i64]
  for invCount in 1..maxK:
    var total: BigInt = @[]
    let upperAdded = min(invCount, j - 1)
    for added in 0..upperAdded:
      total = addBig(total, dp[j - 1][invCount - added])
    dp[j][invCount] = total

var outputBuffer = ""
for j in 0..<datasetCount:
  appendBig(outputBuffer, dp[queryN[j]][queryK[j]])
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

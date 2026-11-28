import math, tables

const
  sieveLimit = 5000000
  phiCacheX = 2000
  phiCacheA = 64

var inputData, line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'

var scanPos = 0
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'): pos += 1
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = result * 10 + int(data[pos]) - 48
    pos += 1

let halfLimit = sieveLimit div 2
var compBits = newSeq[uint64]((halfLimit shr 6) + 1)
for idx in 1 .. (int(sqrt(float64(sieveLimit))) + 1) div 2:
  if (compBits[idx shr 6] and (1'u64 shl (idx and 63))) == 0'u64:
    let prime = 2 * idx + 1
    var mult = (prime * prime) shr 1
    while mult <= halfLimit:
      compBits[mult shr 6] = compBits[mult shr 6] or (1'u64 shl (mult and 63))
      mult += prime

var primeList = @[2'i32]
var primePrefix = newSeq[int32](sieveLimit + 1)
primePrefix[2] = 1'i32
var seen: int32 = 1
for num in 3 .. sieveLimit:
  if (num and 1) == 1 and (compBits[num shr 7] and (1'u64 shl ((num shr 1) and 63))) == 0'u64:
    primeList.add int32(num)
    seen += 1
  primePrefix[num] = seen

var smallPhi = newSeq[int32](phiCacheX * phiCacheA)
for x in 0 .. phiCacheX - 1: smallPhi[x * phiCacheA] = int32(x)
for a in 1 .. phiCacheA - 1:
  let p = int(primeList[a - 1])
  for x in 0 .. phiCacheX - 1:
    let row = x * phiCacheA + a
    smallPhi[row] = smallPhi[row - 1] - smallPhi[(x div p) * phiCacheA + a - 1]

var piCache = initTable[int64, int64]()

proc phiCount(val: int64, cnt: int): int64 =
  if cnt == 0: return val
  if val == 0: return 0
  if cnt == 1: return val - (val shr 1)
  if val < phiCacheX and cnt < phiCacheA: return int64(smallPhi[int(val) * phiCacheA + cnt])
  let lastP = int64(primeList[cnt - 1])
  if val <= lastP: return 1
  if val <= int64(sieveLimit) and val < lastP * lastP: return int64(primePrefix[int(val)]) - int64(cnt) + 1
  return phiCount(val, cnt - 1) - phiCount(val div lastP, cnt - 1)

proc integerRoot(val: int64, deg: int): int64 =
  var root =
    if deg == 2: int64(sqrt(float64(val)))
    elif deg == 3: int64(pow(float64(val), 1.0 / 3.0))
    else: int64(sqrt(sqrt(float64(val))))
  proc fits(base: int64): bool =
    var prod: int64 = 1
    for i in 1 .. deg:
      if prod > val div base: return false
      prod *= base
    return true
  while fits(root + 1): root += 1
  while not fits(root): root -= 1
  return root

proc primePi(val: int64): int64 =
  if val <= int64(sieveLimit): return int64(primePrefix[int(val)])
  if piCache.hasKey(val): return piCache[val]
  let smallCnt = int(primePi(integerRoot(val, 4)))
  let cubeCnt = int(primePi(integerRoot(val, 3)))
  let largeCnt = int(primePi(integerRoot(val, 2)))
  var total = phiCount(val, smallCnt) +
    int64(largeCnt + smallCnt - 2) * int64(largeCnt - smallCnt + 1) div 2
  for idx in smallCnt .. largeCnt - 1:
    let quot = val div int64(primeList[idx])
    total -= primePi(quot)
    if idx < cubeCnt:
      let lim = int(primePi(integerRoot(quot, 2)))
      for subIdx in idx .. lim - 1:
        total -= primePi(quot div int64(primeList[subIdx])) - int64(subIdx)
  piCache[val] = total
  return total

let wanted = int64(nextInt(inputData, scanPos))
var answer: int64
if wanted <= int64(primeList.len):
  answer = int64(primeList[int(wanted) - 1])
else:
  var lowVal = int64(primeList[primeList.len - 1])
  let approx = float64(wanted)
  let logN = ln(approx)
  let logLogN = ln(logN)
  var highVal =
    if wanted >= 688383:
      lowVal = max(lowVal, int64(approx * (logN + logLogN - 1.0 + (logLogN - 2.1) / logN)))
      int64(approx * (logN + logLogN - 1.0 + (logLogN - 2.0) / logN)) + 100
    else:
      int64(approx * (logN + logLogN)) + 100
  if highVal <= lowVal: highVal = lowVal + 1000
  while lowVal < highVal:
    let midVal = lowVal + (highVal - lowVal) div 2
    if primePi(midVal) >= wanted: highVal = midVal
    else: lowVal = midVal + 1
  answer = lowVal

stdout.write($answer & "\n")

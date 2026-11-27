const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc readInputBytes(): string =
  const chunkSize = 1 shl 14
  var res = ""
  var buf = newString(chunkSize)
  while true:
    let got = readBuffer(stdin, addr buf[0], chunkSize)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr buf[0], got)
  res

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var val = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    val = val * 10 + (int(data[pos]) - firstDigitValue)
    pos += 1
  val

var outBuffer = newStringOfCap(flushBlockBytes + 64)

proc appendInt64Line(val: int64) =
  outBuffer.add $val
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc sortSlice(arr: var seq[int], lo: int, hi: int) =
  if lo >= hi:
    return
  let pivot = arr[(lo + hi) shr 1]
  var leftIdx = lo
  var rightIdx = hi
  while leftIdx <= rightIdx:
    while arr[leftIdx] < pivot:
      leftIdx += 1
    while arr[rightIdx] > pivot:
      rightIdx -= 1
    if leftIdx <= rightIdx:
      let tmp = arr[leftIdx]
      arr[leftIdx] = arr[rightIdx]
      arr[rightIdx] = tmp
      leftIdx += 1
      rightIdx -= 1
  if lo < rightIdx:
    sortSlice(arr, lo, rightIdx)
  if leftIdx < hi:
    sortSlice(arr, leftIdx, hi)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let caseCount = nextInt(inputData, scanPos)
  var menRates = newSeq[int](1005)
  var womenRates = newSeq[int](1005)

  for caseIdx in 0 ..< caseCount:
    let pairCount = nextInt(inputData, scanPos)
    if pairCount > menRates.len:
      menRates.setLen(pairCount)
      womenRates.setLen(pairCount)
    for idx in 0 ..< pairCount:
      menRates[idx] = nextInt(inputData, scanPos)
    for idx in 0 ..< pairCount:
      womenRates[idx] = nextInt(inputData, scanPos)
    sortSlice(menRates, 0, pairCount - 1)
    sortSlice(womenRates, 0, pairCount - 1)
    var totalBond = 0'i64
    for idx in 0 ..< pairCount:
      totalBond += int64(menRates[idx]) * int64(womenRates[idx])
    appendInt64Line(totalBond)

  if outBuffer.len > 0:
    stdout.write outBuffer

main()

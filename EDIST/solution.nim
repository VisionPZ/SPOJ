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

proc nextTokenSpan(data: string, pos: var int): tuple[lo: int, hi: int] =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startIdx = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  result = (startIdx, pos)

var outBuffer = newStringOfCap(flushBlockBytes + 64)

proc appendIntLine(val: int) =
  outBuffer.add $val
  outBuffer.add '\n'
  if outBuffer.len >= flushBlockBytes:
    stdout.write outBuffer
    outBuffer.setLen(0)

proc editDistance(
    data: string,
    spanA: tuple[lo: int, hi: int],
    spanB: tuple[lo: int, hi: int],
    prevRow: var seq[int],
    currRow: var seq[int]
): int =
  let lenA = spanA.hi - spanA.lo
  let lenB = spanB.hi - spanB.lo
  if lenB + 1 > prevRow.len:
    prevRow.setLen(lenB + 1)
    currRow.setLen(lenB + 1)
  for col in 0 .. lenB:
    prevRow[col] = col
  for row in 1 .. lenA:
    currRow[0] = row
    let charA = data[spanA.lo + row - 1]
    for col in 1 .. lenB:
      let repCost = prevRow[col - 1] + (if charA == data[spanB.lo + col - 1]: 0 else: 1)
      let delCost = prevRow[col] + 1
      let insCost = currRow[col - 1] + 1
      var best = if repCost < delCost: repCost else: delCost
      if insCost < best:
        best = insCost
      currRow[col] = best
    for col in 0 .. lenB:
      prevRow[col] = currRow[col]
  prevRow[lenB]

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let caseCount = nextInt(inputData, scanPos)
  var prevRow = newSeq[int](2005)
  var currRow = newSeq[int](2005)
  for caseIdx in 0 ..< caseCount:
    let spanA = nextTokenSpan(inputData, scanPos)
    let spanB = nextTokenSpan(inputData, scanPos)
    appendIntLine(editDistance(inputData, spanA, spanB, prevRow, currRow))
  if outBuffer.len > 0:
    stdout.write outBuffer

main()

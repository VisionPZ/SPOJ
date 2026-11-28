const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var path: seq[int32]
var aux: seq[int32]

proc fillPath(startPos, startN, startK: int, startBase, startStep: int32) =
  var writePos = startPos
  var curN = startN
  var curK = startK
  var base = startBase
  var step = startStep

  while true:
    if curK > (curN + 1) shr 1:
      base = base + step * int32(curN - 1)
      step = -step
      curK = curN + 1 - curK

    if curN == 1:
      path[writePos] = base
      return

    if curK == 1:
      var left = 1
      var right = curN
      var pos = writePos
      while left <= right:
        path[pos] = base + step * int32(left - 1)
        pos += 1
        left += 1
        if left <= right:
          path[pos] = base + step * int32(right - 1)
          pos += 1
          right -= 1
      return

    if curN == 2 * curK - 1:
      var cur = curK
      path[writePos] = base + step * int32(cur - 1)
      for delta in 1 ..< curN:
        if (delta and 1) == 1:
          cur -= delta
        else:
          cur += delta
        path[writePos + delta] = base + step * int32(cur - 1)
      return

    if curN == 2 * curK:
      var cur = curK
      path[writePos] = base + step * int32(cur - 1)
      for delta in 1 ..< curN:
        if (delta and 1) == 1:
          cur += delta
        else:
          cur -= delta
        path[writePos + delta] = base + step * int32(cur - 1)
      return

    if curN >= 3 * curK - 1:
      var pos = writePos
      for idx in 0 ..< curK:
        path[pos] = base + step * int32(curK - idx - 1)
        pos += 1
        if idx < curK - 1:
          path[pos] = base + step * int32(curN - curK + 1 + idx)
          pos += 1
      writePos = pos
      base = base + step * int32(curK)
      let nextN = curN - 2 * curK + 1
      let nextK = curN - 3 * curK + 2
      curN = nextN
      curK = nextK
      continue

    let side = curK - 1
    let midLen = curN - 2 * side
    var pos = writePos
    var left = 1
    var right = midLen
    var lastRel = 1
    while left <= right:
      lastRel = side + left
      path[pos] = base + step * int32(lastRel - 1)
      pos += 1
      left += 1
      if left <= right:
        lastRel = side + right
        path[pos] = base + step * int32(lastRel - 1)
        pos += 1
        right -= 1

    let startRightZero = lastRel + midLen - curN + side - 1
    fillPath(pos, side, startRightZero + 1, 0'i32, 1'i32)
    for idx in 0 ..< side:
      aux[idx] = path[pos + idx]

    let rightBase = base + step * int32(curN - side)
    let twoSideMinusOne = 2 * side - 1
    for idx in 0 ..< side:
      let offsetVal = aux[idx]
      if (idx and 1) == 0:
        path[pos + idx] = rightBase + step * offsetVal
        path[pos + twoSideMinusOne - idx] = base + step * offsetVal
      else:
        path[pos + idx] = base + step * offsetVal
        path[pos + twoSideMinusOne - idx] = rightBase + step * offsetVal
    return

proc readInputBytes(): string =
  const chunkSize = 1 shl 12
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
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  value

var outBuf = newStringOfCap(flushBlockBytes + 64)

proc appendSignedInt(value: int32, withSpace: bool) {.inline.} =
  var digits: array[12, char]
  var n = value
  if n < 0'i32:
    outBuf.add '-'
    n = -n
  var count = 0
  if n == 0'i32:
    digits[0] = '0'
    count = 1
  else:
    while n > 0'i32:
      digits[count] = char(int(n mod 10'i32) + firstDigitValue)
      n = n div 10'i32
      count += 1
  for idx in countdown(count - 1, 0):
    outBuf.add digits[idx]
  if withSpace:
    outBuf.add ' '
  else:
    outBuf.add '\n'
  if outBuf.len >= flushBlockBytes:
    stdout.write outBuf
    outBuf.setLen(0)

proc main() =
  let inputData = readInputBytes()
  var scanPos = 0
  let n = nextInt(inputData, scanPos)
  let k = nextInt(inputData, scanPos)
  if n <= 1:
    stdout.write "\n"
    return
  path = newSeq[int32](n)
  aux = newSeq[int32]((n shr 1) + 2)
  fillPath(0, n, k, 1'i32, 1'i32)
  let lastJump = n - 2
  for idx in 0 .. lastJump:
    appendSignedInt(path[idx + 1] - path[idx], idx < lastJump)
  if outBuf.len > 0:
    stdout.write outBuf

main()

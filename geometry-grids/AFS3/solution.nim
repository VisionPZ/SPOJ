import math

const flushBlockBytes = 1 shl 17
const sieveLimit = 100000
const firstDigitValue = 48

type U128 = object
  hi, lo: uint64

proc toU128(value: uint64): U128 {.inline.} =
  U128(hi: 0'u64, lo: value)

proc `+`(a, b: U128): U128 {.inline.} =
  let lo = a.lo + b.lo
  let carry = if lo < a.lo: 1'u64 else: 0'u64
  U128(hi: a.hi + b.hi + carry, lo: lo)

proc addU64(a: var U128, b: uint64) {.inline.} =
  let lo = a.lo + b
  if lo < a.lo:
    a.hi += 1'u64
  a.lo = lo

proc `-`(a, b: U128): U128 {.inline.} =
  let borrow = if a.lo < b.lo: 1'u64 else: 0'u64
  U128(hi: a.hi - b.hi - borrow, lo: a.lo - b.lo)

proc `<`(a, b: U128): bool {.inline.} =
  if a.hi != b.hi:
    return a.hi < b.hi
  a.lo < b.lo

proc `<=`(a, b: U128): bool {.inline.} =
  if a.hi != b.hi:
    return a.hi < b.hi
  a.lo <= b.lo

proc shr1(a: U128): U128 {.inline.} =
  U128(hi: a.hi shr 1, lo: (a.lo shr 1) or ((a.hi and 1'u64) shl 63))

proc shl1(a: U128): U128 {.inline.} =
  U128(hi: (a.hi shl 1) or (a.lo shr 63), lo: a.lo shl 1)

proc mul32x64(smallVal, fullVal: uint64): U128 {.inline.} =
  let p0 = smallVal * (fullVal and 0xffffffff'u64)
  let p1 = smallVal * (fullVal shr 32)
  let lo = p0 + (p1 shl 32)
  let carry = if lo < p0: 1'u64 else: 0'u64
  U128(hi: (p1 shr 32) + carry, lo: lo)

proc mul64(a, b: uint64): U128 {.inline.} =
  if (a shr 32) == 0'u64:
    return mul32x64(a, b)
  if (b shr 32) == 0'u64:
    return mul32x64(b, a)
  let a0 = a and 0xffffffff'u64
  let a1 = a shr 32
  let b0 = b and 0xffffffff'u64
  let b1 = b shr 32
  let p00 = a0 * b0
  let p01 = a0 * b1
  let p10 = a1 * b0
  let p11 = a1 * b1
  let mid = (p00 shr 32) + (p01 and 0xffffffff'u64) + (p10 and 0xffffffff'u64)
  let lo = (p00 and 0xffffffff'u64) or (mid shl 32)
  let hi = p11 + (p01 shr 32) + (p10 shr 32) + (mid shr 32)
  U128(hi: hi, lo: lo)

proc mulU64(a: U128, b: uint64): U128 {.inline.} =
  let lowPart = mul64(a.lo, b)
  U128(hi: lowPart.hi + a.hi * b, lo: lowPart.lo)

proc aboveHyperbola(xCoord, yCoord, bigN: uint64): bool {.inline.} =
  let p0 = xCoord * (yCoord and 0xffffffff'u64)
  let p1 = xCoord * (yCoord shr 32)
  let lo = p0 + (p1 shl 32)
  let hi = (p1 shr 32) + (if lo < p0: 1'u64 else: 0'u64)
  if hi != 0'u64:
    return true
  lo > bigN

proc divU128ToU64(a, b: U128): uint64 {.inline.} =
  if a < b:
    return 0'u64
  var cur = a
  var denom = b
  var bit = 1'u64
  let halfCur = shr1(cur)
  while denom <= halfCur:
    denom = shl1(denom)
    bit = bit shl 1
  var quot = 0'u64
  while bit > 0'u64:
    if denom <= cur:
      cur = cur - denom
      quot = quot or bit
    denom = shr1(denom)
    bit = bit shr 1
  quot

proc divModBillion(val: U128): tuple[q: U128, r: uint64] {.inline.} =
  const base = 1000000000'u64
  let hiQ = val.hi div base
  let rem0 = val.hi mod base
  let loHi = val.lo shr 32
  let loLo = val.lo and 0xffffffff'u64
  let v1 = (rem0 shl 32) or loHi
  let q1 = v1 div base
  let r1 = v1 mod base
  let v2 = (r1 shl 32) or loLo
  let q2 = v2 div base
  let r2 = v2 mod base
  (U128(hi: hiQ, lo: (q1 shl 32) or q2), r2)

proc u128ToStr(val: U128): string =
  if val.hi == 0'u64 and val.lo == 0'u64:
    return "0"
  var cur = val
  var chunks: array[6, uint64]
  var chunkCount = 0
  while cur.hi > 0'u64 or cur.lo > 0'u64:
    let qr = divModBillion(cur)
    chunks[chunkCount] = qr.r
    chunkCount += 1
    cur = qr.q
  var res = $chunks[chunkCount - 1]
  for idx in countdown(chunkCount - 2, 0):
    var part = chunks[idx]
    var buf: array[9, char]
    for pos in countdown(8, 0):
      buf[pos] = char(int(part mod 10'u64) + firstDigitValue)
      part = part div 10'u64
    for pos in 0 .. 8:
      res.add buf[pos]
  res

proc tri(n: uint64): U128 {.inline.} =
  if (n and 1'u64) == 0'u64:
    return mul64(n shr 1, n + 1'u64)
  mul64(n, (n + 1'u64) shr 1)

proc isqrtU64(n: uint64): uint64 {.inline.} =
  var root = uint64(sqrt(float64(n)))
  while (root + 1'u64) * (root + 1'u64) <= n:
    root += 1'u64
  while root * root > n:
    root -= 1'u64
  root

proc icbrtU64(n: uint64): uint64 {.inline.} =
  var root = uint64(cbrt(float64(n)))
  while (root + 1'u64) * (root + 1'u64) * (root + 1'u64) <= n:
    root += 1'u64
  while root * root * root > n:
    root -= 1'u64
  root

proc floorSumTriple(nVal, aVal, bVal, cVal: uint64): tuple[s0, s1, s2: U128] =
  if nVal == 0'u64:
    return (toU128(0'u64), toU128(0'u64), toU128(0'u64))
  if nVal == 1'u64:
    let q0 = bVal div cVal
    return (toU128(q0), toU128(0'u64), mul64(q0, q0))
  if nVal == 2'u64:
    let q0 = bVal div cVal
    let q1 = (aVal + bVal) div cVal
    return (toU128(q0 + q1), toU128(q1), mul64(q0, q0) + mul64(q1, q1))
  let qa = aVal div cVal
  let ra = aVal mod cVal
  let qb = bVal div cVal
  let rb = bVal mod cVal
  let n1U64 = (nVal * (nVal - 1'u64)) shr 1
  let n1 = toU128(n1U64)
  let twoNMinusOne = 2'u64 * nVal - 1'u64
  let n2 =
    if (n1U64 mod 3'u64) == 0'u64:
      mul64(n1U64 div 3'u64, twoNMinusOne)
    else:
      mul64(n1U64, twoNMinusOne div 3'u64)
  var p0 = toU128(0'u64)
  var p1 = toU128(0'u64)
  var p2 = toU128(0'u64)
  if ra != 0'u64:
    let mVal = (ra * (nVal - 1'u64) + rb) div cVal
    if mVal > 0'u64:
      let sub = floorSumTriple(mVal, cVal, cVal - rb - 1'u64, ra)
      let mnMinus1 = mul64(mVal, nVal - 1'u64)
      p0 = mnMinus1 - sub.s0
      p2 = mulU64(mnMinus1, mVal) - shl1(sub.s1) - sub.s0
      p1 = mulU64(n1, mVal) - shr1(sub.s2 + sub.s0)
  let qaN1 = mul64(qa, n1U64)
  let qbN0 = mul64(qb, nVal)
  let qaN2 = mulU64(n2, qa)
  let qbN1 = mul64(qb, n1U64)
  let qa2N2 = mulU64(n2, qa * qa)
  let qb2N0 = mulU64(mul64(qb, qb), nVal)
  let twoQaQbN1 = shl1(mulU64(mul64(qa, qb), n1U64))
  let s0 = qaN1 + qbN0 + p0
  let s1 = qaN2 + qbN1 + p1
  let s2 = qa2N2 + qb2N0 + twoQaQbN1 + shl1(mulU64(p1, qa) + mulU64(p0, qb)) + p2
  (s0, s1, s2)

var stackVec = newSeqOfCap[tuple[dx, dy: uint64]](16384)

proc solveLarge(bigN: uint64): U128 =
  let uVal = isqrtU64(bigN)
  var vVal = icbrtU64(bigN) * 10'u64
  if vVal < 1'u64:
    vVal = 1'u64
  if vVal > uVal:
    vVal = uVal
  var ans = toU128(0'u64)
  for xCur in 1'u64 .. vVal:
    ans.addU64(xCur * (bigN div xCur))
  let tv = tri(vVal)
  for yCur in 1'u64 .. vVal:
    ans = ans + (tri(bigN div yCur) - tv)
  ans = ans + mulU64(tri(uVal) - tv, uVal - vVal)
  if vVal == uVal:
    return ans - tri(bigN)

  var x = uVal
  var y = bigN div x + 1'u64
  stackVec.setLen(0)
  stackVec.add((0'u64, 1'u64))
  stackVec.add((1'u64, 0'u64))
  var subSum = toU128(0'u64)

  while x > vVal:
    var lx = stackVec[^1].dx
    var ly = stackVec[^1].dy
    if x <= lx or not aboveHyperbola(x - lx, y + ly, bigN):
      var rx = lx
      var ry = ly
      stackVec.setLen(stackVec.len - 1)
      while stackVec.len > 0:
        let top = stackVec[^1]
        if x > top.dx and aboveHyperbola(x - top.dx, y + top.dy, bigN):
          break
        rx = top.dx
        ry = top.dy
        stackVec.setLen(stackVec.len - 1)
      lx = stackVec[^1].dx
      ly = stackVec[^1].dy
      while true:
        let mx = lx + rx
        let my = ly + ry
        if x > mx and aboveHyperbola(x - mx, y + my, bigN):
          stackVec.add((mx, my))
          lx = mx
          ly = my
        else:
          if x <= rx:
            break
          let px = x - rx
          let py = y + ry
          if lx == 0'u64:
            var loT = bigN div px - py + 1'u64
            if loT < 1'u64:
              loT = 1'u64
            ry += loT - 1'u64
            let nx = lx + rx
            let ny = ly + ry
            stackVec.add((nx, ny))
            lx = nx
            ly = ny
            continue
          let lhs = mul64(px, ly)
          let twoLxLy = shl1(mul64(lx, ly))
          let rhs = mul64(py, lx) + twoLxLy
          if lhs <= rhs:
            break
          let gap = lhs - mul64(py, lx)
          let t0 = divU128ToU64(gap, twoLxLy)
          var peakFound = false
          for stepT in [t0, t0 + 1'u64]:
            if stepT >= 1'u64:
              let subPx = stepT * lx
              if px > subPx and aboveHyperbola(px - subPx, py + stepT * ly, bigN):
                peakFound = true
                break
          if not peakFound:
            break
          var loT = 1'u64
          var hiT = t0 + 1'u64
          let subP0 = t0 * lx
          if px > subP0 and aboveHyperbola(px - subP0, py + t0 * ly, bigN):
            hiT = t0
          while loT < hiT:
            let mid = (loT + hiT) shr 1
            let subMid = mid * lx
            if px > subMid and aboveHyperbola(px - subMid, py + mid * ly, bigN):
              hiT = mid
            else:
              loT = mid + 1'u64
          rx += (loT - 1'u64) * lx
          ry += (loT - 1'u64) * ly
          let nx = lx + rx
          let ny = ly + ry
          stackVec.add((nx, ny))
          lx = nx
          ly = ny

    let kMax = (x - vVal + lx - 1'u64) div lx
    var loK = 1'u64
    if kMax > 1'u64 and x > 2'u64 * lx and aboveHyperbola(x - 2'u64 * lx, y + 2'u64 * ly, bigN):
      var hiK = 2'u64
      while hiK < kMax:
        let nextK = min(kMax, hiK shl 1)
        if x > nextK * lx and aboveHyperbola(x - nextK * lx, y + nextK * ly, bigN):
          loK = nextK
          hiK = nextK shl 1
        else:
          hiK = nextK - 1'u64
          break
      if hiK > kMax:
        hiK = kMax
      while loK < hiK:
        let mid = (loK + hiK + 1'u64) shr 1
        let stepX = mid * lx
        if x > stepX and aboveHyperbola(x - stepX, y + mid * ly, bigN):
          loK = mid
        else:
          hiK = mid - 1'u64

    var segN = loK * lx
    if segN > x - vVal:
      segN = x - vVal
    if segN > 0'u64:
      let ft = floorSumTriple(segN, ly, 0'u64, lx)
      let n1U64 = (segN * (segN - 1'u64)) shr 1
      let numM = (segN - 1'u64) div lx + 1'u64
      let m1U64 = (numM * (numM - 1'u64)) shr 1
      let adjXq = mul64(numM, x) - mul64(lx, m1U64)
      let adjTri = mul64(numM, y) + mul64(ly, m1U64)
      let sumYLoS0 = mul64(segN, y) + ft.s0
      let sumXq = mulU64(sumYLoS0, x) - (mul64(y, n1U64) + ft.s1) - adjXq
      let sumQ2 = mulU64(mul64(y, y), segN) + shl1(mulU64(ft.s0, y)) + ft.s2
      let sumTri = shr1(sumQ2 + sumYLoS0) - adjTri
      subSum = subSum + sumXq + sumTri
    x -= loK * lx
    y += loK * ly

  let cnt = uVal - vVal
  let sx = tri(uVal) - tri(vVal)
  subSum = subSum - (mulU64(sx, uVal) + mulU64(tri(uVal), cnt))
  ans + subSum - tri(bigN)

proc buildSmallPrefix(): seq[uint64] =
  var res = newSeq[uint64](sieveLimit + 1)
  let halfLimit = sieveLimit shr 1
  for divisor in 1 .. halfLimit:
    let step = divisor
    var multiple = divisor + divisor
    while multiple <= sieveLimit:
      res[multiple] += uint64(step)
      multiple += step
  for idx in 2 .. sieveLimit:
    res[idx] += res[idx - 1]
  res

proc readInputBytes(): string =
  const chunkSize = 1 shl 16
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

proc nextU64(data: string, pos: var int): uint64 {.inline.} =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'u64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10'u64 + uint64(int(data[pos]) - firstDigitValue)
    pos += 1
  value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen(0)

proc main() =
  let smallPrefix = buildSmallPrefix()
  let inputData = readInputBytes()
  var scanPos = 0
  let tCount = int(nextU64(inputData, scanPos))
  for caseIdx in 0 ..< tCount:
    let bigN = nextU64(inputData, scanPos)
    if bigN <= uint64(sieveLimit):
      appendOutput($smallPrefix[int(bigN)])
    else:
      appendOutput(u128ToStr(solveLarge(bigN)))
    appendOutput("\n")
  if outputBuffer.len > 0:
    stdout.write outputBuffer

main()

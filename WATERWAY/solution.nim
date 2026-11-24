{.passC: "-O3".}
{.optimization: speed.}
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const negInf = -1000000000000000000'i64

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type SegmentTree = object
  size: int
  mx: seq[int64]
  lz: seq[int64]

proc initTree(values: seq[int64]): SegmentTree =
  var size = 1
  while size < values.len: size = size shl 1
  result.size = size
  result.mx = newSeq[int64](size shl 1)
  result.lz = newSeq[int64](size shl 1)
  for i in 0..<size shl 1: result.mx[i] = negInf
  for i in 0..<values.len: result.mx[size + i] = values[i]
  for i in countdown(size - 1, 1):
    result.mx[i] = max(result.mx[i shl 1], result.mx[i shl 1 + 1])

proc apply(tree: var SegmentTree, node: int, value: int64) =
  tree.mx[node] += value
  tree.lz[node] += value

proc push(tree: var SegmentTree, node: int) =
  let value = tree.lz[node]
  if value != 0:
    tree.apply(node shl 1, value)
    tree.apply(node shl 1 + 1, value)
    tree.lz[node] = 0

proc rangeAdd(tree: var SegmentTree, node, left, right, ql, qr: int, value: int64) =
  if qr < left or right < ql: return
  if ql <= left and right <= qr:
    tree.apply(node, value)
    return
  tree.push(node)
  let mid = (left + right) shr 1
  tree.rangeAdd(node shl 1, left, mid, ql, qr, value)
  tree.rangeAdd(node shl 1 + 1, mid + 1, right, ql, qr, value)
  tree.mx[node] = max(tree.mx[node shl 1], tree.mx[node shl 1 + 1])

proc rangeMax(tree: var SegmentTree, node, left, right, ql, qr: int): int64 =
  if qr < left or right < ql: return negInf
  if ql <= left and right <= qr: return tree.mx[node]
  tree.push(node)
  let mid = (left + right) shr 1
  return max(tree.rangeMax(node shl 1, left, mid, ql, qr),
             tree.rangeMax(node shl 1 + 1, mid + 1, right, ql, qr))

proc addLinear(array0, array1: var seq[int64], left, right: int, coef0, coef1: int64) =
  if left > right or left < 0 or right >= array0.len - 2: return
  array0[left] += coef0
  array1[left] += coef1
  array0[right + 1] -= coef0
  array1[right + 1] -= coef1

proc solveCase(text: openArray[char], start: int, n: int): int64 =
  var countA = 0
  var countC = 0
  for k in 0..<n:
    if text[start + k] == 'A': countA += 1
    elif text[start + k] == 'C': countC += 1
  if countA == 0 and countC == 0:
    return int64(n) * int64(n) div 4
  if countA == 0 or countC == 0:
    var runLengths = newSeq[int]()
    var currentRun = 0
    for k in 0..<n:
      if text[start + k] == 'B':
        currentRun += 1
      elif currentRun > 0:
        runLengths.add currentRun
        currentRun = 0
    if currentRun > 0:
      if runLengths.len > 0 and text[start] == 'B' and text[start + n - 1] == 'B':
        runLengths[0] += currentRun
      else:
        runLengths.add currentRun
    if runLengths.len == 0:
      return int64(n) * int64(n - 1) div 2
    var pairTotal = 0'i64
    var bestBalance = 0'i64
    var capacities = newSeq[int64](runLengths.len)
    for k in 0..<runLengths.len:
      let len = int64(runLengths[k])
      pairTotal += len * (len + 1) div 2
      capacities[k] = (len + 1) * (len + 1) div 4
    for runIndex in 0..<runLengths.len:
      var outside = -1'i64
      for other in 0..<runLengths.len:
        if other != runIndex: outside = max(outside, capacities[other])
      let len = int64(runLengths[runIndex])
      for take in 1..runLengths[runIndex]:
        let tk = int64(take)
        let base = tk * (len - tk + 1)
        if outside >= 0: bestBalance = max(bestBalance, base + outside)
        bestBalance = max(bestBalance, tk * tk div 4 + base)
        if take < runLengths[runIndex]:
          var vertex = (len + 1 + tk) div 2
          var valueAt = max(tk + 1, min(len, vertex))
          bestBalance = max(bestBalance, valueAt * (len + 1 + tk - valueAt) - tk * tk)
          vertex += 1
          valueAt = max(tk + 1, min(len, vertex))
          bestBalance = max(bestBalance, valueAt * (len + 1 + tk - valueAt) - tk * tk)
    return int64(n) * int64(n - 1) div 2 - pairTotal + bestBalance

  var fwd = newSeq[int](n)
  var run = 0
  for p in countdown(2 * n - 1, 0):
    if text[start + (p mod n)] == 'B' or text[start + (p mod n)] == 'C':
      run += 1
    else:
      run = 0
    if p < n and run > 0:
      fwd[p] = min(run, n)

  var back = newSeq[int](n)
  for p in 0..<2 * n:
    let u = p mod n
    let prev = (u - 1 + n) mod n
    if text[start + prev] == 'A' or text[start + prev] == 'B':
      back[u] = min(back[prev] + 1, n)
    else:
      back[u] = 0

  var diff0 = newSeq[int64](n + 2)
  var diff1 = newSeq[int64](n + 2)
  for u in 0..<n:
    let dC = min(fwd[u], n - back[u] - 1)
    if dC >= 1:
      let lo = min(dC - 1, n - 1 - u)
      addLinear(diff0, diff1, u, u + lo, int64(u + dC), -1)
      if dC - 1 > lo:
        addLinear(diff0, diff1, 0, dC - 1 - lo - 1, int64(u + dC - n), -1)
    let eAhi = min(back[u], n - fwd[u] - 1)
    if eAhi >= 1:
      let lo = min(eAhi, u)
      if lo >= 1:
        addLinear(diff0, diff1, u - lo, u - 1, int64(eAhi + 1 - u), 1)
      if eAhi > lo:
        addLinear(diff0, diff1, n + u - eAhi, n - 1, int64(eAhi + 1 - u - n), 1)
  var forced = newSeq[int64](n)
  var c0 = 0'i64
  var c1 = 0'i64
  for p in 0..<n:
    c0 += diff0[p]
    c1 += diff1[p]
    forced[p] = c0 + int64(p) * c1

  var diff2 = newSeq[int64](n + 2)
  var diffA0 = newSeq[int64](n + 2)
  var diffA1 = newSeq[int64](n + 2)
  proc addRange(base: var seq[int64], left, right: int, value: int64) =
    if left > right or left < 0 or right >= n: return
    base[left] += value
    base[right + 1] -= value
  proc addT(u, tlo, thi: int, a, b: int64) =
    if tlo > thi: return
    let tl = u + tlo
    let tr = u + thi
    if tr < n:
      addLinear(diffA0, diffA1, tl, tr, a, b)
    elif tl >= n:
      addLinear(diffA0, diffA1, tl - n, tr - n, a + b * int64(n), b)
    else:
      addLinear(diffA0, diffA1, tl, n - 1, a, b)
      addLinear(diffA0, diffA1, 0, tr - n, a + b * int64(n), b)

  var loD = newSeq[int](n)
  var hiD = newSeq[int](n)
  var arcsU = newSeq[int]()
  var arcsR = newSeq[int]()
  for u in 0..<n:
    let lo = max(1, n - back[u])
    let hi = min(fwd[u], n - 1)
    if lo <= hi:
      loD[u] = lo
      hiD[u] = hi
      addT(u, 0, lo - 1, int64(hi - lo + 1), 0)
      addT(u, lo, hi - 1, int64(hi + u), -1)
      for d in lo..hi:
        arcsU.add(u)
        arcsR.add(u + d)
  var cover = newSeq[int64](n)
  var cur = 0'i64
  var ca0 = 0'i64
  var ca1 = 0'i64
  for p in 0..<n:
    cur += diff2[p]
    ca0 += diffA0[p]
    ca1 += diffA1[p]
    cover[p] = cur + ca0 + int64(p) * ca1
  var totalCover = newSeq[int64](n)
  for i in 0..<n: totalCover[i] = forced[i] + cover[i]

  var g1 = newSeq[int64](n)
  if hiD[0] >= loD[0]:
    for j in 0..<n:
      var cnt = 0'i64
      for d in loD[0]..hiD[0]:
        if d > j: cnt += 1
      g1[j] = cnt
  var diff3 = newSeq[int64](n + 2)
  for u in 0..<n:
    if hiD[u] >= loD[u]:
      let rlo = u + loD[u]
      let rhi = u + hiD[u]
      let cnt = max(0, rhi - max(rlo, n + 1) + 1)
      if cnt > 0:
        addRange(diff3, u, n - 1, int64(cnt))
  var g2 = newSeq[int64](n)
  cur = 0
  for p in 0..<n:
    cur += diff3[p]
    g2[p] = cur
  var endCount = newSeq[int64](2 * n + 2)
  for idx in 0..<arcsU.len:
    endCount[arcsR[idx]] += 1
  var g3 = newSeq[int64](n)
  var suff = 0'i64
  for r in countdown(2 * n + 1, 0):
    suff += endCount[r]
    let idx = r - n - 1
    if idx >= 0 and idx < n: g3[idx] = suff

  var values = newSeq[int64](n)
  for j in 0..<n:
    values[j] = totalCover[j] + cover[0] - 2 * g1[j] - 2 * g2[j] - 2 * g3[j]

  type ArcEvent = tuple[typ, u, r: int]
  var events = newSeq[seq[ArcEvent]](2 * n + 2)
  for idx in 0..<arcsU.len:
    let u = arcsU[idx]
    let r = arcsR[idx]
    events[u].add((0, u, r))
    events[r].add((1, u, r))
    if r > n: events[r - n].add((2, u, r))

  var tree = initTree(values)
  var answer = 0'i64
  for f in 0..<n: answer = max(answer, forced[f])
  for gpos in 0..<n:
    if gpos > 0:
      let mv = tree.rangeMax(1, 0, tree.size - 1, 0, gpos - 1)
      let cand = (forced[gpos] + mv + 1) div 2
      if cand > answer: answer = cand
    let p = gpos + 1
    if p < events.len:
      for event in events[p]:
        let typ = event.typ
        let u = event.u
        let r = event.r
        let hi1 = min(n - 1, r - 1)
        var hi2 = -1
        if r > n: hi2 = min(n - 1, r - n - 1)
        let compLo = if hi2 >= 0: hi2 + 1 else: 0
        let compHi = u - 1
        let tailLo = if r <= n: r else: n
        if typ == 0:
          if u <= hi1: tree.rangeAdd(1, 0, tree.size - 1, u, hi1, -1)
          if hi2 >= 0: tree.rangeAdd(1, 0, tree.size - 1, 0, hi2, -1)
          if compLo <= compHi and compLo < n:
            tree.rangeAdd(1, 0, tree.size - 1, compLo, min(n - 1, compHi), 1)
          if tailLo < n: tree.rangeAdd(1, 0, tree.size - 1, tailLo, n - 1, 1)
        elif typ == 1:
          if u <= hi1: tree.rangeAdd(1, 0, tree.size - 1, u, hi1, 1)
          if hi2 >= 0: tree.rangeAdd(1, 0, tree.size - 1, 0, hi2, 1)
          if compLo <= compHi and compLo < n:
            tree.rangeAdd(1, 0, tree.size - 1, compLo, min(n - 1, compHi), -1)
          if tailLo < n: tree.rangeAdd(1, 0, tree.size - 1, tailLo, n - 1, -1)
        else:
          let upto = r - n - 1
          if upto >= 0 and upto < n: tree.rangeAdd(1, 0, tree.size - 1, 0, upto, 1)
          if r - n <= u - 1 and r - n < n:
            tree.rangeAdd(1, 0, tree.size - 1, r - n, min(n - 1, u - 1), -1)
          if u < n: tree.rangeAdd(1, 0, tree.size - 1, u, n - 1, 1)
  return answer

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  while scanPos < inputData.len and inputData[scanPos] != 'A' and
        inputData[scanPos] != 'B' and inputData[scanPos] != 'C':
    scanPos += 1
  let textStart = scanPos
  scanPos += cityCount
  let answer = solveCase(inputData, textStart, cityCount)
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

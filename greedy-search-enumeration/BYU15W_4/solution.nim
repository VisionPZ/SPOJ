import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const dpCutoff = 64
const gridPoints = 601
const halfScaleCount = 8.5

const ghNodes = [
  -2.8569700138728056,
  -1.3556261799742659,
  0.0,
  1.3556261799742659,
  2.8569700138728056
]

const ghWeights = [
  0.011257411327720689,
  0.22207592200561264,
  0.5333333333333333,
  0.22207592200561264,
  0.011257411327720689
]

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

proc nextFloat(data: string, pos: var int): float64 =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '.'):
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float64(int(data[pos]) - firstDigitValue)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var place = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value += float64(int(data[pos]) - firstDigitValue) * place
      place *= 0.1
      pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendFixed5(value: float64) =
  var clamped = value
  if clamped < 0.0:
    clamped = 0.0
  elif clamped > 1.0:
    clamped = 1.0
  let scaled = int(round(clamped * 100000.0))
  let whole = scaled div 100000
  let frac = scaled mod 100000
  appendOutput($whole)
  outputBuffer.add '.'
  var pad = 10000
  while pad > 1 and frac < pad:
    outputBuffer.add '0'
    pad = pad div 10
  appendOutput($frac)

type
  OutcomeTable = object
    winA: seq[float64]
    winB: seq[float64]
    draw: seq[float64]
    stride: int

proc buildExactDp(hitProb: float64, limit: int): OutcomeTable =
  let stride = limit + 1
  let tableSize = stride * stride
  var table: OutcomeTable
  table.stride = stride
  table.winA = newSeq[float64](tableSize)
  table.winB = newSeq[float64](tableSize)
  table.draw = newSeq[float64](tableSize)

  var rows = newSeq[seq[float64]](stride)
  var rowLo = newSeq[int](stride)
  var rowHi = newSeq[int](stride)
  rows[0] = @[1.0]
  rowLo[0] = 0
  rowHi[0] = 0
  let missProb = 1.0 - hitProb
  for count in 1 .. limit:
    var row = newSeq[float64](count + 1)
    let pZero = pow(missProb, float64(count))
    if pZero > 1e-300:
      row[0] = pZero
      let ratio = hitProb / missProb
      for hits in 0 .. count - 1:
        row[hits + 1] = row[hits] * float64(count - hits) / float64(hits + 1) * ratio
    else:
      let mode = int(float64(count) * hitProb)
      row[mode] = exp(lgamma(float64(count + 1)) - lgamma(float64(mode + 1)) - lgamma(float64(count - mode + 1)) + float64(mode) * ln(hitProb) + float64(count - mode) * ln(missProb))
      let ratio = hitProb / missProb
      for hits in mode .. count - 1:
        row[hits + 1] = row[hits] * float64(count - hits) / float64(hits + 1) * ratio
      var back = mode
      while back > 0:
        row[back - 1] = row[back] * float64(back) / float64(count - back + 1) / ratio
        back -= 1
    var lo = 0
    while lo < count and row[lo] < 1e-13:
      lo += 1
    var hi = count
    while hi > lo and row[hi] < 1e-13:
      hi -= 1
    rows[count] = row
    rowLo[count] = lo
    rowHi[count] = hi

  for armyA in 1 .. limit:
    table.winA[armyA * stride] = 1.0
  for armyB in 1 .. limit:
    table.winB[armyB] = 1.0
  table.draw[0] = 1.0

  var condA = newSeq[float64](tableSize)
  var condB = newSeq[float64](tableSize)
  var condD = newSeq[float64](tableSize)

  for armyA in 1 .. limit:
    let loA = rowLo[armyA]
    let hiA = rowHi[armyA]
    for armyB in 1 .. limit:
      let loB = rowLo[armyB]
      let hiB = rowHi[armyB]
      var bpMin = armyB - hiA
      if bpMin < 0:
        bpMin = 0
      for nextB in bpMin .. armyB:
        var sumA = 0.0
        var sumB = 0.0
        var sumD = 0.0
        for hitsB in loB .. hiB:
          if hitsB == 0 and nextB == armyB:
            continue
          let probB = rows[armyB][hitsB]
          var nextA = armyA - hitsB
          if nextA < 0:
            nextA = 0
          let idx = nextA * stride + nextB
          sumA += probB * table.winA[idx]
          sumB += probB * table.winB[idx]
          sumD += probB * table.draw[idx]
        let condIdx = armyB * stride + nextB
        condA[condIdx] = sumA
        condB[condIdx] = sumB
        condD[condIdx] = sumD
      let stayProb = rows[armyA][0] * rows[armyB][0]
      let scale = 1.0 / (1.0 - stayProb)
      var totalA = 0.0
      var totalB = 0.0
      var totalD = 0.0
      for hitsA in loA .. hiA:
        let probA = rows[armyA][hitsA]
        var nextB = armyB - hitsA
        if nextB < 0:
          nextB = 0
        let condIdx = armyB * stride + nextB
        totalA += probA * condA[condIdx]
        totalB += probA * condB[condIdx]
        totalD += probA * condD[condIdx]
      let outIdx = armyA * stride + armyB
      table.winA[outIdx] = totalA * scale
      table.winB[outIdx] = totalB * scale
      table.draw[outIdx] = totalD * scale
  return table

proc solveCase(hitProb: float64, armyA: int, armyB: int): array[3, float64] =
  if hitProb >= 1.0 - 1e-12:
    if armyA > armyB:
      return [1.0, 0.0, 0.0]
    if armyA < armyB:
      return [0.0, 1.0, 0.0]
    return [0.0, 0.0, 1.0]

  if armyA <= dpCutoff and armyB <= dpCutoff:
    let limit = if armyA > armyB: armyA else: armyB
    let table = buildExactDp(hitProb, limit)
    let idx = armyA * table.stride + armyB
    return [table.winA[idx], table.winB[idx], table.draw[idx]]

  var sumS = float64(armyA + armyB)
  let diff0 = float64(armyA - armyB)
  let sdZInf = sqrt((1.0 - hitProb) / (3.0 + hitProb) * sumS + 1.0)
  if abs(diff0) > halfScaleCount * sdZInf:
    if diff0 > 0.0:
      return [1.0, 0.0, 0.0]
    return [0.0, 1.0, 0.0]

  var halfSpan = halfScaleCount * sdZInf
  if halfSpan > sumS:
    halfSpan = sumS
  let zMin = diff0 - halfSpan
  let stepDz = (2.0 * halfSpan) / float64(gridPoints - 1)
  var probs = newSeq[float64](gridPoints)
  var nextProbs = newSeq[float64](gridPoints)
  probs[(gridPoints - 1) div 2] = 1.0

  var winA = 0.0
  var winB = 0.0
  var varS = 0.0
  var scale = 1.0
  let decay = 1.0 - hitProb
  let growth = 1.0 + hitProb
  let handoffLimit = 1.2 * float64(dpCutoff)
  let ratioZ = decay / (growth * growth)
  var kernel = newSeq[float64](gridPoints)

  while sumS > handoffLimit:
    var macroTurns = 1
    if hitProb < 0.01 and sumS > 500.0:
      let stepVarOne = hitProb * decay * sumS / (scale * scale * growth * growth)
      var needTurns = 1
      if stepVarOne > 1e-18:
        needTurns = int(ceil((1.5 * stepDz) * (1.5 * stepDz) / stepVarOne))
      var maxByH = int(0.01 / hitProb)
      if maxByH < 1:
        maxByH = 1
      var maxByS = int(ln(handoffLimit / sumS) / ln(decay))
      if maxByS < 1:
        maxByS = 1
      macroTurns = needTurns
      if macroTurns > maxByH:
        macroTurns = maxByH
      if macroTurns > maxByS:
        macroTurns = maxByS
      if macroTurns < 1:
        macroTurns = 1

    var varZStep = 0.0
    if macroTurns == 1:
      scale *= growth
      varZStep = hitProb * decay * sumS / (scale * scale)
      varS = decay * decay * varS + hitProb * decay * sumS
      sumS *= decay
    else:
      let decPow = pow(decay, float64(macroTurns))
      let groPow = pow(growth, float64(macroTurns))
      let ratioPow = pow(ratioZ, float64(macroTurns))
      let geoZ = (1.0 - ratioPow) / (1.0 - ratioZ)
      varZStep = hitProb * decay * sumS / (scale * scale * growth * growth) * geoZ
      let geoS = (1.0 - decPow) / hitProb
      varS = decPow * decPow * varS + hitProb * decay * sumS * (decPow / decay) * geoS
      sumS *= decPow
      scale *= groPow

    let sdStep = sqrt(varZStep)
    let boundZ = sumS / scale
    if sdStep > 0.0:
      var radius = int(ceil(6.0 * sdStep / stepDz))
      if radius < 2:
        radius = 2
      if radius > (gridPoints - 1) div 2:
        radius = (gridPoints - 1) div 2
      var kernelSum = 0.0
      for offset in -radius .. radius:
        let dist = float64(offset) * stepDz / sdStep
        let weight = exp(-0.5 * dist * dist)
        kernel[offset + radius] = weight
        kernelSum += weight
      let invKernel = 1.0 / kernelSum
      for offset in 0 .. 2 * radius:
        kernel[offset] *= invKernel

      for idx in 0 .. gridPoints - 1:
        nextProbs[idx] = 0.0
      for idx in 0 .. gridPoints - 1:
        let mass = probs[idx]
        if mass < 1e-15:
          continue
        for offset in -radius .. radius:
          let targetIdx = idx + offset
          let targetZ = zMin + float64(targetIdx) * stepDz
          let contrib = mass * kernel[offset + radius]
          if targetZ >= boundZ:
            winA += contrib
          elif targetZ <= -boundZ:
            winB += contrib
          elif targetIdx >= 0 and targetIdx < gridPoints:
            nextProbs[targetIdx] += contrib
      var alive = 0.0
      for idx in 0 .. gridPoints - 1:
        probs[idx] = nextProbs[idx]
        alive += probs[idx]
      if alive < 1e-9:
        break

  var aliveTotal = 0.0
  for idx in 0 .. gridPoints - 1:
    aliveTotal += probs[idx]

  var draw = 0.0
  if aliveTotal > 1e-12:
    let table = buildExactDp(hitProb, dpCutoff)
    let stdS = sqrt(varS)
    for idx in 0 .. gridPoints - 1:
      let mass = probs[idx]
      if mass < 1e-15:
        continue
      let diffVal = (zMin + float64(idx) * stepDz) * scale
      for qIdx in 0 .. 4:
        let sumVal = sumS + ghNodes[qIdx] * stdS
        if sumVal <= 0.0:
          draw += mass * ghWeights[qIdx]
          continue
        let aFloat = 0.5 * (sumVal + diffVal)
        let bFloat = 0.5 * (sumVal - diffVal)
        let aBase = int(floor(aFloat))
        let bBase = int(floor(bFloat))
        let aFrac = aFloat - float64(aBase)
        let bFrac = bFloat - float64(bBase)
        for da in 0 .. 1:
          let wA = if da == 0: 1.0 - aFrac else: aFrac
          var aa = aBase + da
          if aa < 0:
            aa = 0
          elif aa > dpCutoff:
            aa = dpCutoff
          for db in 0 .. 1:
            let wB = if db == 0: 1.0 - bFrac else: bFrac
            var bb = bBase + db
            if bb < 0:
              bb = 0
            elif bb > dpCutoff:
              bb = dpCutoff
            let weight = mass * ghWeights[qIdx] * wA * wB
            let tIdx = aa * table.stride + bb
            winA += weight * table.winA[tIdx]
            winB += weight * table.winB[tIdx]
            draw += weight * table.draw[tIdx]

  if armyA == armyB:
    let sym = 0.5 * (1.0 - draw)
    if sym < 0.0:
      return [0.0, 0.0, draw]
    return [sym, sym, draw]
  return [winA, winB, draw]

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let hitProb = nextFloat(inputData, scanPos)
  let armyA = nextInt(inputData, scanPos)
  let armyB = nextInt(inputData, scanPos)
  let ans = solveCase(hitProb, armyA, armyB)
  appendFixed5(ans[0])
  outputBuffer.add ' '
  appendFixed5(ans[1])
  outputBuffer.add ' '
  appendFixed5(ans[2])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

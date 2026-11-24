const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSymbolValue = 30
const unreachableCost = 1 shl 25

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)

for caseIndex in 0..<caseCount:
  let sourceLength = nextInt(inputData, scanPos)
  let targetLength = nextInt(inputData, scanPos)
  let twoRuleCount = nextInt(inputData, scanPos)
  let ruleCount = nextInt(inputData, scanPos)

  var sourceSeq = newSeq[int](sourceLength)
  for sourcePos in 0..<sourceLength:
    sourceSeq[sourcePos] = nextInt(inputData, scanPos)

  var targetSeq = newSeq[int](targetLength)
  for targetPos in 0..<targetLength:
    targetSeq[targetPos] = nextInt(inputData, scanPos)

  var ruleLeft = newSeq[int](ruleCount)
  var ruleFirstOut = newSeq[int](ruleCount)
  var ruleSecondOut = newSeq[int](ruleCount)
  var ruleThirdOut = newSeq[int](ruleCount)
  for rulePos in 0..<ruleCount:
    ruleLeft[rulePos] = nextInt(inputData, scanPos)
    ruleFirstOut[rulePos] = nextInt(inputData, scanPos)
    ruleSecondOut[rulePos] = nextInt(inputData, scanPos)
    if rulePos < twoRuleCount:
      ruleThirdOut[rulePos] = 0
    else:
      ruleThirdOut[rulePos] = nextInt(inputData, scanPos)

  var valueLimit = maxSymbolValue
  for sourcePos in 0..<sourceLength:
    valueLimit = max(valueLimit, sourceSeq[sourcePos])
  for targetPos in 0..<targetLength:
    valueLimit = max(valueLimit, targetSeq[targetPos])
  for rulePos in 0..<ruleCount:
    valueLimit = max(valueLimit, ruleLeft[rulePos])
    valueLimit = max(valueLimit, ruleFirstOut[rulePos])
    valueLimit = max(valueLimit, ruleSecondOut[rulePos])
    valueLimit = max(valueLimit, ruleThirdOut[rulePos])

  let areaSize = targetLength * targetLength
  let slotWidth = valueLimit + 1
  var pairSlot = newSeq[int](slotWidth * slotWidth)
  for slotPos in 0..<pairSlot.len:
    pairSlot[slotPos] = -1

  var pairFirst = newSeq[int](ruleCount)
  var pairSecond = newSeq[int](ruleCount)
  var rulePair = newSeq[int](ruleCount)
  var pairCount = 0
  for rulePos in 0..<ruleCount:
    let slotKey = ruleFirstOut[rulePos] * slotWidth + ruleSecondOut[rulePos]
    if pairSlot[slotKey] == -1:
      pairSlot[slotKey] = pairCount
      pairFirst[pairCount] = ruleFirstOut[rulePos]
      pairSecond[pairCount] = ruleSecondOut[rulePos]
      pairCount += 1
    rulePair[rulePos] = pairSlot[slotKey]

  var deriveCost = newSeq[int](slotWidth * areaSize)
  for costPos in 0..<deriveCost.len:
    deriveCost[costPos] = unreachableCost
  var pairCost = newSeq[int](pairCount * areaSize)
  for costPos in 0..<pairCost.len:
    pairCost[costPos] = unreachableCost

  for spanLength in 1..targetLength:
    for lowPos in 0..(targetLength - spanLength):
      let highPos = lowPos + spanLength - 1
      let spanIndex = lowPos * targetLength + highPos
      if spanLength == 1:
        for symbolValue in 1..valueLimit:
          if targetSeq[lowPos] == symbolValue:
            deriveCost[symbolValue * areaSize + spanIndex] = 0
      else:
        for pairPos in 0..<pairCount:
          let leftBase = pairFirst[pairPos] * areaSize
          let rightBase = pairSecond[pairPos] * areaSize
          let pairBase = pairPos * areaSize
          var bestCost = unreachableCost
          for splitPos in lowPos..<highPos:
            let leftCost = deriveCost[leftBase + lowPos * targetLength + splitPos]
            let rightCost = deriveCost[rightBase + (splitPos + 1) * targetLength + highPos]
            let candidate = leftCost + rightCost
            if candidate < bestCost:
              bestCost = candidate
          pairCost[pairBase + spanIndex] = bestCost

        for rulePos in 0..<ruleCount:
          let symbolBase = ruleLeft[rulePos] * areaSize
          let pairBase = rulePair[rulePos] * areaSize
          var bestCost = deriveCost[symbolBase + spanIndex]
          if ruleThirdOut[rulePos] == 0:
            let candidate = pairCost[pairBase + spanIndex] + 1
            if candidate < bestCost:
              bestCost = candidate
          else:
            let tailBase = ruleThirdOut[rulePos] * areaSize
            for splitPos in (lowPos + 1)..<highPos:
              let headCost = pairCost[pairBase + lowPos * targetLength + splitPos]
              let tailCost = deriveCost[tailBase + (splitPos + 1) * targetLength + highPos]
              let candidate = headCost + tailCost + 1
              if candidate < bestCost:
                bestCost = candidate
          deriveCost[symbolBase + spanIndex] = bestCost

  var previousMatch = newSeq[int](targetLength + 1)
  var currentMatch = newSeq[int](targetLength + 1)
  for matchPos in 0..targetLength:
    previousMatch[matchPos] = unreachableCost
  previousMatch[0] = 0

  for sourcePos in 1..sourceLength:
    for matchPos in 0..targetLength:
      currentMatch[matchPos] = unreachableCost
    let symbolBase = sourceSeq[sourcePos - 1] * areaSize
    for matchedCount in 1..targetLength:
      var bestCost = unreachableCost
      for splitPos in 0..<matchedCount:
        let headCost = previousMatch[splitPos]
        if headCost >= unreachableCost:
          continue
        let tailCost = deriveCost[symbolBase + splitPos * targetLength + matchedCount - 1]
        let candidate = headCost + tailCost
        if candidate < bestCost:
          bestCost = candidate
      currentMatch[matchedCount] = bestCost
    let swapBuffer = previousMatch
    previousMatch = currentMatch
    currentMatch = swapBuffer

  let answer = previousMatch[targetLength]
  if answer >= unreachableCost:
    appendOutput("-1")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

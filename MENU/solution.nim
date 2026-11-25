const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unreachable = -1000000000

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let dayCount = nextInt(inputData, scanPos)
  let dishCount = nextInt(inputData, scanPos)
  let budget = nextInt(inputData, scanPos)
  if dayCount == 0 and dishCount == 0 and budget == 0: break

  var dishCost = newSeq[int](dishCount + 1)
  var dishValue = newSeq[int](dishCount + 1)
  var largestCost = 0
  for dish in 1 .. dishCount:
    dishCost[dish] = nextInt(inputData, scanPos)
    dishValue[dish] = nextInt(inputData, scanPos)
    if dishCost[dish] > largestCost: largestCost = dishCost[dish]

  let costLimit = min(budget, dayCount * largestCost)
  let stride = costLimit + 1
  let layerSize = (dishCount + 1) * stride
  var allStates = newSeq[int]((dayCount + 1) * 3 * layerSize)

  let firstLayer = 3 * layerSize
  for pos in firstLayer .. firstLayer + 3 * layerSize - 1:
    allStates[pos] = unreachable
  for dish in 1 .. dishCount:
    let price = dishCost[dish]
    if price <= costLimit:
      allStates[firstLayer + dish * stride + price] = 2 * dishValue[dish]

  for dayIndex in 1 ..< dayCount:
    let sourceLayer = dayIndex * 3 * layerSize
    let targetLayer = sourceLayer + 3 * layerSize
    for pos in targetLayer .. targetLayer + 3 * layerSize - 1:
      allStates[pos] = unreachable
    for spent in 0 .. costLimit:
      var topValue = unreachable
      var topDish = 0
      var secondValue = unreachable
      for dish in 1 .. dishCount:
        let base = sourceLayer + dish * stride + spent
        var dishBest = allStates[base]
        if allStates[base + layerSize] > dishBest: dishBest = allStates[base + layerSize]
        if allStates[base + 2 * layerSize] > dishBest: dishBest = allStates[base + 2 * layerSize]
        if dishBest > topValue:
          secondValue = topValue
          topValue = dishBest
          topDish = dish
        elif dishBest > secondValue and dish != topDish:
          secondValue = dishBest
      for dish in 1 .. dishCount:
        let newSpent = spent + dishCost[dish]
        if newSpent > costLimit: continue
        let targetBase = targetLayer + dish * stride + newSpent
        let switchSource = if dish == topDish: secondValue else: topValue
        if switchSource > unreachable div 2:
          let candidate = switchSource + 2 * dishValue[dish]
          if candidate > allStates[targetBase]: allStates[targetBase] = candidate
        let sourceBase = sourceLayer + dish * stride + spent
        let firstRunValue = allStates[sourceBase]
        if firstRunValue > unreachable div 2:
          let candidate = firstRunValue + dishValue[dish]
          if candidate > allStates[targetBase + layerSize]: allStates[targetBase + layerSize] = candidate
        let secondRunValue = allStates[sourceBase + layerSize]
        let thirdRunValue = allStates[sourceBase + 2 * layerSize]
        let deepValue = if secondRunValue > thirdRunValue: secondRunValue else: thirdRunValue
        if deepValue > unreachable div 2 and deepValue > allStates[targetBase + 2 * layerSize]:
          allStates[targetBase + 2 * layerSize] = deepValue

  let finalLayer = dayCount * 3 * layerSize
  var bestBenefit = unreachable
  var bestCost = 0
  var bestRun = 0
  var bestDish = 0
  for runIndex in 0 .. 2:
    let runBase = finalLayer + runIndex * layerSize
    for dish in 1 .. dishCount:
      let dishBase = runBase + dish * stride
      for spent in 0 .. costLimit:
        let value = allStates[dishBase + spent]
        if value <= unreachable div 2: continue
        if value > bestBenefit or (value == bestBenefit and spent < bestCost):
          bestBenefit = value
          bestCost = spent
          bestRun = runIndex
          bestDish = dish

  if bestBenefit <= unreachable div 2:
    appendOutput("0.0\n\n")
    continue

  var menu = newSeq[int](dayCount + 1)
  var currentDay = dayCount
  var currentRun = bestRun
  var currentDish = bestDish
  var currentCost = bestCost
  var currentValue = bestBenefit
  while currentDay >= 1:
    menu[currentDay] = currentDish
    if currentDay == 1: break
    let previousCost = currentCost - dishCost[currentDish]
    let previousLayer = (currentDay - 1) * 3 * layerSize
    if currentRun == 0:
      let wanted = currentValue - 2 * dishValue[currentDish]
      var found = false
      for runIndex in 0 .. 2:
        for previousDish in 1 .. dishCount:
          if previousDish == currentDish: continue
          let pos = previousLayer + runIndex * layerSize + previousDish * stride + previousCost
          if allStates[pos] == wanted:
            currentRun = runIndex
            currentDish = previousDish
            currentValue = wanted
            found = true
            break
        if found: break
    elif currentRun == 1:
      currentValue = currentValue - dishValue[currentDish]
      currentRun = 0
    else:
      let posTwo = previousLayer + layerSize + currentDish * stride + previousCost
      let posThree = previousLayer + 2 * layerSize + currentDish * stride + previousCost
      if allStates[posTwo] == currentValue:
        currentRun = 1
      elif allStates[posThree] == currentValue:
        currentRun = 2
    currentCost = previousCost
    currentDay -= 1

  appendOutput($(bestBenefit div 2))
  appendOutput(".")
  if bestBenefit mod 2 == 0: appendOutput("0") else: appendOutput("5")
  appendOutput("\n")
  for dayIndex in 1 .. dayCount:
    appendOutput($(menu[dayIndex]))
    appendOutput(" ")
  appendOutput("\n\n")

stdout.write outputBuffer
outputBuffer.setLen 0

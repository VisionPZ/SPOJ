{.checks: off.}
{.optimization: speed.}

const wildcardType = 10
const typeCount = 11
const stopCount = 3
const slotCount = 3
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const firstLetterValue = 65
const tableSize = stopCount * typeCount * typeCount * typeCount

type
  BundleState = object
    bundles: int
    stops: int
    lastStop: int

proc nextInteger(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (ord(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return value

proc nextType(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < 'A' or inputData[scanPos] > 'J'):
    scanPos += 1
  let typeValue = ord(inputData[scanPos]) - firstLetterValue
  scanPos += 1
  return typeValue

proc pruneInPlace(states: var seq[BundleState]) =
  if states.len == 0:
    return
  var minBundles = high(int)
  for stateValue in states:
    if stateValue.bundles < minBundles:
      minBundles = stateValue.bundles
  var writePos = 0
  for stateValue in states:
    if stateValue.bundles == minBundles:
      states[writePos] = stateValue
      writePos += 1
  states.setLen writePos
  for indexValue in 1 .. states.len - 1:
    let current = states[indexValue]
    var leftIndex = indexValue - 1
    while leftIndex >= 0 and (states[leftIndex].stops > current.stops or
          (states[leftIndex].stops == current.stops and
           states[leftIndex].lastStop < current.lastStop)):
      states[leftIndex + 1] = states[leftIndex]
      leftIndex -= 1
    states[leftIndex + 1] = current
  writePos = 0
  var bestLast = -2
  for stateValue in states:
    if stateValue.lastStop > bestLast:
      states[writePos] = stateValue
      writePos += 1
      bestLast = stateValue.lastStop
  states.setLen writePos

var inputData = stdin.readAll()
var scanPos = 0
let caseCount = nextInteger(inputData, scanPos)
var templateStamp = newSeq[int](tableSize)
var currentStamp = 0
var outputBuffer = ""

for caseIndex in 0 .. caseCount - 1:
  currentStamp += 1
  let templateCount = nextInteger(inputData, scanPos)
  let instructionCount = nextInteger(inputData, scanPos)
  for templateIndex in 0 .. templateCount - 1:
    let firstLetter = nextType(inputData, scanPos)
    let secondLetter = nextType(inputData, scanPos)
    let thirdLetter = nextType(inputData, scanPos)
    let stopPosition = nextInteger(inputData, scanPos)
    for slotOne in [firstLetter, wildcardType]:
      for slotTwo in [secondLetter, wildcardType]:
        for slotThree in [thirdLetter, wildcardType]:
          let tableIndex = ((stopPosition * typeCount + slotOne) * typeCount + slotTwo) * typeCount + slotThree
          templateStamp[tableIndex] = currentStamp

  var instructionTypes = newSeq[int](instructionCount + 1)
  var dependencyIndices = newSeq[int](instructionCount + 1)
  for instructionIndex in 1 .. instructionCount:
    instructionTypes[instructionIndex] = nextType(inputData, scanPos)
    dependencyIndices[instructionIndex] = nextInteger(inputData, scanPos)

  var stateLists: array[0 .. 3, seq[BundleState]]
  for listIndex in 0 .. 3:
    stateLists[listIndex] = newSeqOfCap[BundleState](16)
  stateLists[0].add BundleState(bundles: 0, stops: 0, lastStop: -1)

  for bundleEnd in 0 .. instructionCount - 1:
    pruneInPlace stateLists[0]
    let bundleStart = bundleEnd + 1

    var canSkipStop = [false, false, false, false]
    var canPlaceStop = [false, false, false, false, false, false, false, false,
                        false, false, false, false, false, false, false, false]
    for slotMask in 1 .. 7:
      var groupSize = 0
      for slotIndex in 0 .. slotCount - 1:
        if (slotMask and (1 shl slotIndex)) != 0:
          groupSize += 1
      if bundleStart + groupSize - 1 > instructionCount:
        continue
      var slotLetters = [wildcardType, wildcardType, wildcardType]
      var filledCount = 0
      for slotIndex in 0 .. slotCount - 1:
        if (slotMask and (1 shl slotIndex)) != 0:
          slotLetters[slotIndex] = instructionTypes[bundleStart + filledCount]
          filledCount += 1
      for stopPosition in 0 .. stopCount - 1:
        let tableIndex = ((stopPosition * typeCount + slotLetters[0]) * typeCount +
                          slotLetters[1]) * typeCount + slotLetters[2]
        if templateStamp[tableIndex] == currentStamp:
          if stopPosition == 0:
            canSkipStop[groupSize] = true
          else:
            var beforeCount = 0
            for slotIndex in 0 .. stopPosition - 1:
              if (slotMask and (1 shl slotIndex)) != 0:
                beforeCount += 1
            canPlaceStop[groupSize * 4 + beforeCount] = true

    var relevantDep = [-1, -1, -1, -1]
    for ahead in 0 .. 2:
      let position = bundleStart + ahead
      if position <= instructionCount and dependencyIndices[position] > 0:
        relevantDep[ahead] = dependencyIndices[position]

    for stateIndex in 0 .. stateLists[0].len - 1:
      let stateValue = stateLists[0][stateIndex]
      for groupSize in 1 .. 3:
        let nextEnd = bundleEnd + groupSize
        if nextEnd > instructionCount:
          continue
        var bundleMaxDep = -1
        for ahead in 0 .. groupSize - 1:
          if relevantDep[ahead] > bundleMaxDep:
            bundleMaxDep = relevantDep[ahead]
        if canSkipStop[groupSize] and bundleMaxDep <= stateValue.lastStop:
          stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
              stops: stateValue.stops, lastStop: stateValue.lastStop)
          if nextEnd < instructionCount:
            stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
                stops: stateValue.stops + 1, lastStop: nextEnd)
        for beforeCount in 0 .. groupSize:
          if not canPlaceStop[groupSize * 4 + beforeCount]:
            continue
          let templateStop = bundleStart + beforeCount - 1
          var beforeMaxDep = -1
          for ahead in 0 .. beforeCount - 1:
            if relevantDep[ahead] > beforeMaxDep:
              beforeMaxDep = relevantDep[ahead]
          var afterMaxDep = -1
          for ahead in beforeCount .. groupSize - 1:
            if relevantDep[ahead] > afterMaxDep:
              afterMaxDep = relevantDep[ahead]
          if beforeMaxDep > stateValue.lastStop or afterMaxDep > templateStop:
            continue
          let extraStops = 1
          stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
              stops: stateValue.stops + extraStops, lastStop: templateStop)
          if nextEnd < instructionCount and nextEnd != templateStop:
            stateLists[groupSize].add BundleState(bundles: stateValue.bundles + 1,
                stops: stateValue.stops + extraStops + 1, lastStop: nextEnd)

    swap stateLists[0], stateLists[1]
    swap stateLists[1], stateLists[2]
    swap stateLists[2], stateLists[3]
    stateLists[3].setLen 0

  pruneInPlace stateLists[0]
  var bestBundles = high(int)
  var bestStops = high(int)
  for stateValue in stateLists[0]:
    if stateValue.bundles < bestBundles or
       (stateValue.bundles == bestBundles and stateValue.stops < bestStops):
      bestBundles = stateValue.bundles
      bestStops = stateValue.stops

  outputBuffer.add $bestBundles
  outputBuffer.add " "
  outputBuffer.add $bestStops
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer

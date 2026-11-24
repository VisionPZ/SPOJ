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

proc nextInteger(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - firstDigitValue)
    i += 1
  return value

proc nextType(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < 'A' or inputData[i] > 'J'):
    i += 1
  let typeValue = ord(inputData[i]) - firstLetterValue
  i += 1
  return typeValue

proc pruneInPlace(states: var seq[BundleState]) =
  if states.len == 0:
    return
  var minBundles = high(int)
  for stateValue in states:
    if stateValue.bundles < minBundles:
      minBundles = stateValue.bundles
  var j = 0
  for stateValue in states:
    if stateValue.bundles == minBundles:
      states[j] = stateValue
      j += 1
  states.setLen j
  for k in 1 .. states.len - 1:
    let current = states[k]
    var i = k - 1
    while i >= 0 and (states[i].stops > current.stops or
          (states[i].stops == current.stops and
           states[i].lastStop < current.lastStop)):
      states[i + 1] = states[i]
      i -= 1
    states[i + 1] = current
  j = 0
  var bestLast = -2
  for stateValue in states:
    if stateValue.lastStop > bestLast:
      states[j] = stateValue
      j += 1
      bestLast = stateValue.lastStop
  states.setLen j

var inputData = stdin.readAll()
var i = 0
let caseCount = nextInteger(inputData, i)
var templateStamp = newSeq[int](tableSize)
var currentStamp = 0
var outputBuffer = ""

for j in 0 .. caseCount - 1:
  currentStamp += 1
  let templateCount = nextInteger(inputData, i)
  let instructionCount = nextInteger(inputData, i)
  for k in 0 .. templateCount - 1:
    let firstLetter = nextType(inputData, i)
    let secondLetter = nextType(inputData, i)
    let thirdLetter = nextType(inputData, i)
    let l = nextInteger(inputData, i)
    for slotOne in [firstLetter, wildcardType]:
      for slotTwo in [secondLetter, wildcardType]:
        for slotThree in [thirdLetter, wildcardType]:
          let tableIndex = ((l * typeCount + slotOne) * typeCount + slotTwo) * typeCount + slotThree
          templateStamp[tableIndex] = currentStamp

  var instructionTypes = newSeq[int](instructionCount + 1)
  var dependencyIndices = newSeq[int](instructionCount + 1)
  for k in 1 .. instructionCount:
    instructionTypes[k] = nextType(inputData, i)
    dependencyIndices[k] = nextInteger(inputData, i)

  var stateLists: array[0 .. 3, seq[BundleState]]
  for k in 0 .. 3:
    stateLists[k] = newSeqOfCap[BundleState](16)
  stateLists[0].add BundleState(bundles: 0, stops: 0, lastStop: -1)

  for k in 0 .. instructionCount - 1:
    pruneInPlace stateLists[0]
    let bundleStart = k + 1

    var canSkipStop = [false, false, false, false]
    var canPlaceStop = [false, false, false, false, false, false, false, false,
                        false, false, false, false, false, false, false, false]
    for slotMask in 1 .. 7:
      var groupSize = 0
      for l in 0 .. slotCount - 1:
        if (slotMask and (1 shl l)) != 0:
          groupSize += 1
      if bundleStart + groupSize - 1 > instructionCount:
        continue
      var slotLetters = [wildcardType, wildcardType, wildcardType]
      var filledCount = 0
      for l in 0 .. slotCount - 1:
        if (slotMask and (1 shl l)) != 0:
          slotLetters[l] = instructionTypes[bundleStart + filledCount]
          filledCount += 1
      for i in 0 .. stopCount - 1:
        let tableIndex = ((i * typeCount + slotLetters[0]) * typeCount +
                          slotLetters[1]) * typeCount + slotLetters[2]
        if templateStamp[tableIndex] == currentStamp:
          if i == 0:
            canSkipStop[groupSize] = true
          else:
            var beforeCount = 0
            for j in 0 .. i - 1:
              if (slotMask and (1 shl j)) != 0:
                beforeCount += 1
            canPlaceStop[groupSize * 4 + beforeCount] = true

    var relevantDep = [-1, -1, -1, -1]
    for l in 0 .. 2:
      let position = bundleStart + l
      if position <= instructionCount and dependencyIndices[position] > 0:
        relevantDep[l] = dependencyIndices[position]

    for j in 0 .. stateLists[0].len - 1:
      let stateValue = stateLists[0][j]
      for groupSize in 1 .. 3:
        let nextEnd = k + groupSize
        if nextEnd > instructionCount:
          continue
        var bundleMaxDep = -1
        for l in 0 .. groupSize - 1:
          if relevantDep[l] > bundleMaxDep:
            bundleMaxDep = relevantDep[l]
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
          for l in 0 .. beforeCount - 1:
            if relevantDep[l] > beforeMaxDep:
              beforeMaxDep = relevantDep[l]
          var afterMaxDep = -1
          for l in beforeCount .. groupSize - 1:
            if relevantDep[l] > afterMaxDep:
              afterMaxDep = relevantDep[l]
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

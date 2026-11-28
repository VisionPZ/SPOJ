import tables

const flushBlockBytes = 1 shl 17
const moduloValue = 1000000007

proc encodeState(slots: array[8, int], markers: array[2, int], width: int): int64 =
  var key = int64(markers[0])
  key = key * 9 + int64(markers[1])
  for indexValue in 0 .. width:
    key = key * 9 + int64(slots[indexValue])
  return key

proc decodeState(key: int64, width: int, slots: var array[8, int], markers: var array[2, int]) =
  var remaining = key
  for indexValue in countdown(width, 0):
    slots[indexValue] = int(remaining mod 9)
    remaining = remaining div 9
  markers[1] = int(remaining mod 9)
  markers[0] = int(remaining div 9)

proc canonicalKey(slots: array[8, int], markers: array[2, int], width: int): int64 =
  var labelMap: array[9, int]
  var nextLabel = 1
  for indexValue in 0 .. width:
    let label = slots[indexValue]
    if label != 0 and labelMap[label] == 0:
      labelMap[label] = nextLabel
      nextLabel += 1
  var normalizedSlots: array[8, int]
  for indexValue in 0 .. width:
    normalizedSlots[indexValue] = labelMap[slots[indexValue]]
  var normalizedMarkers = [0, 0]
  var markerIndex = 0
  for sourceIndex in 0 .. 1:
    let oldMarker = markers[sourceIndex]
    if oldMarker != 0 and labelMap[oldMarker] != 0:
      let mapped = labelMap[oldMarker]
      if mapped != normalizedMarkers[0] and mapped != normalizedMarkers[1]:
        normalizedMarkers[markerIndex] = mapped
        markerIndex += 1
  if normalizedMarkers[0] > normalizedMarkers[1]:
    swap normalizedMarkers[0], normalizedMarkers[1]
  return encodeState(normalizedSlots, normalizedMarkers, width)

proc addMarker(markers: array[2, int], label: int): array[2, int] =
  result = markers
  if result[0] == 0:
    result[0] = label
  elif result[1] == 0:
    result[1] = label

proc removeMarker(markers: array[2, int], label: int): array[2, int] =
  result = markers
  for indexValue in 0 .. 1:
    if result[indexValue] == label:
      result[indexValue] = 0

proc hasMarker(markers: array[2, int], label: int): bool =
  return markers[0] == label or markers[1] == label

proc markerCount(markers: array[2, int]): int =
  var count = 0
  if markers[0] != 0:
    count += 1
  if markers[1] != 0:
    count += 1
  return count

proc slotsAreEmpty(slots: array[8, int], width: int): bool =
  for indexValue in 0 .. width:
    if slots[indexValue] != 0:
      return false
  return true

proc largestLabel(slots: array[8, int], width: int): int =
  var largest = 0
  for indexValue in 0 .. width:
    if slots[indexValue] > largest:
      largest = slots[indexValue]
  return largest

proc addState(states: var Table[int64, int64], key: int64, ways: int64) =
  states[key] = (states.getOrDefault(key) + ways) mod moduloValue

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc countRoutes(grid: seq[string], rowCount: int, columnCount: int): int64 =
  var rowsBefore = newSeq[int](rowCount + 1)
  var rowPrefix = newSeq[seq[int]](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    rowPrefix[rowIndex] = newSeq[int](columnCount + 1)
    for columnIndex in 0 .. columnCount - 1:
      let freeCell = grid[rowIndex][columnIndex] == '.'
      rowPrefix[rowIndex][columnIndex + 1] = rowPrefix[rowIndex][columnIndex]
      if freeCell:
        rowPrefix[rowIndex][columnIndex + 1] += 1
    rowsBefore[rowIndex + 1] = rowsBefore[rowIndex] + rowPrefix[rowIndex][columnCount]
  let totalFree = rowsBefore[rowCount]
  if totalFree == 0:
    return 0
  if totalFree == 1:
    return 1
  var states = initTable[int64, int64]()
  var followingStates = initTable[int64, int64]()
  var shiftedStates = initTable[int64, int64]()
  states[0] = 1
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 1 .. columnCount:
      followingStates.clear()
      let processedBefore = rowsBefore[rowIndex] + rowPrefix[rowIndex][columnIndex - 1]
      let isLastFree = totalFree - processedBefore - 1 == 0
      let rightAvailable = columnIndex < columnCount and grid[rowIndex][columnIndex] == '.'
      let downAvailable = rowIndex + 1 < rowCount and grid[rowIndex + 1][columnIndex - 1] == '.'
      for stateKey, ways in states:
        var baseSlots: array[8, int]
        var baseMarkers: array[2, int]
        decodeState(stateKey, columnCount, baseSlots, baseMarkers)
        if grid[rowIndex][columnIndex - 1] == '*':
          if baseSlots[columnIndex - 1] == 0 and baseSlots[columnIndex] == 0:
            addState(followingStates, stateKey, ways)
          continue
        let upPlug = baseSlots[columnIndex]
        let leftPlug = baseSlots[columnIndex - 1]
        if upPlug != 0 and leftPlug != 0 and upPlug == leftPlug:
          continue
        let incomingCount = (if upPlug != 0: 1 else: 0) + (if leftPlug != 0: 1 else: 0)
        var workSlots = baseSlots
        workSlots[columnIndex] = 0
        workSlots[columnIndex - 1] = 0
        let freshLabel = largestLabel(workSlots, columnCount) + 1
        if incomingCount == 0:
          if rightAvailable and downAvailable:
            var candidateSlots = workSlots
            candidateSlots[columnIndex - 1] = freshLabel
            candidateSlots[columnIndex] = freshLabel
            addState(followingStates, canonicalKey(candidateSlots, baseMarkers, columnCount), ways)
          if rightAvailable:
            var candidateSlots = workSlots
            candidateSlots[columnIndex] = freshLabel
            if markerCount(baseMarkers) < 2:
              addState(followingStates, canonicalKey(candidateSlots, addMarker(baseMarkers, freshLabel), columnCount), ways)
          if downAvailable:
            var candidateSlots = workSlots
            candidateSlots[columnIndex - 1] = freshLabel
            if markerCount(baseMarkers) < 2:
              addState(followingStates, canonicalKey(candidateSlots, addMarker(baseMarkers, freshLabel), columnCount), ways)
        elif incomingCount == 1:
          let plugLabel = if upPlug != 0: upPlug else: leftPlug
          if downAvailable:
            var candidateSlots = workSlots
            candidateSlots[columnIndex - 1] = plugLabel
            addState(followingStates, canonicalKey(candidateSlots, baseMarkers, columnCount), ways)
          if rightAvailable:
            var candidateSlots = workSlots
            candidateSlots[columnIndex] = plugLabel
            addState(followingStates, canonicalKey(candidateSlots, baseMarkers, columnCount), ways)
          if hasMarker(baseMarkers, plugLabel):
            let clearedMarkers = removeMarker(baseMarkers, plugLabel)
            if isLastFree and slotsAreEmpty(workSlots, columnCount) and markerCount(clearedMarkers) == 0:
              addState(followingStates, canonicalKey(workSlots, clearedMarkers, columnCount), ways)
          elif markerCount(baseMarkers) < 2:
            addState(followingStates, canonicalKey(workSlots, addMarker(baseMarkers, plugLabel), columnCount), ways)
        else:
          var candidateSlots = workSlots
          for slotIndex in 0 .. columnCount:
            if candidateSlots[slotIndex] == leftPlug:
              candidateSlots[slotIndex] = upPlug
          if hasMarker(baseMarkers, upPlug) and hasMarker(baseMarkers, leftPlug):
            if isLastFree and slotsAreEmpty(candidateSlots, columnCount):
              var clearedMarkers = [0, 0]
              addState(followingStates, canonicalKey(candidateSlots, clearedMarkers, columnCount), ways)
          else:
            var candidateMarkers = baseMarkers
            for markerIndex in 0 .. 1:
              if candidateMarkers[markerIndex] == leftPlug:
                candidateMarkers[markerIndex] = upPlug
            addState(followingStates, canonicalKey(candidateSlots, candidateMarkers, columnCount), ways)
      swap states, followingStates
    shiftedStates.clear()
    for stateKey, stateValue in states:
      var oldSlots: array[8, int]
      var oldMarkers: array[2, int]
      decodeState(stateKey, columnCount, oldSlots, oldMarkers)
      var newSlots: array[8, int]
      newSlots[0] = 0
      for slotIndex in 1 .. columnCount:
        newSlots[slotIndex] = oldSlots[slotIndex - 1]
      addState(shiftedStates, canonicalKey(newSlots, oldMarkers, columnCount), stateValue)
    swap states, shiftedStates
  return (states.getOrDefault(0) * 2) mod moduloValue

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  var grid = newSeq[string](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = nextToken(inputData, scanPos)
  appendOutput($(countRoutes(grid, rowCount, columnCount)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

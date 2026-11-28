const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var rowCount = nextInt(inputData, scanPos)
var columnCount = nextInt(inputData, scanPos)
var areaLimit = nextInt(inputData, scanPos)

while not (rowCount == 0 and columnCount == 0 and areaLimit == 0):
  var medicines = newSeq[int]()
  var medicineValue = nextInt(inputData, scanPos)
  while medicineValue != -1:
    medicines.add medicineValue
    medicineValue = nextInt(inputData, scanPos)
  let medicineLength = medicines.len

  var typeValues = newSeq[int]()
  var medicineTypes = newSeq[int](medicineLength)
  for dayIndex in 0 .. medicineLength - 1:
    var found = -1
    for typeIndex in 0 .. typeValues.len - 1:
      if typeValues[typeIndex] == medicines[dayIndex]:
        found = typeIndex
        break
    if found == -1:
      found = typeValues.len
      typeValues.add medicines[dayIndex]
    medicineTypes[dayIndex] = found
  let typeCount = typeValues.len

  var occurrences = newSeq[seq[int]](typeCount)
  for dayIndex in 0 .. medicineLength - 1:
    occurrences[medicineTypes[dayIndex]].add dayIndex + 1
  var nextDays = newSeq[seq[int]](typeCount)
  var occurrenceCounts = newSeq[int](typeCount)
  var initialSupport = newSeq[int](typeCount)
  for typeIndex in 0 .. typeCount - 1:
    let count = occurrences[typeIndex].len
    occurrenceCounts[typeIndex] = count
    nextDays[typeIndex] = newSeq[int](count + 1)
    for occurrenceIndex in 0 .. count - 1:
      nextDays[typeIndex][occurrenceIndex] = occurrences[typeIndex][occurrenceIndex]
    nextDays[typeIndex][count] = medicineLength + 1
    initialSupport[typeIndex] = nextDays[typeIndex][0] - 1

  var segmentSize = 1
  while segmentSize < typeCount:
    segmentSize *= 2
  var segmentMin = newSeq[int](2 * segmentSize)
  for nodeIndex in 0 .. 2 * segmentSize - 1:
    segmentMin[nodeIndex] = medicineLength + 1
  for typeIndex in 0 .. typeCount - 1:
    segmentMin[segmentSize + typeIndex] = initialSupport[typeIndex]
  for nodeIndex in countdown(segmentSize - 1, 1):
    if segmentMin[2 * nodeIndex] < segmentMin[2 * nodeIndex + 1]:
      segmentMin[nodeIndex] = segmentMin[2 * nodeIndex]
    else:
      segmentMin[nodeIndex] = segmentMin[2 * nodeIndex + 1]

  proc setSupport(typeIndex: int, value: int) =
    var nodeIndex = segmentSize + typeIndex
    segmentMin[nodeIndex] = value
    nodeIndex = nodeIndex div 2
    while nodeIndex >= 1:
      if segmentMin[2 * nodeIndex] < segmentMin[2 * nodeIndex + 1]:
        segmentMin[nodeIndex] = segmentMin[2 * nodeIndex]
      else:
        segmentMin[nodeIndex] = segmentMin[2 * nodeIndex + 1]
      nodeIndex = nodeIndex div 2

  var gridTypes = newSeq[int](rowCount * columnCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let herb = nextInt(inputData, scanPos)
      var found = -1
      for typeIndex in 0 .. typeCount - 1:
        if typeValues[typeIndex] == herb:
          found = typeIndex
          break
      gridTypes[rowIndex * columnCount + columnIndex] = found

  var typeCounts = newSeq[int](typeCount)
  var markGeneration = newSeq[int](typeCount)
  var changedTypes = newSeq[int]()
  var generation = 0
  var bestDays = 0
  var bestTopRow = 1
  var bestLeftColumn = 1
  var bestBottomRow = 1
  var bestRightColumn = 1

  for topRow in 1 .. rowCount:
    let largestHeight = min(rowCount - topRow + 1, areaLimit)
    for bottomRow in topRow .. topRow + largestHeight - 1:
      let height = bottomRow - topRow + 1
      var widthLimit = areaLimit div height
      if widthLimit < 1:
        continue
      if widthLimit > columnCount:
        widthLimit = columnCount
      for leftColumn in 1 .. columnCount:
        generation += 1
        changedTypes.setLen 0
        let maxRight = min(columnCount, leftColumn + widthLimit - 1)
        for rightColumn in leftColumn .. maxRight:
          for rowIndex in topRow .. bottomRow:
            let typeIndex = gridTypes[(rowIndex - 1) * columnCount + rightColumn - 1]
            if typeIndex >= 0:
              if markGeneration[typeIndex] != generation:
                markGeneration[typeIndex] = generation
                changedTypes.add typeIndex
              typeCounts[typeIndex] += 1
              let used = typeCounts[typeIndex]
              var limit = medicineLength + 1
              if used <= occurrenceCounts[typeIndex]:
                limit = nextDays[typeIndex][used]
              setSupport(typeIndex, limit - 1)
          var days = segmentMin[1]
          if days > medicineLength:
            days = medicineLength
          if days > bestDays or
             (days == bestDays and (topRow < bestTopRow or
              (topRow == bestTopRow and (leftColumn < bestLeftColumn or
               (leftColumn == bestLeftColumn and (bottomRow < bestBottomRow or
                (bottomRow == bestBottomRow and rightColumn < bestRightColumn))))))):
            bestDays = days
            bestTopRow = topRow
            bestLeftColumn = leftColumn
            bestBottomRow = bottomRow
            bestRightColumn = rightColumn
          if days == medicineLength:
            break
        for typeIndex in changedTypes:
          typeCounts[typeIndex] = 0
          setSupport(typeIndex, initialSupport[typeIndex])

  appendOutput($bestDays & " " & $bestTopRow & " " & $bestLeftColumn & " " &
               $bestBottomRow & " " & $bestRightColumn & "\n")
  rowCount = nextInt(inputData, scanPos)
  columnCount = nextInt(inputData, scanPos)
  areaLimit = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0

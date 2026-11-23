var inputData = stdin.readAll()
var scanPos = 0

proc skipWhitespace(data: string, pos: var int) =
  while pos < data.len and ord(data[pos]) <= 32:
    inc pos

proc nextInt(data: string, pos: var int): int =
  skipWhitespace(data, pos)
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + (ord(data[pos]) - 48)
    inc pos
  return value

proc nextRowMask(data: string, pos: var int, width: int): int =
  skipWhitespace(data, pos)
  var mask = 0
  var colIndex = 0
  while colIndex < width and pos < data.len:
    if data[pos] == '1':
      mask = mask or (1 shl colIndex)
    inc pos
    inc colIndex
  return mask

proc crossRow(value: int, widthMask: int): int =
  return value xor ((value shl 1) and widthMask) xor (value shr 1)

const flushBlockBytes = 1 shl 18
var outputBuffer = ""

proc emit(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let width = nextInt(inputData, scanPos)
  let height = nextInt(inputData, scanPos)
  if width == 0 and height == 0:
    break

  var transposed = false
  var workWidth = width
  var workHeight = height
  if height < width:
    transposed = true
    workWidth = height
    workHeight = width

  var sourceRows: array[16, int]
  for rowIndex in 0 .. height - 1:
    sourceRows[rowIndex] = nextRowMask(inputData, scanPos, width)

  var workRows: array[16, int]
  if transposed:
    for columnIndex in 0 .. width - 1:
      var rowMask = 0
      for rowIndex in 0 .. height - 1:
        if (sourceRows[rowIndex] and (1 shl columnIndex)) != 0:
          rowMask = rowMask or (1 shl rowIndex)
      workRows[columnIndex] = rowMask
  else:
    for rowIndex in 0 .. height - 1:
      workRows[rowIndex] = sourceRows[rowIndex]

  let allOn = (1 shl workWidth) - 1

  var rowImages: array[16, array[16, int]]
  var offsets: array[16, int]
  for colIndex in 0 .. workWidth - 1:
    rowImages[0][colIndex] = 1 shl colIndex
    rowImages[1][colIndex] = crossRow(1 shl colIndex, allOn)
  offsets[1] = workRows[0] xor allOn
  for rowIndex in 1 .. workHeight - 2:
    for colIndex in 0 .. workWidth - 1:
      rowImages[rowIndex + 1][colIndex] =
        crossRow(rowImages[rowIndex][colIndex], allOn) xor rowImages[rowIndex - 1][colIndex]
    offsets[rowIndex + 1] =
      crossRow(offsets[rowIndex], allOn) xor offsets[rowIndex - 1] xor
      workRows[rowIndex] xor allOn

  var finalCoeff: array[16, int]
  for colIndex in 0 .. workWidth - 1:
    finalCoeff[colIndex] =
      crossRow(rowImages[workHeight - 1][colIndex], allOn) xor rowImages[workHeight - 2][colIndex]
  let finalTarget = workRows[workHeight - 1] xor allOn xor
                    crossRow(offsets[workHeight - 1], allOn) xor offsets[workHeight - 2]

  var equations: array[16, int]
  for bitIndex in 0 .. workWidth - 1:
    var equation = 0
    for colIndex in 0 .. workWidth - 1:
      if ((finalCoeff[colIndex] shr bitIndex) and 1) != 0:
        equation = equation or (1 shl colIndex)
    if ((finalTarget shr bitIndex) and 1) != 0:
      equation = equation or (1 shl workWidth)
    equations[bitIndex] = equation

  var pivotCount = 0
  var pivotColumns: array[16, int]
  for colIndex in 0 .. workWidth - 1:
    var selected = -1
    for rowIndex in pivotCount .. workWidth - 1:
      if ((equations[rowIndex] shr colIndex) and 1) != 0:
        selected = rowIndex
        break
    if selected < 0:
      continue
    let held = equations[pivotCount]
    equations[pivotCount] = equations[selected]
    equations[selected] = held
    for rowIndex in 0 .. workWidth - 1:
      if rowIndex != pivotCount and ((equations[rowIndex] shr colIndex) and 1) != 0:
        equations[rowIndex] = equations[rowIndex] xor equations[pivotCount]
    pivotColumns[pivotCount] = colIndex
    inc pivotCount

  var inconsistent = false
  for rowIndex in pivotCount .. workWidth - 1:
    if ((equations[rowIndex] shr workWidth) and 1) != 0:
      inconsistent = true

  if inconsistent:
    emit("-1\n")
  else:
    var firstPattern = 0
    var pivotIndex = pivotCount - 1
    while pivotIndex >= 0:
      if ((equations[pivotIndex] shr workWidth) and 1) != 0:
        firstPattern = firstPattern or (1 shl pivotColumns[pivotIndex])
      dec pivotIndex

    var pressRows: array[16, int]
    pressRows[0] = firstPattern
    pressRows[1] = crossRow(firstPattern, allOn) xor offsets[1]
    for rowIndex in 1 .. workHeight - 2:
      pressRows[rowIndex + 1] = workRows[rowIndex] xor allOn xor
                                crossRow(pressRows[rowIndex], allOn) xor pressRows[rowIndex - 1]

    var stepCount = 0
    for rowIndex in 0 .. workHeight - 1:
      for colIndex in 0 .. workWidth - 1:
        if ((pressRows[rowIndex] shr colIndex) and 1) != 0:
          inc stepCount

    emit($stepCount)
    emit("\n")
    for rowIndex in 0 .. workHeight - 1:
      for colIndex in 0 .. workWidth - 1:
        if ((pressRows[rowIndex] shr colIndex) and 1) != 0:
          if transposed:
            emit($(rowIndex + 1))
            emit(" ")
            emit($(colIndex + 1))
            emit("\n")
          else:
            emit($(colIndex + 1))
            emit(" ")
            emit($(rowIndex + 1))
            emit("\n")

stdout.write outputBuffer

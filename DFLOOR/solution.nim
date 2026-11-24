var inputData = stdin.readAll()
var i = 0

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and ord(data[i]) <= 32:
    inc i

proc nextInt(data: string, i: var int): int =
  skipWhitespace(data, i)
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + (ord(data[i]) - 48)
    inc i
  return value

proc nextRowMask(data: string, i: var int, width: int): int =
  skipWhitespace(data, i)
  var mask = 0
  var k = 0
  while k < width and i < data.len:
    if data[i] == '1':
      mask = mask or (1 shl k)
    inc i
    inc k
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
  let width = nextInt(inputData, i)
  let height = nextInt(inputData, i)
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
  for j in 0 .. height - 1:
    sourceRows[j] = nextRowMask(inputData, i, width)

  var workRows: array[16, int]
  if transposed:
    for k in 0 .. width - 1:
      var rowMask = 0
      for j in 0 .. height - 1:
        if (sourceRows[j] and (1 shl k)) != 0:
          rowMask = rowMask or (1 shl j)
      workRows[k] = rowMask
  else:
    for j in 0 .. height - 1:
      workRows[j] = sourceRows[j]

  let allOn = (1 shl workWidth) - 1

  var rowImages: array[16, array[16, int]]
  var offsets: array[16, int]
  for k in 0 .. workWidth - 1:
    rowImages[0][k] = 1 shl k
    rowImages[1][k] = crossRow(1 shl k, allOn)
  offsets[1] = workRows[0] xor allOn
  for j in 1 .. workHeight - 2:
    for k in 0 .. workWidth - 1:
      rowImages[j + 1][k] =
        crossRow(rowImages[j][k], allOn) xor rowImages[j - 1][k]
    offsets[j + 1] =
      crossRow(offsets[j], allOn) xor offsets[j - 1] xor
      workRows[j] xor allOn

  var finalCoeff: array[16, int]
  for k in 0 .. workWidth - 1:
    finalCoeff[k] =
      crossRow(rowImages[workHeight - 1][k], allOn) xor rowImages[workHeight - 2][k]
  let finalTarget = workRows[workHeight - 1] xor allOn xor
                    crossRow(offsets[workHeight - 1], allOn) xor offsets[workHeight - 2]

  var equations: array[16, int]
  for l in 0 .. workWidth - 1:
    var equation = 0
    for k in 0 .. workWidth - 1:
      if ((finalCoeff[k] shr l) and 1) != 0:
        equation = equation or (1 shl k)
    if ((finalTarget shr l) and 1) != 0:
      equation = equation or (1 shl workWidth)
    equations[l] = equation

  var pivotCount = 0
  var pivotColumns: array[16, int]
  for k in 0 .. workWidth - 1:
    var selected = -1
    for j in pivotCount .. workWidth - 1:
      if ((equations[j] shr k) and 1) != 0:
        selected = j
        break
    if selected < 0:
      continue
    let held = equations[pivotCount]
    equations[pivotCount] = equations[selected]
    equations[selected] = held
    for j in 0 .. workWidth - 1:
      if j != pivotCount and ((equations[j] shr k) and 1) != 0:
        equations[j] = equations[j] xor equations[pivotCount]
    pivotColumns[pivotCount] = k
    inc pivotCount

  var inconsistent = false
  for j in pivotCount .. workWidth - 1:
    if ((equations[j] shr workWidth) and 1) != 0:
      inconsistent = true

  if inconsistent:
    emit("-1\n")
  else:
    var firstPattern = 0
    var i = pivotCount - 1
    while i >= 0:
      if ((equations[i] shr workWidth) and 1) != 0:
        firstPattern = firstPattern or (1 shl pivotColumns[i])
      dec i

    var pressRows: array[16, int]
    pressRows[0] = firstPattern
    pressRows[1] = crossRow(firstPattern, allOn) xor offsets[1]
    for j in 1 .. workHeight - 2:
      pressRows[j + 1] = workRows[j] xor allOn xor
                                crossRow(pressRows[j], allOn) xor pressRows[j - 1]

    var stepCount = 0
    for j in 0 .. workHeight - 1:
      for k in 0 .. workWidth - 1:
        if ((pressRows[j] shr k) and 1) != 0:
          inc stepCount

    emit($stepCount)
    emit("\n")
    for j in 0 .. workHeight - 1:
      for k in 0 .. workWidth - 1:
        if ((pressRows[j] shr k) and 1) != 0:
          if transposed:
            emit($(j + 1))
            emit(" ")
            emit($(k + 1))
            emit("\n")
          else:
            emit($(k + 1))
            emit(" ")
            emit($(j + 1))
            emit("\n")

stdout.write outputBuffer

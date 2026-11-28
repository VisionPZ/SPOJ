const flushBlockBytes = 1 shl 17

var inputData: string
var lineReadBuffer: string
while readLine(stdin, lineReadBuffer):
  inputData.add lineReadBuffer
  inputData.add '\n'

var i = 0

proc nextInt(): int64 =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i = i + 1
  var scannedValue: int64 = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    scannedValue = scannedValue * 10 + int64(int(inputData[i]) - 48)
    i = i + 1
  return scannedValue

var caseCount = int(nextInt())
var outputBuffer: string

for _ in 1 .. caseCount:
  var bookCount = int(nextInt())
  var scribeCount = int(nextInt())
  var bookPages = newSeq[int64](bookCount)
  var heaviestBook: int64 = 0
  var totalPages: int64 = 0
  for j in 0 .. bookCount - 1:
    bookPages[j] = nextInt()
    if bookPages[j] > heaviestBook: heaviestBook = bookPages[j]
    totalPages = totalPages + bookPages[j]
  var loadLow = heaviestBook
  var loadHigh = totalPages
  while loadLow < loadHigh:
    var loadGuess = (loadLow + loadHigh) div 2
    var scribesUsed = 1
    var runningSum: int64 = 0
    for j in 0 .. bookCount - 1:
      if runningSum + bookPages[j] > loadGuess:
        scribesUsed = scribesUsed + 1
        runningSum = bookPages[j]
      else:
        runningSum = runningSum + bookPages[j]
    if scribesUsed <= scribeCount:
      loadHigh = loadGuess
    else:
      loadLow = loadGuess + 1
  var optimalLoad = loadLow
  var partFirstBook = newSeq[int](scribeCount)
  var booksRemaining = bookCount
  for j in countdown(scribeCount - 1, 0):
    var takenCount = 1
    var takenSum = bookPages[booksRemaining - 1]
    while booksRemaining - takenCount > j and
        takenSum + bookPages[booksRemaining - takenCount - 1] <= optimalLoad:
      takenSum = takenSum + bookPages[booksRemaining - takenCount - 1]
      takenCount = takenCount + 1
    partFirstBook[j] = booksRemaining - takenCount
    booksRemaining = partFirstBook[j]
  var currentPart = 0
  for j in 0 .. bookCount - 1:
    if j > 0:
      if currentPart + 1 < scribeCount and j == partFirstBook[currentPart + 1]:
        outputBuffer.add " / "
        currentPart = currentPart + 1
      else:
        outputBuffer.add ' '
    outputBuffer.add $bookPages[j]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

const flushBlockBytes = 1 shl 17

var inputData: string
var lineReadBuffer: string
while readLine(stdin, lineReadBuffer):
  inputData.add lineReadBuffer
  inputData.add '\n'

var scanPosition = 0

proc nextInt(): int64 =
  while scanPosition < inputData.len and (inputData[scanPosition] < '0' or inputData[scanPosition] > '9'):
    scanPosition = scanPosition + 1
  var scannedValue: int64 = 0
  while scanPosition < inputData.len and inputData[scanPosition] >= '0' and inputData[scanPosition] <= '9':
    scannedValue = scannedValue * 10 + int64(int(inputData[scanPosition]) - 48)
    scanPosition = scanPosition + 1
  return scannedValue

var caseCount = int(nextInt())
var outputBuffer: string

for _ in 1 .. caseCount:
  var bookCount = int(nextInt())
  var scribeCount = int(nextInt())
  var bookPages = newSeq[int64](bookCount)
  var heaviestBook: int64 = 0
  var totalPages: int64 = 0
  for bookIndex in 0 .. bookCount - 1:
    bookPages[bookIndex] = nextInt()
    if bookPages[bookIndex] > heaviestBook: heaviestBook = bookPages[bookIndex]
    totalPages = totalPages + bookPages[bookIndex]
  var loadLow = heaviestBook
  var loadHigh = totalPages
  while loadLow < loadHigh:
    var loadGuess = (loadLow + loadHigh) div 2
    var scribesUsed = 1
    var runningSum: int64 = 0
    for bookIndex in 0 .. bookCount - 1:
      if runningSum + bookPages[bookIndex] > loadGuess:
        scribesUsed = scribesUsed + 1
        runningSum = bookPages[bookIndex]
      else:
        runningSum = runningSum + bookPages[bookIndex]
    if scribesUsed <= scribeCount:
      loadHigh = loadGuess
    else:
      loadLow = loadGuess + 1
  var optimalLoad = loadLow
  var partFirstBook = newSeq[int](scribeCount)
  var booksRemaining = bookCount
  for scriberIndex in countdown(scribeCount - 1, 0):
    var takenCount = 1
    var takenSum = bookPages[booksRemaining - 1]
    while booksRemaining - takenCount > scriberIndex and
        takenSum + bookPages[booksRemaining - takenCount - 1] <= optimalLoad:
      takenSum = takenSum + bookPages[booksRemaining - takenCount - 1]
      takenCount = takenCount + 1
    partFirstBook[scriberIndex] = booksRemaining - takenCount
    booksRemaining = partFirstBook[scriberIndex]
  var currentPart = 0
  for bookIndex in 0 .. bookCount - 1:
    if bookIndex > 0:
      if currentPart + 1 < scribeCount and bookIndex == partFirstBook[currentPart + 1]:
        outputBuffer.add " / "
        currentPart = currentPart + 1
      else:
        outputBuffer.add ' '
    outputBuffer.add $bookPages[bookIndex]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

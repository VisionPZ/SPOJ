const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

type Booklet = tuple[pages: int, listIndex: int]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc sortBooklets(booklets: var seq[Booklet]) =
  for outerIndex in 1 ..< booklets.len:
    let current = booklets[outerIndex]
    var innerIndex = outerIndex - 1
    while innerIndex >= 0 and booklets[innerIndex].pages > current.pages:
      booklets[innerIndex + 1] = booklets[innerIndex]
      innerIndex -= 1
    booklets[innerIndex + 1] = current

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 0..<caseCount:
  let schoolCount = nextInt(inputData, scanPos)
  let querySchool = nextInt(inputData, scanPos)
  let bookletCount = nextInt(inputData, scanPos)
  var booklets: seq[Booklet]
  booklets.setLen(bookletCount)
  for listIndex in 0..<bookletCount:
    booklets[listIndex] = (pages: nextInt(inputData, scanPos), listIndex: listIndex)
  sortBooklets(booklets)
  let lowerCount = bookletCount div schoolCount
  let extraCount = bookletCount mod schoolCount
  let upperCount = lowerCount + (if extraCount > 0: 1 else: 0)
  let groupStart = if querySchool < extraCount:
    querySchool * upperCount
  else:
    extraCount * upperCount + (querySchool - extraCount) * lowerCount
  let groupSize = if querySchool < extraCount: upperCount else: lowerCount
  var earliestIndex = bookletCount
  var answer = 0
  for groupPos in groupStart ..< groupStart + groupSize:
    if booklets[groupPos].listIndex < earliestIndex:
      earliestIndex = booklets[groupPos].listIndex
      answer = booklets[groupPos].pages
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

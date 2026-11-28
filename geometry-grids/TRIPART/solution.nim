const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const tableBits = 15
const tableSize = 1 shl tableBits
const tableMask = tableSize - 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var seenMark: array[tableSize, int]
var seenShape: array[tableSize, tuple[x, y, z: int]]
var generation = 0

proc gcd2(first, second: int): int =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

proc normalize(first, second, third: int): tuple[x, y, z: int] =
  var left = first
  var middle = second
  var right = third
  if left > middle: swap(left, middle)
  if middle > right: swap(middle, right)
  if left > middle: swap(left, middle)
  let divisor = gcd2(gcd2(left, middle), right)
  result.x = left div divisor
  result.y = middle div divisor
  result.z = right div divisor

proc shapeSlot(x, y, z: int): int =
  (x * 1000003 + y * 100003 + z * 1009) and tableMask

proc addShape(x, y, z: int): bool =
  var slot = shapeSlot(x, y, z)
  while seenMark[slot] == generation:
    if seenShape[slot].x == x and seenShape[slot].y == y and seenShape[slot].z == z:
      return false
    slot = (slot + 1) and tableMask
  seenMark[slot] = generation
  seenShape[slot].x = x
  seenShape[slot].y = y
  seenShape[slot].z = z
  return true

proc countStyles(firstSide, secondSide, thirdSide: int): int =
  let start = normalize(firstSide * firstSide, secondSide * secondSide, thirdSide * thirdSide)
  inc generation
  discard addShape(start.x, start.y, start.z)
  var work: seq[tuple[x, y, z: int]]
  work.add start
  var k = 0
  while k < work.len:
    let current = work[k]
    k += 1
    let median4 = 2 * current.x + 2 * current.y - current.z
    let firstChild = normalize(4 * current.x, current.z, median4)
    if addShape(firstChild.x, firstChild.y, firstChild.z):
      work.add firstChild
    let secondChild = normalize(4 * current.y, current.z, median4)
    if addShape(secondChild.x, secondChild.y, secondChild.z):
      work.add secondChild
  return work.len

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let firstSide = nextInt(inputData, i)
  let secondSide = nextInt(inputData, i)
  let thirdSide = nextInt(inputData, i)
  appendOutput($(countStyles(firstSide, secondSide, thirdSide)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

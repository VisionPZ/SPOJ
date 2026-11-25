import algorithm

const flushBlockBytes = 1 shl 17

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

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type DriveCapacities = tuple[oldCapacity: int64, newCapacity: int64]

proc byOldCapacity(first: DriveCapacities, second: DriveCapacities): int =
  if first.oldCapacity < second.oldCapacity:
    return -1
  elif first.oldCapacity > second.oldCapacity:
    return 1
  return 0

proc byNewCapacityDescending(first: DriveCapacities, second: DriveCapacities): int =
  if first.newCapacity > second.newCapacity:
    return -1
  elif first.newCapacity < second.newCapacity:
    return 1
  return 0

while hasMoreData(inputData, scanPos):
  let driveCount = nextInt(inputData, scanPos)
  var growingDrives: seq[DriveCapacities] = @[]
  var shrinkingDrives: seq[DriveCapacities] = @[]
  for driveIndex in 0 .. driveCount - 1:
    let oldCapacity = int64(nextInt(inputData, scanPos))
    let newCapacity = int64(nextInt(inputData, scanPos))
    if newCapacity >= oldCapacity:
      growingDrives.add((oldCapacity, newCapacity))
    else:
      shrinkingDrives.add((oldCapacity, newCapacity))
  growingDrives.sort(byOldCapacity)
  shrinkingDrives.sort(byNewCapacityDescending)
  var freeSpace: int64 = 0
  var extraCapacity: int64 = 0
  for driveIndex in 0 .. growingDrives.len - 1:
    let drive = growingDrives[driveIndex]
    if freeSpace < drive.oldCapacity:
      extraCapacity += drive.oldCapacity - freeSpace
      freeSpace = 0
    else:
      freeSpace -= drive.oldCapacity
    freeSpace += drive.newCapacity
  for driveIndex in 0 .. shrinkingDrives.len - 1:
    let drive = shrinkingDrives[driveIndex]
    if freeSpace < drive.oldCapacity:
      extraCapacity += drive.oldCapacity - freeSpace
      freeSpace = 0
    else:
      freeSpace -= drive.oldCapacity
    freeSpace += drive.newCapacity
  appendOutput($extraCapacity)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

type Schedule = object
  startTime: int
  finishTime: int

const flushBlockBytes = 1 shl 17
const minutesPerHour = 60
const cleanupMinutes = 30

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let roomCount = nextInt(inputData, scanPos)
let eventCount = nextInt(inputData, scanPos)
var schedules = newSeq[Schedule](eventCount)
for eventIndex in 0 .. eventCount - 1:
  let startHour = nextInt(inputData, scanPos)
  let startMinute = nextInt(inputData, scanPos)
  let endHour = nextInt(inputData, scanPos)
  let endMinute = nextInt(inputData, scanPos)
  let participantCount = nextInt(inputData, scanPos)
  schedules[eventIndex].startTime = startHour * minutesPerHour + startMinute
  schedules[eventIndex].finishTime = endHour * minutesPerHour + endMinute + cleanupMinutes + participantCount

for sortIndex in 1 .. eventCount - 1:
  let currentSchedule = schedules[sortIndex]
  var previousIndex = sortIndex - 1
  while previousIndex >= 0:
    let earlierSchedule = schedules[previousIndex]
    if earlierSchedule.finishTime < currentSchedule.finishTime:
      break
    if earlierSchedule.finishTime == currentSchedule.finishTime and earlierSchedule.startTime <= currentSchedule.startTime:
      break
    schedules[previousIndex + 1] = earlierSchedule
    previousIndex -= 1
  schedules[previousIndex + 1] = currentSchedule

var roomFreetimes = newSeq[int](0)
var scheduledCount = 0
for eventIndex in 0 .. eventCount - 1:
  let currentStart = schedules[eventIndex].startTime
  let currentFinish = schedules[eventIndex].finishTime
  var lowIndex = 0
  var highIndex = roomFreetimes.len - 1
  var bestRoomIndex = -1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if roomFreetimes[middleIndex] <= currentStart:
      bestRoomIndex = middleIndex
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  if bestRoomIndex >= 0:
    roomFreetimes[bestRoomIndex] = currentFinish
    while bestRoomIndex + 1 < roomFreetimes.len and roomFreetimes[bestRoomIndex] > roomFreetimes[bestRoomIndex + 1]:
      swap roomFreetimes[bestRoomIndex], roomFreetimes[bestRoomIndex + 1]
      bestRoomIndex += 1
    scheduledCount += 1
  elif roomFreetimes.len < roomCount:
    roomFreetimes.add currentFinish
    var insertedIndex = roomFreetimes.len - 1
    while insertedIndex > 0 and roomFreetimes[insertedIndex] < roomFreetimes[insertedIndex - 1]:
      swap roomFreetimes[insertedIndex], roomFreetimes[insertedIndex - 1]
      insertedIndex -= 1
    scheduledCount += 1

appendOutput("Jumlah kegiatan/acara: " & $scheduledCount)
outputBuffer.add '\n'
appendOutput("Jumlah ruang: " & $roomFreetimes.len)
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

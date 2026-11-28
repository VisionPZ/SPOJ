import algorithm

const flushBlockBytes = 1 shl 17

type ScheduledTask = object
  duration: int64
  originalIndex: int

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

proc prefixQuery(tree: seq[int], upperIndex: int): int =
  var total = 0
  var cursor = upperIndex
  while cursor > 0:
    total += tree[cursor]
    cursor -= cursor and (-cursor)
  return total

proc addToTree(tree: var seq[int], startIndex: int, deltaValue: int) =
  var cursor = startIndex
  while cursor <= tree.len - 1:
    tree[cursor] += deltaValue
    cursor += cursor and (-cursor)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let taskCount = nextInt(inputData, scanPos)
var taskList = newSeq[ScheduledTask](taskCount)
for taskIndex in 0 .. taskCount - 1:
  taskList[taskIndex].duration = int64(nextInt(inputData, scanPos))
  taskList[taskIndex].originalIndex = taskIndex
taskList.sort(proc (leftTask, rightTask: ScheduledTask): int =
    cmp(leftTask.duration, rightTask.duration))
var answers = newSeq[int64](taskCount)
var activeTree = newSeq[int](taskCount + 1)
for taskIndex in 0 .. taskCount - 1:
  addToTree(activeTree, taskIndex + 1, 1)
var activeCount = taskCount
var elapsedBefore = (taskList[0].duration - 1) * int64(taskCount)
var groupStart = 0
while groupStart < taskCount:
  let currentDuration = taskList[groupStart].duration
  var groupEnd = groupStart + 1
  while groupEnd < taskCount and taskList[groupEnd].duration == currentDuration:
    groupEnd += 1
  for groupIndex in groupStart .. groupEnd - 1:
    let taskIndex = taskList[groupIndex].originalIndex
    let earlierActive = prefixQuery(activeTree, taskIndex)
    answers[taskIndex] = elapsedBefore + int64(earlierActive) + 1
  for groupIndex in groupStart .. groupEnd - 1:
    addToTree(activeTree, taskList[groupIndex].originalIndex + 1, -1)
  let nextActiveCount = activeCount - (groupEnd - groupStart)
  if groupEnd < taskCount:
    let nextDuration = taskList[groupEnd].duration
    let skippedRounds = nextDuration - currentDuration - 1
    elapsedBefore = elapsedBefore + int64(activeCount) +
        skippedRounds * int64(nextActiveCount)
  activeCount = nextActiveCount
  groupStart = groupEnd
for answerValue in answers:
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

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
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9') and data[probe] != '-':
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false

proc nextInstruction(data: string, pos: var int): tuple[kind: char, argument: int] =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let kind = data[pos]
  pos += 1
  let argument = nextInt(data, pos)
  return (kind, argument)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreData(inputData, scanPos):
  let taskCount = nextInt(inputData, scanPos)
  let resourceCount = nextInt(inputData, scanPos)
  var startTimes = newSeq[int](taskCount)
  var basePriorities = newSeq[int](taskCount)
  var instructionKinds = newSeq[seq[char]](taskCount)
  var instructionArguments = newSeq[seq[int]](taskCount)
  var priorityCeilings = newSeq[int](resourceCount + 1)
  for taskIndex in 0 .. taskCount - 1:
    startTimes[taskIndex] = nextInt(inputData, scanPos)
    basePriorities[taskIndex] = nextInt(inputData, scanPos)
    let instructionCount = nextInt(inputData, scanPos)
    instructionKinds[taskIndex] = @[]
    instructionArguments[taskIndex] = @[]
    for instructionIndex in 0 .. instructionCount - 1:
      let instruction = nextInstruction(inputData, scanPos)
      if instruction.kind == 'C':
        for repeatIndex in 0 .. instruction.argument - 1:
          instructionKinds[taskIndex].add 'C'
          instructionArguments[taskIndex].add 0
      elif instruction.kind == 'L':
        instructionKinds[taskIndex].add 'L'
        instructionArguments[taskIndex].add instruction.argument
        if basePriorities[taskIndex] > priorityCeilings[instruction.argument]:
          priorityCeilings[instruction.argument] = basePriorities[taskIndex]
      else:
        instructionKinds[taskIndex].add 'U'
        instructionArguments[taskIndex].add instruction.argument
  var resourceOwners = newSeq[int](resourceCount + 1)
  for resourceIndex in 0 .. resourceCount:
    resourceOwners[resourceIndex] = -1
  var ownedResources = newSeq[seq[int]](taskCount)
  for taskIndex in 0 .. taskCount - 1:
    ownedResources[taskIndex] = @[]
  var instructionPositions = newSeq[int](taskCount)
  var completedTasks = newSeq[bool](taskCount)
  var completionTimes = newSeq[int](taskCount)
  var currentPriorities = newSeq[int](taskCount)
  var runningTasks = newSeq[bool](taskCount)
  var blockedTasks = newSeq[bool](taskCount)
  var clockValue = 0
  for taskIndex in 0 .. taskCount - 1:
    if startTimes[taskIndex] < clockValue:
      clockValue = startTimes[taskIndex]
  var remainingTasks = taskCount
  while remainingTasks > 0:
    for taskIndex in 0 .. taskCount - 1:
      runningTasks[taskIndex] = not completedTasks[taskIndex] and
        startTimes[taskIndex] <= clockValue and
        instructionPositions[taskIndex] < instructionKinds[taskIndex].len
      currentPriorities[taskIndex] = basePriorities[taskIndex]
    var changed = true
    var passCount = 0
    while changed and passCount <= taskCount:
      changed = false
      passCount += 1
      for taskIndex in 0 .. taskCount - 1:
        if not runningTasks[taskIndex]:
          continue
        let position = instructionPositions[taskIndex]
        if instructionKinds[taskIndex][position] != 'L':
          continue
        let requestedResource = instructionArguments[taskIndex][position]
        var inheritedPriority = basePriorities[taskIndex]
        if resourceOwners[requestedResource] != -1:
          let blocker = resourceOwners[requestedResource]
          if currentPriorities[blocker] > inheritedPriority:
            inheritedPriority = currentPriorities[blocker]
        for ownedResource in 1 .. resourceCount:
          let blocker = resourceOwners[ownedResource]
          if blocker != -1 and blocker != taskIndex and
             priorityCeilings[ownedResource] >= currentPriorities[taskIndex] and
             currentPriorities[blocker] > inheritedPriority:
            inheritedPriority = currentPriorities[blocker]
        if inheritedPriority > currentPriorities[taskIndex]:
          currentPriorities[taskIndex] = inheritedPriority
          changed = true
    for taskIndex in 0 .. taskCount - 1:
      blockedTasks[taskIndex] = false
      if not runningTasks[taskIndex]:
        continue
      let position = instructionPositions[taskIndex]
      if instructionKinds[taskIndex][position] != 'L':
        continue
      let requestedResource = instructionArguments[taskIndex][position]
      if resourceOwners[requestedResource] != -1:
        blockedTasks[taskIndex] = true
        continue
      for ownedResource in 1 .. resourceCount:
        let blocker = resourceOwners[ownedResource]
        if blocker != -1 and blocker != taskIndex and
           priorityCeilings[ownedResource] >= currentPriorities[taskIndex]:
          blockedTasks[taskIndex] = true
          break
    var selectedTask = -1
    for taskIndex in 0 .. taskCount - 1:
      if runningTasks[taskIndex] and not blockedTasks[taskIndex]:
        if selectedTask == -1 or currentPriorities[taskIndex] > currentPriorities[selectedTask]:
          selectedTask = taskIndex
    if selectedTask == -1:
      clockValue += 1
      continue
    let position = instructionPositions[selectedTask]
    let operation = instructionKinds[selectedTask][position]
    let argument = instructionArguments[selectedTask][position]
    if operation == 'C':
      clockValue += 1
    elif operation == 'L':
      resourceOwners[argument] = selectedTask
      ownedResources[selectedTask].add argument
    else:
      let released = ownedResources[selectedTask][ownedResources[selectedTask].len - 1]
      ownedResources[selectedTask].setLen(ownedResources[selectedTask].len - 1)
      resourceOwners[released] = -1
    instructionPositions[selectedTask] += 1
    if instructionPositions[selectedTask] == instructionKinds[selectedTask].len:
      completedTasks[selectedTask] = true
      completionTimes[selectedTask] = clockValue
      remainingTasks -= 1
  for taskIndex in 0 .. taskCount - 1:
    if taskIndex > 0:
      appendOutput(" ")
    appendOutput($completionTimes[taskIndex])
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

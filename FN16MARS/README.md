# FN16MARS — What Happened on Mars? (SPOJ)

<https://www.spoj.com/problems/FN16MARS/>

## Problem

Several tasks share locked resources on one processor. Higher base priority runs first, but a task waiting for a lock lends its priority to the lock holder. Simulate the Priority Ceiling Protocol and report when each task finishes.

Input holds cases until end of file. Each case starts with the task count and resource count. Each task line gives its start time, base priority, instruction count, and instruction strings such as C100, L2, or U2. Output one line with the finish times in input order.

| item | bound |
|---|---|
| tasks per case | 1 to 20 |
| resources per case | 1 to 20 |
| instruction strings per task | 1 to 100 |
| computes per string | 1 to 100 |
| judge limit | 4000 ms, 1536 MB |

The total compute count drives the run, since each compute advances the clock by one microsecond.

The exact sample input is:

    3 1
    50 2 5 C1 L1 C1 U1 C1
    1 1 5 C1 L1 C100 U1 C1
    70 3 1 C1
    3 3
    5 3 5 C1 L1 C1 U1 C1
    3 2 9 C1 L2 C1 L3 C1 U3 C1 U2 C1
    1 1 9 C1 L3 C3 L2 C1 U2 C1 U3 C1

The exact sample output is:

    106 107 71
    8 15 16

## Idea

Picture a runner waiting for a baton and lending their speed to the runner who holds it. A blocked task raises the current priority of the task that blocks it. Recompute those priorities at each clock step, then run the highest non-blocked task. Lock and unlock actions consume no time, so long compute blocks dominate the loop.

The takeaway is that repeated small priority sweeps reproduce the full protocol.

## Why It Works

1. A resource ceiling is the highest base priority of any task that locks it.
2. A task is blocked only when its next instruction is a lock and a conflicting owner exists.
3. Blocking also occurs when another task holds a resource with ceiling at least the waiter's current priority.
4. A blocking task inherits the waiter's current priority, which can propagate through chains.
5. Current priorities only rise, so a few sweeps reach the unique fixed point.
6. Compute instructions advance the clock; lock and unlock instructions do not.

| term | meaning |
|---|---|
| `priorityCeilings` | highest base priority that may lock each resource |
| `resourceOwners` | task currently holding each resource |
| `currentPriorities` | effective priorities after inheritance |
| `blockedTasks` | tasks that cannot run at this step |
| `completionTimes` | finish time reported for each task |

The table separates fixed data from values that change each step.

A script trace of the first sample case follows:

    clock 1: task 2 computes and locks resource 1
    clock 50: task 1 starts, computes, then waits for resource 1
    task 2 inherits priority 2 and finishes its 100 computes
    clock 70: task 3 runs one compute with priority 3 and finishes at 71
    task 1 finishes at 106, then task 2 finishes at 107

The trace explains the first sample answer line.

## Code

**Input and instruction expansion.** Each C string becomes one compute per microsecond.

```nim
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
```

The scanner reads the operation letter before its number.
One compute string expands into many identical steps.
Buffered writes keep the finish lines cheap.

**Task setup.** Each resource ceiling records the highest locking base priority.

```nim
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
```

Instruction kinds and arguments live in parallel arrays.
Lock instructions update the ceiling of their resource.
Unlock instructions only affect the simulated stack later.

**Priority fixed point.** Inheritance flows from each blocked task to its blockers.

```nim
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
```

Each step restarts priorities from base values.
Repeated sweeps stop once no priority rises.
A task only blocks when its next instruction is a lock.

**Execution step.** The winner either computes, locks, or unlocks.

```nim
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
```

An idle processor still advances the clock.
Unlocks release the most recently held resource.
The last instruction sets that task's finish time.

## Complexity

Each compute instruction advances one clock step.

| phase | time | space |
|---|---|---|
| input read | one pass over all instruction strings | one input string |
| setup | one pass over tasks and resources | per-task instruction arrays |
| simulation | one step per compute, plus lock steps | owner and priority arrays |
| output | one write per full block | block buffer |

The priority sweep is small because task counts never exceed 20.

| measure | Big O |
|---|---|
| time | O(total computes · tasks · resources) |
| space | O(total computes + resources) |

Simulating every possible schedule would take exponential time.
The takeaway is that the protocol fixes the schedule at every step.

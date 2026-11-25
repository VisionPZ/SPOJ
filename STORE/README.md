# STORE — Store-keeper (SPOJ)

<https://www.spoj.com/problems/STORE/>

## Problem

A store-keeper must push a parcel across a floor of fixed crates to a target square. Walking around the parcel costs nothing, but each push counts, and the keeper wants the smallest count.

Input: `t` test cases. Each case starts with `n m`, then `n` lines of `m` letters. `S` is a crate, `M` is the keeper, `P` is the parcel, `K` is the target, and `w` is empty floor.

Output: `NO` when the target is unreachable, or the minimum number of pushes.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Grid size | `n`, `m` at most 100 |
| Markers `M`, `P`, `K` | exactly one of each per case |
| Judge limit | 7000 ms, 1536 MB |

A grid holds up to 10,000 squares, so a state must stay small.

The sample input and output:

```
1
10 12
SSSSSSSSSSSS
SwwwwwwwSSSS
SwSSSSwwSSSS
SwSSSSwwSKSS
SwSSSSwwSwSS
SwwwwwPwwwww
SSSSSSSwSwSw
SSSSSSMwSwww
SSSSSSSSSSSS
SSSSSSSSSSSS
```

```
7
```

## Idea

Forget the keeper's exact square and remember only which side of the parcel they stand on. Think of a moving crew that counts shoves, not footsteps.

The program first labels edge blocks (groups of squares linked without a bridge) with Tarjan's low-link search. Inside one block, the keeper can walk to any standing square for free. A breadth-first search then explores states of parcel square plus standing side.

A naive search tracks both the parcel square and the keeper square. That gives up to `(nm)²` states and cannot fit a 100 by 100 floor. The block search uses only `4nm` states.

Free walking collapses many keeper positions into one state per parcel side.

## Why It Works

Four facts justify the block state.

1. A push needs the keeper on the square opposite the landing square, and both must be open.
2. Two squares in the same edge block stay mutually reachable after removing any single square edge. The keeper can therefore change sides inside that block without a push.
3. Tarjan's search assigns a block to each directed square edge when `lowLink` reaches the parent's discovery time.
4. Breadth-first search over states uses unit cost per push, so the first arrival at the target has the fewest pushes.

The arrays that drive the search:

| Term | Meaning |
| --- | --- |
| `blocked[cell]` | true for a crate or the border ring |
| `discTime`, `lowLink` | Tarjan discovery time and earliest reachable time |
| `edgeBlock[cell * 4 + dir]` | block id of one directed edge |
| `pushDist[state]` | fewest pushes reaching a parcel-side state |
| `stateQueue` | queue of parcel-side states |

The border ring keeps every neighbor index inside the flat arrays.

A script trace of the pushes in the sample case, using one-based row and column:

```
parcel 6,7 keeper 8,7 target 4,10
| push | parcel from | parcel to | pushes so far |
| --- | --- | --- | --- |
| 1 | 6,7 | 6,8 | 1 |
| 2 | 6,8 | 6,9 | 2 |
| 3 | 6,9 | 6,10 | 3 |
| 4 | 6,10 | 6,11 | 4 |
| 5 | 6,11 | 6,10 | 5 |
| 6 | 6,10 | 5,10 | 6 |
| 7 | 5,10 | 4,10 | 7 |
answer = 7
```

The fifth push steps back, then the keeper turns the parcel upward through the gap.

## Code

**Input and field reader.** One buffer holds the stream, and a scanner extracts numbers and grid letters.

```nim
{.push checks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextField(data: string, pos: var int): char =
  while pos < data.len:
    let cellChar = data[pos]
    if cellChar == 'S' or cellChar == 'M' or cellChar == 'P' or cellChar == 'K' or cellChar == 'w':
      pos += 1
      return cellChar
    pos += 1
  return 'S'

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextField` skips whitespace and returns one of the five grid letters.
The scanner handles only positive dimensions.
The output helper flushes at 256 KiB.

**Shared search state.** Arrays are reused across cases to avoid repeated allocation.

```nim
var stride = 0
var delta: array[4, int]
var blocked: seq[bool]
var edgeBlock: seq[int]
var discTime: seq[int]
var lowLink: seq[int]
var parentCell: seq[int]
var edgeStack: seq[int]
var visitStamp: seq[int]
var floodQueue: seq[int]
var pushDist: seq[int]
var stateQueue: seq[int]
var stateHead = 0
var stateTail = 0
var stampCounter = 0
var dfsTime = 0
var blockCount = 0
```

`stride` is `cols + 2`, which leaves a crate ring around the grid.
`delta` holds the four flat-array steps.
All queues and distance arrays are rebuilt per case.

**Edge blocks.** Tarjan's search labels each directed edge with a block id.

```nim
proc tarjanDfs(cell: int) =
  dfsTime += 1
  discTime[cell] = dfsTime
  lowLink[cell] = dfsTime
  for dirIdx in 0..3:
    let neighbor = cell + delta[dirIdx]
    if blocked[neighbor]:
      continue
    if discTime[neighbor] == 0:
      parentCell[neighbor] = cell
      let stackTop = edgeStack.len
      edgeStack.add(cell * 4 + dirIdx)
      tarjanDfs(neighbor)
      if lowLink[neighbor] < lowLink[cell]:
        lowLink[cell] = lowLink[neighbor]
      if lowLink[neighbor] >= discTime[cell]:
        blockCount += 1
        while edgeStack.len > stackTop:
          let edge = edgeStack[edgeStack.len - 1]
          edgeStack.setLen(edgeStack.len - 1)
          let fromCell = edge div 4
          let fromDir = edge mod 4
          let toCell = fromCell + delta[fromDir]
          edgeBlock[fromCell * 4 + fromDir] = blockCount
          edgeBlock[toCell * 4 + (fromDir xor 1)] = blockCount
    elif neighbor != parentCell[cell] and discTime[neighbor] < discTime[cell]:
      edgeStack.add(cell * 4 + dirIdx)
      if discTime[neighbor] < lowLink[cell]:
        lowLink[cell] = discTime[neighbor]
```

A spanning-tree edge enters the stack, and a back edge lowers `lowLink`.
When `lowLink[neighbor] >= discTime[cell]`, the popped edges form one block.
Both directions receive the same id, so free walking works either way.

**Start states.** A flood fill finds which parcel sides the keeper can reach at no cost.

```nim
proc initStart(parcelCell: int, keeperCell: int) =
  blocked[parcelCell] = true
  stampCounter += 1
  let stamp = stampCounter
  var head = 0
  var tail = 0
  floodQueue[tail] = keeperCell
  tail += 1
  visitStamp[keeperCell] = stamp
  while head < tail:
    let cell = floodQueue[head]
    head += 1
    for dirIdx in 0..3:
      let nextCell = cell + delta[dirIdx]
      if not blocked[nextCell] and visitStamp[nextCell] != stamp:
        visitStamp[nextCell] = stamp
        floodQueue[tail] = nextCell
        tail += 1
  blocked[parcelCell] = false
  for dirIdx in 0..3:
    if not blocked[parcelCell + delta[dirIdx]] and visitStamp[parcelCell + delta[dirIdx]] == stamp:
      let state = parcelCell * 4 + dirIdx
      pushDist[state] = 0
      stateQueue[stateTail] = state
      stateTail += 1
```

The parcel is marked blocked during the flood, then unblocked.
`stampCounter` avoids clearing the whole visit array.
Each reachable side seeds a state with distance zero.

**Case driver and push search.** Each push checks a landing square and a standing square in one block.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let rows = nextInt(inputData, scanPos)
  let cols = nextInt(inputData, scanPos)
  stride = cols + 2
  let cellTotal = (rows + 2) * stride
  delta[0] = -stride
  delta[1] = stride
  delta[2] = -1
  delta[3] = 1
  blocked = newSeq[bool](cellTotal)
  for cellIdx in 0..<cellTotal:
    blocked[cellIdx] = true
  var parcelCell = 0
  var keeperCell = 0
  var targetCell = 0
  for rowIdx in 1..rows:
    for colIdx in 1..cols:
      let field = nextField(inputData, scanPos)
      let cell = rowIdx * stride + colIdx
      blocked[cell] = (field == 'S')
      if field == 'P':
        parcelCell = cell
      elif field == 'M':
        keeperCell = cell
      elif field == 'K':
        targetCell = cell
  edgeBlock = newSeq[int](cellTotal * 4)
  for edgeIdx in 0..<edgeBlock.len:
    edgeBlock[edgeIdx] = -1
  discTime = newSeq[int](cellTotal)
  lowLink = newSeq[int](cellTotal)
  parentCell = newSeq[int](cellTotal)
  for cellIdx in 0..<cellTotal:
    parentCell[cellIdx] = -1
  edgeStack = newSeq[int](cellTotal * 4)
  dfsTime = 0
  blockCount = 0
  for cellIdx in 0..<cellTotal:
    if not blocked[cellIdx] and discTime[cellIdx] == 0:
      tarjanDfs(cellIdx)
  visitStamp = newSeq[int](cellTotal)
  floodQueue = newSeq[int](cellTotal)
  pushDist = newSeq[int](cellTotal * 4)
  for stateIdx in 0..<pushDist.len:
    pushDist[stateIdx] = -1
  stateQueue = newSeq[int](cellTotal * 4)
  stateHead = 0
  stateTail = 0
  var answer = -1
  if parcelCell == targetCell:
    answer = 0
  else:
    initStart(parcelCell, keeperCell)
    while stateHead < stateTail and answer == -1:
      let state = stateQueue[stateHead]
      stateHead += 1
      let parcelHere = state div 4
      let prevDir = state mod 4
      let pushCount = pushDist[state]
      for dirIdx in 0..3:
        let landingCell = parcelHere + delta[dirIdx]
        if blocked[landingCell]:
          continue
        let standDir = dirIdx xor 1
        let standCell = parcelHere + delta[standDir]
        if blocked[standCell]:
          continue
        if edgeBlock[parcelHere * 4 + prevDir] != edgeBlock[parcelHere * 4 + standDir]:
          continue
        let nextState = landingCell * 4 + standDir
        if pushDist[nextState] == -1:
          pushDist[nextState] = pushCount + 1
          if landingCell == targetCell:
            answer = pushCount + 1
            break
          stateQueue[stateTail] = nextState
          stateTail += 1
  if answer == -1:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'
```

`cellTotal` includes the border ring, so every `delta` step stays in range.
The block equality test replaces a full walking search.
The queue visits each state once, and the first target hit gives the minimum.

## Complexity

Both the block labeling and the state search are linear in grid squares.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Grid build | O(nm) | O(nm) for `blocked` |
| Tarjan blocks | O(nm) over four edges per square | O(nm) for arrays and stack |
| Start flood fill | O(nm) | O(nm) for the queue |
| Push search | O(nm) states, four transitions each | O(nm) for distances |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(nm) | O(nm) |

At `n = m = 100` the search holds about 40,000 parcel-side states.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(nm) per case |
| Space | O(nm) per case, plus buffers |

Tracking the keeper square as well would raise the state count to O((nm)²) and slow every case sharply.

## Problem

Read a weighted city of plazas where bags explode at noon. Panic starts at each bag and spreads along streets; two crowds that meet head-on die. Choose the plazas where a person alive at noon survives longest, and print their numbers in increasing order.

| Quantity | Bound |
| --- | --- |
| Test cases | 500 |
| Plazas per case | 50000 |
| Streets per case | 250000 |
| Bags per case | 50000 |
| Street travel time | 1000 |
| Time limit | 2267 ms |
| Memory limit | 1536 MB |

The street count drives the design, so each case needs near-linear work.

## Idea

A multi-source Dijkstra pass gives the panic arrival time at every plaza. Crowds leave a plaza along every street except a street that brought panic in. The streets that achieve the shortest arrival are closed to the person. The last event on a path along the open streets gives the survival time. After sorting plazas by arrival time, each outgoing street costs constant work.

Cost per item: one Dijkstra relaxation per directed street, then one decision per open street.

## Why It Works

Panic reaches a plaza at its shortest distance from any bag. A street that achieves that distance is a parent street, and the crowd there never uses it again. A crowd from plaza v toward plaza u meets the opposing crowd exactly when the two travel intervals overlap. When no crowd comes back from u, the traveler dies on arrival at u.

The collision time uses this formula, with forward travel time `w(v,u)` and backward time `w(u,v)`:

- `d[v] * w(u,v)` scales the departure at v by the backward time.
- `d[u] * w(v,u)` scales the departure at u by the forward time.
- `w(v,u) * w(u,v)` is the meeting offset.
- `w(v,u) + w(u,v)` is the combined speed denominator.

A worked example from the sample uses plazas 1 and 2 as bags, so `d[3] = 10` and `d[4] = 15`. The table lists the candidate events on each street.

| Street | Departures | Weights | Collision |
| --- | --- | --- | --- |
| 1-2 | 0 / 0 | 10 / 10 | 100/20 = 5 |
| 2-4 | 0 / 15 | 30 / 30 | 1350/60 = 22.5 |
| 3-1 | 10 / 0 | 5 / 50 | 750/55 = 13.64 |

The latest event is 22.5 on street 2-4. Plazas 2, 3, and 4 all reach it, so they are the answer.

## Code

The input is read in large blocks into one buffer, and the inline hand scanner walks it by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const readChunkBytes = 1 shl 20
const unreachable = 1 shl 60

{.push checks: off.}
{.passC: "-O3".}

proc nextInt(data: string, pos: var int): int {.inline.} =
  var i = pos
  let dataLen = data.len
  while i < dataLen and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < dataLen and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  pos = i
  return value

var inputData = ""
var readChunk = newString(readChunkBytes)
while true:
  let bytesRead = stdin.readBuffer(readChunk[0].addr, readChunk.len)
  if bytesRead == 0:
    break
  let startPos = inputData.len
  inputData.setLen(startPos + bytesRead)
  copyMem(inputData[startPos].addr, readChunk[0].addr, bytesRead)
```

The scanner skips every non-digit, so blank lines between cases need no special handling. A probe pass over the buffered input finds the largest case, so each array is allocated once at the exact size it needs.

```nim
var scanAt = 0
let caseCount = nextInt(inputData, scanAt)
var scanProbe = scanAt
var largestNodeCount = 0
var largestStreetCount = 0
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanProbe)
  let streetCount = nextInt(inputData, scanProbe)
  let bagCount = nextInt(inputData, scanProbe)
  if nodeCount > largestNodeCount:
    largestNodeCount = nodeCount
  if streetCount > largestStreetCount:
    largestStreetCount = streetCount
  for streetIndex in 0..<streetCount:
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
  for bagIndex in 0..<bagCount:
    discard nextInt(inputData, scanProbe)

let maxNodeCount = largestNodeCount + 2
let maxArcCount = 2 * largestStreetCount + 5
let maxStreetCount = largestStreetCount + 2
```

One output buffer flushes in large blocks, which keeps the write path cheap.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each street becomes two directed arcs. A counting pass groups them by source plaza, so Dijkstra and the DP scan contiguous ranges. Every array is allocated once at the maximum size and reused by all cases.

```nim
  arcStart[1] = 0
  for nodeIndex in 1..nodeCount:
    arcStart[nodeIndex + 1] = arcStart[nodeIndex] + arcCount[nodeIndex]
    arcCursor[nodeIndex] = arcStart[nodeIndex]

  for streetIndex in 0..<streetCount:
    let u = tempFrom[streetIndex]
    let v = tempTarget[streetIndex]
    let forwardArc = arcCursor[u]
    arcCursor[u] += 1
    arcTo[forwardArc] = v
    arcWeight[forwardArc] = tempForward[streetIndex]
    let backwardArc = arcCursor[v]
    arcCursor[v] += 1
    arcTo[backwardArc] = u
    arcWeight[backwardArc] = tempBackward[streetIndex]
    arcReverse[forwardArc] = backwardArc
    arcReverse[backwardArc] = forwardArc
```

Dijkstra starts from all bags at once. A stale heap entry is skipped by comparing its key with the current distance.

```nim
  while heapSize > 0:
    let nodeIndex = heapPop()
    if poppedDist != distArr[nodeIndex]:
      continue
    let baseDist = distArr[nodeIndex]
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      let nextDist = baseDist + arcWeight[arcIndex]
      let target = arcTo[arcIndex]
      if nextDist < distArr[target]:
        distArr[target] = nextDist
        heapPush(target, nextDist)
```

An outgoing arc is closed when its neighbor reaches this plaza at the shortest distance. Bag plazas have no closed street. The check runs once per directed arc.

```nim
  for arcIndex in 0..<arcTotal:
    isParentArc[arcIndex] = false
  for nodeIndex in 1..nodeCount:
    if isBagArr[nodeIndex]:
      continue
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if distArr[arcTo[arcIndex]] + arcWeight[arcReverse[arcIndex]] == distArr[nodeIndex]:
        isParentArc[arcIndex] = true
```

An iterative heapsort visits plazas from largest arrival time to smallest. A child always has a larger time, so its answer is ready before the parent needs it. The heap uses no recursion.

```nim
proc sortByDistance(values: var seq[int], count: int) =
  var startIndex = count div 2 - 1
  while startIndex >= 0:
    siftDown(values, startIndex, count - 1)
    startIndex -= 1
  var finish = count - 1
  while finish > 0:
    swap(values[0], values[finish])
    siftDown(values, 0, finish - 1)
    finish -= 1
```

```nim
    ordered[nodeIndex - 1] = nodeIndex
  sortByDistance(ordered, nodeCount)
```

For each open street the code either inherits the child's answer, computes the collision as a fraction, or uses the plain arrival time. Keeping numerator and denominator separate gives exact comparisons with 64-bit products.

```nim
        if arrive == distArr[target]:
          valueNum = survivalNum[target]
          valueDen = survivalDen[target]
        elif distArr[target] < arrive and distArr[nodeIndex] < distArr[target] + arcWeight[arcReverse[arcIndex]]:
          valueNum = int64(distArr[nodeIndex]) * arcWeight[arcReverse[arcIndex]] +
                     int64(distArr[target]) * forwardWeight +
                     int64(forwardWeight) * arcWeight[arcReverse[arcIndex]]
          valueDen = int64(forwardWeight + arcWeight[arcReverse[arcIndex]])
        else:
          valueNum = int64(arrive)
          valueDen = 1
```

Otherwise the code scans all plazas once and prints those tied at the top fraction.

```nim
  var maxNum: int64 = survivalNum[1]
  var maxDen: int64 = survivalDen[1]
  for nodeIndex in 2..nodeCount:
    if survivalNum[nodeIndex] * maxDen > maxNum * survivalDen[nodeIndex]:
      maxNum = survivalNum[nodeIndex]
      maxDen = survivalDen[nodeIndex]
```

## Complexity

Dijkstra takes O(m log n) time and O(n + m) space. Marking closed streets takes O(m) time. Sorting plazas takes O(n log n) time. The DP takes O(m) time and O(n) space for the two fraction arrays. Output takes time proportional to the printed plazas. The total is O(m log n) time and O(n + m) space per case.

A full event simulation follows every crowd and can run without end when crowds circulate. The distance formula settles each street once and avoids that cost.

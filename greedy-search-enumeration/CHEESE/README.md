# CHEESE — Cheese-rolling World Cup (SPOJ)
<https://www.spoj.com/problems/CHEESE/>

## Problem

Each city has a name whose pronunciation power is the sum of lengths of all even-length palindromic substrings. Choose every city whose power reaches the K-th distinct highest power, then report the maximum road flow from the capital to each chosen city.

Input holds several test cases. Each starts with N, M, K, followed by N names and M directed roads with capacity C. A line of three zeros ends the input. Output the chosen count, then one line per chosen city in numeric order as `name (power) flow`.

| item | bound |
|---|---|
| cities N | 1 to 200 |
| roads M | 1 to N(N - 1) |
| threshold K | 1 to 10 |
| name length | up to 30000 |
| road capacity | 1 to 1000000000 |
| judge limit | 3781 ms, 1536 MB |

Comparisons ignore letter case, while printed names keep their original spelling. The capital is city 0, and its flow is 0.

Sample input:

```
3 4 2
Curitiba
LalLal
Idappadi
0 1 2
2 1 1
0 2 3
1 2 6
4 5 3
heeymacarena
haay
abbaxx
ddxdd
0 3 20
0 2 10
2 3 5
3 1 10
2 1 20
0 0 0
```

Sample output:

```
2
LalLal (12) 3
Idappadi (20) 5
4
heeymacarena (2) 0
haay (2) 20
abbaxx (8) 10
ddxdd (4) 25
```

## Idea

Scan a name once for palindromes, then treat each chosen city as a separate water pipe network.

The palindrome scan uses Manacher's even-radius method. At each gap between letters it stores the number of even palindromes centered there, and their lengths sum to `radius * (radius + 1)`. A K-th unique highest power sets the cutoff.

For each chosen city, Dinic's algorithm computes the maximum flow from the capital. Each run starts from the original capacities, so cities are independent.

Checking every substring costs O(L^2) or worse per name and 3^K style selection is not relevant. Manacher costs O(L), and Dinic costs O(V^2 E) on this small graph.

Rebuild the residual network for every chosen city, since at most 2K cities qualify.

## Why It Works

1. An even palindrome has a center between two letters.
2. Manacher records how many even palindromes share each center.
3. A center with radius r contributes lengths 2, 4, ..., 2r.
4. Those lengths sum to `r * (r + 1)`, so a radius pass gives the power.
5. Lowercasing before the scan makes comparisons case insensitive.
6. Dinic sends blocking flows along shortest augmenting paths.

| term | meaning |
|---|---|
| `radii` | even palindrome radius at each center |
| `pronunciationPowers` | one power per city |
| `topPowers` | distinct powers above the cutoff |
| `flowCapacity` | residual capacity of a directed road |

The power is stored in 64 bits because a name of length 30000 can produce trillions of counted characters.

For `abbaxx` the even palindromes are `bb`, `xx`, and `abba`. Their lengths 2, 2, and 4 sum to 8.

| center | radius | contribution |
|---|---|---|
| a|bbaxx | 0 | 0 |
| ab|baxx | 2 | 6 |
| abb|axx | 0 | 0 |
| abba|xx | 0 | 0 |
| abbax|x | 1 | 2 |

The total from the table is 8, which matches the stated power.

In the first sample case, K = 2 and the distinct powers are 20, 12, 8, and 2. The cutoff is 12, so LalLal and Idappadi qualify. LalLal receives 2 directly and 1 through city 2, giving flow 3.

Capacities use `int64`, and each reverse edge stores the unused flow for later cancellation. The reverse edge sits at `edgeIndex xor 1`.

## Code

**Input and helpers.** The reader loads names and roads, and lowercase copies feed the palindrome scan.

```nim
const flushBlockBytes = 1 shl 17
const uppercaseShift = 32

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

proc isLetter(character: char): bool =
  return (character >= 'A' and character <= 'Z') or (character >= 'a' and character <= 'z')

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not isLetter(data[pos]):
    pos += 1
  var word = ""
  while pos < data.len and isLetter(data[pos]):
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc lowercaseCopy(text: string): string =
  var loweredText = ""
  for character in text:
    if character >= 'A' and character <= 'Z':
      loweredText.add char(int(character) + uppercaseShift)
    else:
      loweredText.add character
  return loweredText
```

The word reader accepts both letter cases.
The original name is kept for output.
The lowered copy drives the palindrome scan.

**Palindrome power.** One pass over centers gives every even palindrome radius.

```nim
proc evenPalindromePower(text: string): int64 =
  let textLength = text.len
  var radii = newSeq[int](textLength)
  var leftEdge = 0
  var rightEdge = -1
  for center in 0 .. textLength - 1:
    var radius = 0
    if center <= rightEdge:
      let mirror = leftEdge + rightEdge - center + 1
      let available = rightEdge - center + 1
      radius = radii[mirror]
      if radius > available:
        radius = available
    while center + radius < textLength and center - radius - 1 >= 0 and text[center + radius] == text[center - radius - 1]:
      radius += 1
    radii[center] = radius
    if center + radius - 1 > rightEdge:
      leftEdge = center - radius
      rightEdge = center + radius - 1
  var total: int64 = 0
  for radius in radii:
    total = total + int64(radius) * int64(radius + 1)
  return total

proc containsPower(powerList: seq[int64], value: int64): bool =
  for power in powerList:
    if power == value:
      return true
  return false
```

Mirror radii avoid repeated character checks.
Each center contributes `radius * (radius + 1)`.
The helper keeps the top powers distinct.

**Flow network.** Edges, levels, and blocking flows form Dinic's algorithm.

```nim
var flowHead: seq[int]
var flowTarget: seq[int]
var flowNext: seq[int]
var flowCapacity: seq[int64]
var flowLevel: seq[int]
var flowQueue: seq[int]

proc resetFlowGraph(cityCount: int) =
  flowTarget.setLen 0
  flowNext.setLen 0
  flowCapacity.setLen 0
  flowHead = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    flowHead[cityIndex] = -1

proc addFlowEdge(source: int, target: int, capacity: int64) =
  flowTarget.add target
  flowCapacity.add capacity
  flowNext.add flowHead[source]
  flowHead[source] = flowTarget.len - 1
  flowTarget.add source
  flowCapacity.add 0
  flowNext.add flowHead[target]
  flowHead[target] = flowTarget.len - 1

proc buildFlowLevels(source: int, sink: int): bool =
  for cityIndex in 0 .. flowLevel.len - 1:
    flowLevel[cityIndex] = -1
  var queueHead = 0
  var queueTail = 0
  flowLevel[source] = 0
  flowQueue[queueTail] = source
  queueTail += 1
  while queueHead < queueTail:
    let currentCity = flowQueue[queueHead]
    queueHead += 1
    var edgeIndex = flowHead[currentCity]
    while edgeIndex >= 0:
      let targetCity = flowTarget[edgeIndex]
      if flowCapacity[edgeIndex] > 0 and flowLevel[targetCity] < 0:
        flowLevel[targetCity] = flowLevel[currentCity] + 1
        flowQueue[queueTail] = targetCity
        queueTail += 1
      edgeIndex = flowNext[edgeIndex]
  return flowLevel[sink] >= 0

proc sendFlow(currentCity: int, sink: int, available: int64): int64 =
  if currentCity == sink:
    return available
  var edgeIndex = flowHead[currentCity]
  while edgeIndex >= 0:
    let targetCity = flowTarget[edgeIndex]
    if flowCapacity[edgeIndex] > 0 and flowLevel[targetCity] == flowLevel[currentCity] + 1:
      let pushed = sendFlow(targetCity, sink, min(available, flowCapacity[edgeIndex]))
      if pushed > 0:
        flowCapacity[edgeIndex] = flowCapacity[edgeIndex] - pushed
        flowCapacity[edgeIndex xor 1] = flowCapacity[edgeIndex xor 1] + pushed
        return pushed
    edgeIndex = flowNext[edgeIndex]
  return 0

proc maximumFlow(source: int, sink: int): int64 =
  var totalFlow: int64 = 0
  while buildFlowLevels(source, sink):
    while true:
      let pushed = sendFlow(source, sink, int64.high div 4)
      if pushed == 0:
        break
      totalFlow = totalFlow + pushed
  return totalFlow
```

Each road adds a forward edge and a reverse edge.
Breadth-first search assigns levels to reachable cities.
Depth-first search pushes flow until no path remains.

**Test case loop.** The program selects cities and prints one flow per chosen city.

```nim
while true:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let thresholdCount = nextInt(inputData, scanPos)
  if cityCount == 0 and roadCount == 0 and thresholdCount == 0:
    break
  var cityNames = newSeq[string](cityCount)
  var pronunciationPowers = newSeq[int64](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    cityNames[cityIndex] = nextWord(inputData, scanPos)
    pronunciationPowers[cityIndex] = evenPalindromePower(lowercaseCopy(cityNames[cityIndex]))
  var roadStarts = newSeq[int](roadCount)
  var roadEnds = newSeq[int](roadCount)
  var roadLimits = newSeq[int64](roadCount)
  for roadIndex in 0 .. roadCount - 1:
    roadStarts[roadIndex] = nextInt(inputData, scanPos)
    roadEnds[roadIndex] = nextInt(inputData, scanPos)
    roadLimits[roadIndex] = int64(nextInt(inputData, scanPos))
  var topPowers = newSeq[int64]()
  var smallestPower = pronunciationPowers[0]
  for power in pronunciationPowers:
    if power < smallestPower:
      smallestPower = power
  for rankIndex in 0 .. thresholdCount - 1:
    var candidate: int64 = -1
    for cityIndex in 0 .. cityCount - 1:
      let power = pronunciationPowers[cityIndex]
      if power > candidate and not containsPower(topPowers, power):
        candidate = power
    if candidate < 0:
      break
    topPowers.add candidate
  var cutoff = smallestPower
  if topPowers.len >= thresholdCount:
    cutoff = topPowers[topPowers.len - 1]
  var chosenCount = 0
  for cityIndex in 0 .. cityCount - 1:
    if pronunciationPowers[cityIndex] >= cutoff:
      chosenCount += 1
  appendOutput($chosenCount)
  outputBuffer.add '\n'
  flowLevel = newSeq[int](cityCount)
  flowQueue = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    if pronunciationPowers[cityIndex] >= cutoff:
      appendOutput(cityNames[cityIndex])
      appendOutput(" (")
      appendOutput($pronunciationPowers[cityIndex])
      appendOutput(") ")
      if cityIndex == 0:
        appendOutput("0")
      else:
        resetFlowGraph(cityCount)
        for roadIndex in 0 .. roadCount - 1:
          addFlowEdge(roadStarts[roadIndex], roadEnds[roadIndex], roadLimits[roadIndex])
        appendOutput($maximumFlow(0, cityIndex))
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Distinct top powers are collected by repeated maximum scans.
A short power list makes every city qualify.
Each chosen city gets a fresh flow network.

## Complexity

The palindrome scan is linear in each name, and each flow run is small because N is at most 200.

| phase | time | space |
|---|---|---|
| name scan | O(L) per name | radii array of length L |
| cutoff selection | O(KN) | at most K stored powers |
| flow per chosen city | O(V^2 E) | O(V + E) |
| output | one line per chosen city | block buffer |

At most 2K cities are chosen, so at most 20 flow runs occur.

| measure | Big O |
|---|---|
| time per case | O(NL + K N + 2K × V^2 E) |
| space per case | O(L + E) |

Checking all substring pairs would cost O(L^2) per name and lose the advantage of the linear scan.

The two linear-time phases and a bounded number of flow runs keep every test case fast.

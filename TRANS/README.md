## Problem

Each test case gives a source sequence X, a target sequence Y, and replacement rules. A rule replaces one number by two or three numbers in one step. Print the fewest steps that turn X into Y, or print -1 when no transformation exists.

The judge fixes these bounds.

| Item | Bound |
| --- | --- |
| Test cases | at most 30 |
| Source length N | at most 50 |
| Target length M | at most 50 |
| Rules per case | at most 30 |
| Number values | 1 to 30 |
| Time limit | 1076 ms |
| Memory limit | 1536 MB |

The target length bounds every substring table in the program.

## Idea

The program gives each source number a derivation tree. Its leaves form one contiguous block of the target. A bottom-up table stores the cheapest derivation of every target substring from every number. A pair table shares the work of two-output rules with three-output rules. A second table splits the target into one block per source number.

One target substring costs O(V × M) steps, where V is the rule count and M is the target length.

## Why It Works

Every expansion keeps the order of the numbers it leaves behind. Each original number therefore owns one contiguous, nonempty block of the target. One derivation of a substring uses one rule at its root.

For a two-output rule a -> b c and a substring Y[low..high]:

- The first output takes Y[low..split], and the second takes Y[split + 1..high].
- pairCost(b, c, low, high) minimizes the sum of their costs over every split.
- deriveCost(a, low, high) adds one step to that pair cost.

For a three-output rule a -> b c d:

- The first pair takes Y[low..split], and the last output takes Y[split + 1..high].
- deriveCost(a, low, high) minimizes pairCost(b, c, low, split) + deriveCost(d, split + 1, high) + 1.
- The split runs from low + 1 to high - 1.

The program fills substrings by increasing length. Each shorter part is finished before the current substring starts.

The outer table uses this formula:

- previousMatch[p] holds the cost after earlier source numbers fill Y[0..p-1].
- currentMatch[j] takes the minimum of previousMatch[p] + deriveCost(X[i-1], p, j-1) over every p below j.

The generator prints this cost for the middle number 3 in the sample.

| Source number | Target span | Cost |
| --- | --- | --- |
| 3 | 1..8 | 6 |

The first and last source numbers each match one target number at zero cost. The sample answer is 6.

## Code

The reader collects one input buffer, and the scanner walks it by index.

```
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSymbolValue = 30
const unreachableCost = 1 shl 25

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner stops at the first non-digit, so one call handles any whitespace. The writer flushes every `flushBlockBytes` bytes, so no per-number write reaches the stream. Reading and writing cost time linear in the input size.

This block builds the pair table and fills every substring cost.

```
  let areaSize = targetLength * targetLength
  let slotWidth = valueLimit + 1
  var pairSlot = newSeq[int](slotWidth * slotWidth)
  for slotPos in 0..<pairSlot.len:
    pairSlot[slotPos] = -1

  var pairFirst = newSeq[int](ruleCount)
  var pairSecond = newSeq[int](ruleCount)
  var rulePair = newSeq[int](ruleCount)
  var pairCount = 0
  for rulePos in 0..<ruleCount:
    let slotKey = ruleFirstOut[rulePos] * slotWidth + ruleSecondOut[rulePos]
    if pairSlot[slotKey] == -1:
      pairSlot[slotKey] = pairCount
      pairFirst[pairCount] = ruleFirstOut[rulePos]
      pairSecond[pairCount] = ruleSecondOut[rulePos]
      pairCount += 1
    rulePair[rulePos] = pairSlot[slotKey]

  var deriveCost = newSeq[int](slotWidth * areaSize)
  for costPos in 0..<deriveCost.len:
    deriveCost[costPos] = unreachableCost
  var pairCost = newSeq[int](pairCount * areaSize)
  for costPos in 0..<pairCost.len:
    pairCost[costPos] = unreachableCost

  for spanLength in 1..targetLength:
    for lowPos in 0..(targetLength - spanLength):
      let highPos = lowPos + spanLength - 1
      let spanIndex = lowPos * targetLength + highPos
      if spanLength == 1:
        for symbolValue in 1..valueLimit:
          if targetSeq[lowPos] == symbolValue:
            deriveCost[symbolValue * areaSize + spanIndex] = 0
      else:
        for pairPos in 0..<pairCount:
          let leftBase = pairFirst[pairPos] * areaSize
          let rightBase = pairSecond[pairPos] * areaSize
          let pairBase = pairPos * areaSize
          var bestCost = unreachableCost
          for splitPos in lowPos..<highPos:
            let leftCost = deriveCost[leftBase + lowPos * targetLength + splitPos]
            let rightCost = deriveCost[rightBase + (splitPos + 1) * targetLength + highPos]
            let candidate = leftCost + rightCost
            if candidate < bestCost:
              bestCost = candidate
          pairCost[pairBase + spanIndex] = bestCost

        for rulePos in 0..<ruleCount:
          let symbolBase = ruleLeft[rulePos] * areaSize
          let pairBase = rulePair[rulePos] * areaSize
          var bestCost = deriveCost[symbolBase + spanIndex]
          if ruleThirdOut[rulePos] == 0:
            let candidate = pairCost[pairBase + spanIndex] + 1
            if candidate < bestCost:
              bestCost = candidate
          else:
            let tailBase = ruleThirdOut[rulePos] * areaSize
            for splitPos in (lowPos + 1)..<highPos:
              let headCost = pairCost[pairBase + lowPos * targetLength + splitPos]
              let tailCost = deriveCost[tailBase + (splitPos + 1) * targetLength + highPos]
              let candidate = headCost + tailCost + 1
              if candidate < bestCost:
                bestCost = candidate
          deriveCost[symbolBase + spanIndex] = bestCost
```

The span loop runs once per length from 1 to `targetLength`. Equal symbols cost zero steps at length one. The pair table removes the second split loop from every three-output rule. This block fills O(M²) costs in O(V × M³) steps.

This block matches source numbers against consecutive target blocks.

```
  var previousMatch = newSeq[int](targetLength + 1)
  var currentMatch = newSeq[int](targetLength + 1)
  for matchPos in 0..targetLength:
    previousMatch[matchPos] = unreachableCost
  previousMatch[0] = 0

  for sourcePos in 1..sourceLength:
    for matchPos in 0..targetLength:
      currentMatch[matchPos] = unreachableCost
    let symbolBase = sourceSeq[sourcePos - 1] * areaSize
    for matchedCount in 1..targetLength:
      var bestCost = unreachableCost
      for splitPos in 0..<matchedCount:
        let headCost = previousMatch[splitPos]
        if headCost >= unreachableCost:
          continue
        let tailCost = deriveCost[symbolBase + splitPos * targetLength + matchedCount - 1]
        let candidate = headCost + tailCost
        if candidate < bestCost:
          bestCost = candidate
      currentMatch[matchedCount] = bestCost
    let swapBuffer = previousMatch
    previousMatch = currentMatch
    currentMatch = swapBuffer

  let answer = previousMatch[targetLength]
  if answer >= unreachableCost:
    appendOutput("-1")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per source number. The inner loops try every possible block boundary. Two reused rows replace an N by M table. This block costs O(N × M²) steps and O(M) space.

## Complexity

Reading costs time linear in the input size. The substring tables visit O(M²) spans, and each span scans O(V) rules with O(M) splits. One case therefore costs O(V × M³) time. The matching table adds O(N × M²) time.

The two cost tables hold O((S + P) × M²) integers, where S counts distinct symbols and P counts distinct output pairs. With the stated bounds the tables stay under a few megabytes.

A search over all intermediate sequences grows past a billion states at length 50. The substring tables replace that search.

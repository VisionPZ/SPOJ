## Problem

Read T test cases. Each case gives K key characters, L letter characters, and L letter frequencies. Split the letters into consecutive groups on the keys and minimize total typing price. The price of a letter is its frequency times its position on its key. Break cost ties by maximizing the letters on the last key, then the key before it, and so on. Print a header and K key lines per case, followed by a blank line.

The bounds stay small in both dimensions.

| Quantity | Bound |
| --- | --- |
| Test cases | about 2000 |
| Keys K | 1 to 90 |
| Letters L | K to 90 |
| Frequency | 1 to 100000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The product of K and L never exceeds 8100.

## Idea

One key holds one consecutive block of letters, so the task is a partition problem. Prefix sums give the cost of any block in constant time. A dynamic program fills one state for each count of letters and keys. On a cost tie it keeps the smallest split point, which leaves the most letters on the last key. Walking the saved splits backward gives the required tie order. Enumerating all partitions would take exponential time.

Each state scans at most L split points, so one case costs O(K L^2).

## Why It Works

`prefixFrequency` sums the frequencies up to a letter. `prefixWeighted` sums each frequency times its letter index. The cost of a block leftIndex through rightIndex is the weighted sum minus `(leftIndex - 1)` times the plain sum. The subtraction shifts every letter to its position inside the block.

`minimumCost[keyIndex][letterIndex]` holds the cheapest cost for the first letterIndex letters on keyIndex keys. The program tries every `splitIndex` from keyIndex minus one up to letterIndex minus one. The last key takes the letters after that split. The guard on `infiniteCost` skips prefixes that no key assignment can reach. Adding to an unreachable state would overflow and create a false negative cost.

The scan visits `splitIndex` in increasing order and replaces the answer only on a strictly lower cost. The smallest `splitIndex` therefore survives a tie. That choice maximizes the letters on the last key. Repeating the choice from the back fills the earlier keys in the required order.

Here is the sample case solved by the program.

| Key | Letters | Cost |
| --- | --- | --- |
| 2 | ABCD | 15730 |
| 3 | EFG | 10473 |
| 4 | HIJK | 9087 |
| 5 | LM | 4614 |
| 6 | NOPQ | 13258 |
| 7 | RS | 8892 |
| 8 | TUV | 8590 |
| 9 | WXYZ | 7289 |

The total cost is 77933, and no other layout beats it.

## Code

```
  var lineBuffer = ""
  while readLine(stdin, lineBuffer):
    inputData.add lineBuffer
    inputData.add '\n'
```

The loop reads every line into `inputData`. Adding a newline preserves token boundaries. The loop runs once per input line.

```
proc nextInteger(): int =
  let dataLength = inputData.len
  while scanPosition < dataLength and inputData[scanPosition] != '-' and
      (inputData[scanPosition] < '0' or inputData[scanPosition] > '9'):
    inc scanPosition
  var isNegative = false
  if scanPosition < dataLength and inputData[scanPosition] == '-':
    isNegative = true
    inc scanPosition
  var numberValue = 0
  while scanPosition < dataLength and inputData[scanPosition] >= '0' and
      inputData[scanPosition] <= '9':
    numberValue = numberValue * 10 + (ord(inputData[scanPosition]) - firstDigitValue)
    inc scanPosition
  if isNegative:
    return -numberValue
  return numberValue
```

The scanner advances `scanPosition` only forward. It handles a minus sign before the digits. The inner loop runs once per input character.

```
    prefixFrequency[0] = 0
    prefixWeighted[0] = 0
    for letterIndex in 1..letterCount:
      frequencyValues[letterIndex] = int64(nextInteger())
      prefixFrequency[letterIndex] = prefixFrequency[letterIndex - 1] + frequencyValues[letterIndex]
      prefixWeighted[letterIndex] = prefixWeighted[letterIndex - 1] +
          frequencyValues[letterIndex] * int64(letterIndex)

    for leftIndex in 1..letterCount:
      for rightIndex in leftIndex..letterCount:
        let frequencySum = prefixFrequency[rightIndex] - prefixFrequency[leftIndex - 1]
        let weightedSum = prefixWeighted[rightIndex] - prefixWeighted[leftIndex - 1]
        segmentCost[leftIndex][rightIndex] = weightedSum - int64(leftIndex - 1) * frequencySum
```

The inner loop visits letterCount times for each leftIndex. The offset `(leftIndex - 1)` restarts positions at one on each key. Every block cost takes constant time.

```
    for keyIndex in 1..keyCount:
      for letterIndex in keyIndex..letterCount:
        var chosenCost = infiniteCost
        var chosenSplit = -1
        for splitIndex in (keyIndex - 1)..(letterIndex - 1):
          if minimumCost[keyIndex - 1][splitIndex] >= infiniteCost:
            continue
          let candidateCost = minimumCost[keyIndex - 1][splitIndex] +
              segmentCost[splitIndex + 1][letterIndex]
          if candidateCost < chosenCost:
            chosenCost = candidateCost
            chosenSplit = splitIndex
        minimumCost[keyIndex][letterIndex] = chosenCost
        bestSplitAt[keyIndex][letterIndex] = chosenSplit
```

The scan visits letterIndex minus keyIndex plus one split points. The guard skips states with no reachable prefix. Strict comparison keeps the smallest tie split. This block costs O(K L^2) per case.

```
    var remainingLetters = letterCount
    var keyIndex = keyCount
    while keyIndex >= 1:
      let splitIndex = bestSplitAt[keyIndex][remainingLetters]
      groupStart[keyIndex] = splitIndex + 1
      groupEnd[keyIndex] = remainingLetters
      remainingLetters = splitIndex
      dec keyIndex

    for outputKeyIndex in 1..keyCount:
      appendCharacter(keyCharacters[outputKeyIndex])
      appendText(": ")
      if groupStart[outputKeyIndex] <= groupEnd[outputKeyIndex]:
        for letterIndex in groupStart[outputKeyIndex]..groupEnd[outputKeyIndex]:
          appendCharacter(letterCharacters[letterIndex])
      appendText("\n")
    appendText("\n")
```

The first loop runs keyCount times, once for each key. The empty-group check keeps the trailing space on an unused key. The second loop writes K lines and at most L letters.

```
proc flushOutput() =
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

The program flushes after each `flushBlockBytes` bytes. One write serves many output lines. Clearing the buffer with `setLen` reuses its memory.

## Complexity

Reading and scanning take O(total input tokens). Precomputing block costs takes O(L^2) per case. The DP takes O(K L^2) per case. Reconstruction and printing take O(L + K) per case. Tables use O(K L) space, plus one input buffer and one output buffer. Direct enumeration would examine all groupings of the letter sequence.

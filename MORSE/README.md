## Problem

Read a Morse sequence and a dictionary of words. Count the phrases that use whole dictionary words and reproduce the sequence exactly. Print one count per data set.

| Quantity | Limit |
| --- | --- |
| Data sets | 1 to 20 |
| Morse length | 1 to 10000 symbols |
| Dictionary size | 1 to 10000 words |
| Word length | 1 to 20 letters |
| Answer | at most 2 * 10^9 |
| Time | 7000 ms |
| Memory | 1536 MB |

The limits rule out comparing every word at every position.

## Idea

Store every dictionary word as a path of dots and dashes in a trie, a tree that shares common prefixes. Walk the tree from each sequence position and add the current prefix count whenever a path ends; each jump consumes one whole word. Counting every jump therefore counts every full phrase.

Cost per start position: at most 80 steps, one per Morse pulse of the longest word.

## Why It Works

A Morse conversion maps each letter to one fixed string of dots and dashes. A phrase matches when the Morse strings of its words join into the whole sequence. `ways[position]` holds the number of decodings of the prefix ending at that position. `ways[0]` starts at 1 because the empty prefix has one decoding.

The update `ways[endPos] += waysHere * wordCount` has three terms.

| Term | Meaning |
| --- | --- |
| `waysHere` | Decodings of the prefix before the word. |
| `wordCount` | Dictionary entries whose Morse code equals the consumed slice. |
| `ways[endPos]` | Decodings of the prefix after the word. |

Each match adds one phrase per earlier decoding and per matching entry.

Insertion reaches a child at index `trieWordCount.len - 1` after the three arrays grow. Index zero marks a missing child, since the root already holds index zero. A terminal node stores the number of words with that exact code, so repeated words count as different choices.

The table below uses the sequence `...` with the one-pulse, two-pulse, and three-pulse words.

| start | word | code | end | ways[end] after update |
| --- | --- | --- | --- | --- |
| 0 | E | . | 1 | 1 |
| 0 | I | .. | 2 | 1 |
| 0 | S | ... | 3 | 1 |
| 1 | E | . | 2 | 2 |
| 1 | I | .. | 3 | 2 |
| 2 | E | . | 3 | 4 |

The final counts are 1, 1, 2, 4 and the answer is 4.

## Code

The scanner walks one input buffer by index. It allocates no token strings.

```nim
proc readToken(inputData: string, scanPos: var int, dataLength: int,
               tokenStart: var int, tokenLength: var int) =
  while scanPos < dataLength and inputData[scanPos] <= ' ':
    scanPos += 1
  tokenStart = scanPos
  while scanPos < dataLength and inputData[scanPos] > ' ':
    scanPos += 1
  tokenLength = scanPos - tokenStart

proc parseCount(inputData: string, tokenStart: int, tokenLength: int): int =
  result = 0
  for offset in 0 ..< tokenLength:
    result = result * 10 + (int(inputData[tokenStart + offset]) - firstDigitValue)
```

`parseCount` handles the two counts in the input. Both loops stop at `dataLength`. The cost is one pass over the buffer.

Insertion turns each word into one path through the trie.

```nim
proc addWordToTrie(inputData: string, wordStart: int, wordLength: int,
                   trieDotChild: var seq[int], trieDashChild: var seq[int],
                   trieWordCount: var seq[int]) =
  var nodeIndex = 0
  for letterOffset in 0 ..< wordLength:
    let code = morseCodes[int(inputData[wordStart + letterOffset]) - firstUpperValue]
    for pulseOffset in 0 ..< code.len:
      if code[pulseOffset] == dashCharacter:
        if trieDashChild[nodeIndex] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDashChild[nodeIndex] = trieWordCount.len - 1
        nodeIndex = trieDashChild[nodeIndex]
      else:
        if trieDotChild[nodeIndex] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDotChild[nodeIndex] = trieWordCount.len - 1
        nodeIndex = trieDotChild[nodeIndex]
  trieWordCount[nodeIndex] += 1
```

The letter loop runs at most 20 times and the pulse loop at most 80 times. A new node takes index `trieWordCount.len - 1`; index zero means no child. The build costs one node per distinct Morse prefix.

Counting walks the trie from every reachable position.

```nim
proc countDecodings(inputData: string, morseStart: int, morseLength: int,
                    ways: var seq[int], trieDotChild: seq[int],
                    trieDashChild: seq[int], trieWordCount: seq[int]): int =
  for position in 0 .. morseLength:
    ways[position] = 0
  ways[0] = 1
  for startPos in 0 ..< morseLength:
    let waysHere = ways[startPos]
    if waysHere == 0:
      continue
    var nodeIndex = 0
    var endPos = startPos
    while endPos < morseLength:
      var nextNode: int
      if inputData[morseStart + endPos] == dashCharacter:
        nextNode = trieDashChild[nodeIndex]
      else:
        nextNode = trieDotChild[nodeIndex]
      if nextNode == 0:
        break
      nodeIndex = nextNode
      endPos += 1
      let wordCount = trieWordCount[nodeIndex]
      if wordCount != 0:
        ways[endPos] += waysHere * wordCount
  return ways[morseLength]
```

The outer loop starts at every position below `morseLength`. The inner walk stops at the first missing child or at the sequence end. Positions with zero ways are skipped. This pass costs at most 80 steps per start position.

The driver builds one trie per data set and buffers the printed lines.

```nim
  for dataIndex in 0 ..< dataSetCount:
    readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
    let morseStart = tokenStart
    let morseLength = tokenLength
    readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
    let wordCount = parseCount(inputData, tokenStart, tokenLength)
    var trieDotChild: seq[int] = @[0]
    var trieDashChild: seq[int] = @[0]
    var trieWordCount: seq[int] = @[0]
    for wordIndex in 0 ..< wordCount:
      readToken(inputData, scanPos, dataLength, tokenStart, tokenLength)
      addWordToTrie(inputData, tokenStart, tokenLength, trieDotChild,
                    trieDashChild, trieWordCount)
    if ways.len <= morseLength:
      ways.setLen(morseLength + 1)
    let answer = countDecodings(inputData, morseStart, morseLength, ways,
                                trieDotChild, trieDashChild, trieWordCount)
    outputBuffer.add $answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
```

The loop runs `dataSetCount` times, at most 20. Each trie starts as a single root node, so data sets do not share state. A block flush keeps the output buffer small.

## Complexity

Let N be the sequence length, W the word count, and L the longest code length, at most 80.

| Phase | Time | Space |
| --- | --- | --- |
| Read input | O(input bytes) | O(input bytes) |
| Build trie | O(W * L) | O(W * L) nodes |
| Count phrases | O(N * L) | O(N) |
| Total per data set | O(W * L + N * L) | O(W * L + N) |

At full limits, one data set uses at most 800000 trie nodes and 800000 walk steps. All 20 data sets use about 32 million steps.

A naive scan compares every word at every position and costs O(N * W * L) time. At full limits that is 8 billion comparisons per data set.

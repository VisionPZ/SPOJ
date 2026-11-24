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

A Morse conversion maps each letter to one fixed string of dots and dashes. A phrase matches when the Morse strings of its words join into the whole sequence. `ways[j]` holds the number of decodings of the prefix ending at that position. `ways[0]` starts at 1 because the empty prefix has one decoding.

The update `ways[k] += waysHere * wordCount` has three terms.

| Term | Meaning |
| --- | --- |
| `waysHere` | Decodings of the prefix before the word. |
| `wordCount` | Dictionary entries whose Morse code equals the consumed slice. |
| `ways[k]` | Decodings of the prefix after the word. |

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
proc readToken(inputData: string, i: var int, dataLength: int,
               j: var int, tokenLength: var int) =
  while i < dataLength and inputData[i] <= ' ':
    i += 1
  j = i
  while i < dataLength and inputData[i] > ' ':
    i += 1
  tokenLength = i - j

proc parseCount(inputData: string, i: int, tokenLength: int): int =
  result = 0
  for j in 0 ..< tokenLength:
    result = result * 10 + (int(inputData[i + j]) - firstDigitValue)
```

`parseCount` handles the two counts in the input. Both loops stop at `dataLength`. The cost is one pass over the buffer.

Insertion turns each word into one path through the trie.

```nim
proc addWordToTrie(inputData: string, i: int, wordLength: int,
                   trieDotChild: var seq[int], trieDashChild: var seq[int],
                   trieWordCount: var seq[int]) =
  var j = 0
  for k in 0 ..< wordLength:
    let code = morseCodes[int(inputData[i + k]) - firstUpperValue]
    for l in 0 ..< code.len:
      if code[l] == dashCharacter:
        if trieDashChild[j] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDashChild[j] = trieWordCount.len - 1
        j = trieDashChild[j]
      else:
        if trieDotChild[j] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDotChild[j] = trieWordCount.len - 1
        j = trieDotChild[j]
  trieWordCount[j] += 1
```

The letter loop runs at most 20 times and the pulse loop at most 80 times. A new node takes index `trieWordCount.len - 1`; index zero means no child. The build costs one node per distinct Morse prefix.

Counting walks the trie from every reachable position.

```nim
proc countDecodings(inputData: string, i: int, morseLength: int,
                    ways: var seq[int], trieDotChild: seq[int],
                    trieDashChild: seq[int], trieWordCount: seq[int]): int =
  for j in 0 .. morseLength:
    ways[j] = 0
  ways[0] = 1
  for j in 0 ..< morseLength:
    let waysHere = ways[j]
    if waysHere == 0:
      continue
    var l = 0
    var k = j
    while k < morseLength:
      var nextNode: int
      if inputData[i + k] == dashCharacter:
        nextNode = trieDashChild[l]
      else:
        nextNode = trieDotChild[l]
      if nextNode == 0:
        break
      l = nextNode
      k += 1
      let wordCount = trieWordCount[l]
      if wordCount != 0:
        ways[k] += waysHere * wordCount
  return ways[morseLength]
```

The outer loop starts at every position below `morseLength`. The inner walk stops at the first missing child or at the sequence end. Positions with zero ways are skipped. This pass costs at most 80 steps per start position.

The driver builds one trie per data set and buffers the printed lines.

```nim
  for k in 0 ..< dataSetCount:
    readToken(inputData, i, dataLength, j, tokenLength)
    let l = j
    let morseLength = tokenLength
    readToken(inputData, i, dataLength, j, tokenLength)
    let wordCount = parseCount(inputData, j, tokenLength)
    var trieDotChild: seq[int] = @[0]
    var trieDashChild: seq[int] = @[0]
    var trieWordCount: seq[int] = @[0]
    for k in 0 ..< wordCount:
      readToken(inputData, i, dataLength, j, tokenLength)
      addWordToTrie(inputData, j, tokenLength, trieDotChild,
                    trieDashChild, trieWordCount)
    if ways.len <= morseLength:
      ways.setLen(morseLength + 1)
    let answer = countDecodings(inputData, l, morseLength, ways,
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

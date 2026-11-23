# PIGBANK - Piggy-Bank

## Problem

For each test case you get the empty and filled pig weights (`1 <= E <= F <= 10000`
grams), then `N <= 500` coin types with a price `P` and a weight `W`. Coins may be
used any number of times. Find the cheapest way to reach the weight difference
exactly; print `The minimum amount of money in the piggy-bank is X.` or
`This is impossible.`.

## Idea

Unbounded knapsack: `best[t]` is the cheapest price that weighs exactly `t` grams.
Fill it coin by coin, and for one coin walk `t` upward from its own weight, so the
value just written for a smaller weight is already usable. That upward walk is what
makes an unlimited number of copies of the coin possible. Cost per coin is one
pass over the target weight, so O(N F) work per test case.

## Why It Works

Processing `t` from the coin weight upward means `best[t - weight]` may already
contain this same coin, so copies are free. Every combination of coins is generated
in at least one pass: after all coins are processed, `best[t]` holds the cheapest
total among all multisets of coins weighing `t`. An unreachable weight keeps the
sentinel `impossiblePrice = 1 shl 29`, which is larger than any real answer
(10 000 grams of the cheapest coin costs at most 50 000 x 10 000 = 5 x 10^8).
For the sample, target 100 with coins (price 1, weight 1) and (price 30, weight 50)
gives 60, since two 50 gram coins beat one hundred 1 gram coins.

## Code

```nim
var tokens: seq[string]
var tokenIndex = 0
var coinWeight: seq[int]
var coinPrice: seq[int]
var bestPrice: seq[int]
const impossiblePrice = 1 shl 29

proc readLineText(): string =
  var current = ""
  discard stdin.readLine(current)
  return current

proc appendTokensFromLine(): int =
  var line = readLineText()
  while line.len == 0:
    line = readLineText()
  var index = 0
  while index < line.len:
    while index < line.len and (line[index] == ' ' or line[index] == '\r' or line[index] == '\t'):
      index += 1
    let start = index
    while index < line.len and line[index] != ' ' and line[index] != '\r' and line[index] != '\t':
      index += 1
    if index > start:
      tokens.add(line[start ..< index])
  return tokens.len

proc nextToken(): string =
  while true:
    if tokenIndex < tokens.len:
      let answer = tokens[tokenIndex]
      tokenIndex += 1
      return answer
    setLen(tokens, 0)
    tokenIndex = 0
    discard appendTokensFromLine()

proc nextNumber(): int =
  var text = nextToken()
  var value = 0
  var position = 0
  while position < text.len:
    if text[position] in {'0' .. '9'}:
      value = value * 10 + (text[position].ord - '0'.ord)
    position += 1
  return value

proc appendNumber(buffer: var string, value: int) =
  var digits: seq[byte]
  if value == 0:
    digits.add(cast[uint8]('0'.ord))
  else:
    var rest = value
    while rest > 0:
      digits.add(cast[uint8]('0'.ord + (rest mod 10)))
      rest = rest div 10
  var index = digits.len - 1
  while index >= 0:
    buffer.add(cast[char](digits[index]))
    index -= 1

var output: string

proc emit(text: string) =
  output.add(text)
  if output.len >= 1 shl 19:
    stdout.write(output)
    setLen(output, 0)

let caseCount = nextNumber()
for _ in 0 ..< caseCount:
  let emptyWeight = nextNumber()
  let filledWeight = nextNumber()
  let coinCount = nextNumber()
  setLen(coinWeight, coinCount)
  setLen(coinPrice, coinCount)
  for index in 0 ..< coinCount:
    coinPrice[index] = nextNumber()
    coinWeight[index] = nextNumber()
  let target = filledWeight - emptyWeight
  setLen(bestPrice, target + 1)
  bestPrice[0] = 0
  for weight in 1 .. target:
    bestPrice[weight] = impossiblePrice
  for coin in 0 ..< coinCount:
    let weight = coinWeight[coin]
    let price = coinPrice[coin]
    if weight > 0 and weight <= target:
      for current in weight .. target:
        let candidate = bestPrice[current - weight] + price
        if candidate < bestPrice[current]:
          bestPrice[current] = candidate
  if bestPrice[target] >= impossiblePrice:
    emit("This is impossible.\n")
  else:
    var line = "The minimum amount of money in the piggy-bank is "
    appendNumber(line, bestPrice[target])
    line.add(".\n")
    emit(line)
stdout.write(output)
```

## Complexity

Time per test case is O(N (F - E)) plus the token parsing, at most 500 x 10 000 =
5 x 10^6 steps; space is O(F - E), at most 10 001 integers. The naive form, trying
every multiset of coins, is exponential.

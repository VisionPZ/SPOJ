# PIGBANK — Piggy-Bank (SPOJ)

<https://www.spoj.com/problems/PIGBANK/>

## Problem

Coins of known weights and prices fill a piggy bank of known empty and full
weights. Find the minimum cash that the coins inside must be worth.

Each test case gives empty and filled pig weights (`1 <= E <= F <= 10000` grams).
It then lists `N <= 500` coin types, each with price `P` and weight `W`. Coins may be
used any number of times. Find the cheapest way to reach the weight difference
exactly; print `The minimum amount of money in the piggy-bank is X.` or
`This is impossible.`.

## Idea

Unbounded knapsack: `best[t]` is the cheapest price that weighs exactly `t` grams.
Fill it coin by coin, and for one coin walk `t` upward from its own weight, so the
value written for a smaller weight is already usable. That upward walk is what
makes an unlimited number of copies of the coin possible. Cost per coin is one
pass over the target weight, so O(N F) work per test case.

## Why It Works

Processing `t` from the coin weight upward means `best[t - weight]` may already
contain this same coin, so copies are free. Every combination of coins is generated
in at least one pass: after all coins are processed, `best[t]` holds the cheapest
total among all multisets of coins weighing `t`. Unreachable weights keep the sentinel `impossiblePrice = 1 shl 29`.
That bound exceeds any valid cost, since 10 000 coins of price 50 000 total 5 x 10^8.
For the sample, target 100 with coins (price 1, weight 1) and (price 30, weight 50)
gives 60, since two 50 gram coins beat one hundred 1 gram coins.

## Code

```nim
var tokens: seq[string]
var i = 0
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
  var i = 0
  while i < line.len:
    while i < line.len and (line[i] == ' ' or line[i] == '\r' or line[i] == '\t'):
      i += 1
    let start = i
    while i < line.len and line[i] != ' ' and line[i] != '\r' and line[i] != '\t':
      i += 1
    if i > start:
      tokens.add(line[start ..< i])
  return tokens.len

proc nextToken(): string =
  while true:
    if i < tokens.len:
      let answer = tokens[i]
      i += 1
      return answer
    setLen(tokens, 0)
    i = 0
    discard appendTokensFromLine()

proc nextNumber(): int =
  var text = nextToken()
  var value = 0
  var i = 0
  while i < text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
    i += 1
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
  var i = digits.len - 1
  while i >= 0:
    buffer.add(cast[char](digits[i]))
    i -= 1

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
  for j in 0 ..< coinCount:
    coinPrice[j] = nextNumber()
    coinWeight[j] = nextNumber()
  let target = filledWeight - emptyWeight
  setLen(bestPrice, target + 1)
  bestPrice[0] = 0
  for weight in 1 .. target:
    bestPrice[weight] = impossiblePrice
  for j in 0 ..< coinCount:
    let weight = coinWeight[j]
    let price = coinPrice[j]
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

Each test case takes O(N (F - E)) time plus parsing, at most 5 x 10^6 steps.
Space is O(F - E), storing at most 10 001 integers. The naive form, trying
every multiset of coins, is exponential.

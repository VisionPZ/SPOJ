const flushBlockBytes = 1 shl 17
const maxPrimeValue = 100005
const baseValue = 1000000000
const limbDigits = 9
const digitOffset = 48
const missingIndex = -1

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
    value = value * 10 + int(data[pos]) - digitOffset
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var sievePrimes = newSeq[int]()
block:
  var compositeFlags = newSeq[bool](maxPrimeValue + 1)
  for value in 2 .. maxPrimeValue:
    if not compositeFlags[value]:
      sievePrimes.add value
      if int64(value) * int64(value) <= int64(maxPrimeValue):
        for multiple in countup(value * value, maxPrimeValue, value):
          compositeFlags[multiple] = true

proc nextNumber(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[startPos .. pos - 1]

proc parseLimbs(text: string): seq[int64] =
  var limbs = newSeq[int64]()
  var position = text.len - 1
  while position >= 0:
    var limbValue: int64 = 0
    var multiplier: int64 = 1
    for digitIndex in 0 .. limbDigits - 1:
      if position < 0:
        break
      limbValue = limbValue + int64(int(text[position]) - digitOffset) * multiplier
      multiplier = multiplier * 10
      position -= 1
    limbs.add limbValue
  return limbs

proc isUnit(limbs: seq[int64]): bool =
  return limbs.len == 1 and limbs[0] == 1

proc remainderPrime(limbs: seq[int64], primeValue: int): int =
  var remainder: int64 = 0
  for limbIndex in countdown(limbs.len - 1, 0):
    remainder = (remainder * int64(baseValue) + limbs[limbIndex]) mod int64(primeValue)
  return int(remainder)

proc dividePrime(limbs: var seq[int64], primeValue: int) =
  var carry: int64 = 0
  for limbIndex in countdown(limbs.len - 1, 0):
    let currentValue = carry * int64(baseValue) + limbs[limbIndex]
    limbs[limbIndex] = currentValue div int64(primeValue)
    carry = currentValue mod int64(primeValue)
  while limbs.len > 1 and limbs[limbs.len - 1] == 0:
    limbs.setLen(limbs.len - 1)

proc factorNumber(text: string): seq[(int, int)] =
  var factors = newSeq[(int, int)]()
  var limbs = parseLimbs(text)
  if limbs.len == 0:
    return factors
  for primeValue in sievePrimes:
    if isUnit(limbs):
      break
    var exponent = 0
    while remainderPrime(limbs, primeValue) == 0:
      exponent += 1
      dividePrime(limbs, primeValue)
    if exponent > 0:
      factors.add((primeValue, exponent))
  if not isUnit(limbs):
    if limbs.len > 2:
      factors.add((missingIndex, 1))
    else:
      var leftover: int64 = 0
      for limbIndex in countdown(limbs.len - 1, 0):
        leftover = leftover * int64(baseValue) + limbs[limbIndex]
      if leftover > int64(maxPrimeValue):
        factors.add((missingIndex, 1))
  return factors

proc appendProduct(primeValues: seq[int], exponents: seq[int]) =
  var limbs = newSeq[int64]()
  limbs.add 1
  for primeIndex in 0 .. primeValues.len - 1:
    if exponents[primeIndex] > 0:
      for repetition in 0 .. exponents[primeIndex] - 1:
        var carry: int64 = 0
        for limbIndex in 0 .. limbs.len - 1:
          let productValue = limbs[limbIndex] * int64(primeValues[primeIndex]) + carry
          limbs[limbIndex] = productValue mod int64(baseValue)
          carry = productValue div int64(baseValue)
        while carry > 0:
          limbs.add carry mod int64(baseValue)
          carry = carry div int64(baseValue)
  var resultText = $(limbs[limbs.len - 1])
  var limbIndex = limbs.len - 2
  while limbIndex >= 0:
    var partText = $(limbs[limbIndex])
    while partText.len < limbDigits:
      partText = "0" & partText
    resultText.add partText
    limbIndex -= 1
  appendOutput("YES ")
  appendOutput(resultText)
  outputBuffer.add '\n'

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pairCount = nextInt(inputData, scanPos)
  var domainIndexOf = newSeq[int](maxPrimeValue + 1)
  var codomainIndexOf = newSeq[int](maxPrimeValue + 1)
  for primeValue in 0 .. maxPrimeValue:
    domainIndexOf[primeValue] = missingIndex
    codomainIndexOf[primeValue] = missingIndex
  var domainValues = newSeq[int]()
  var codomainValues = newSeq[int]()
  var domainFactors = newSeq[seq[(int, int)]]()
  var codomainFactors = newSeq[seq[(int, int)]]()
  for pairIndex in 0 .. pairCount - 1:
    let valueText = nextNumber(inputData, scanPos)
    let imageText = nextNumber(inputData, scanPos)
    var domainEntry = newSeq[(int, int)]()
    for factorEntry in factorNumber(valueText):
      let primeValue = factorEntry[0]
      let exponent = factorEntry[1]
      if domainIndexOf[primeValue] == missingIndex:
        domainIndexOf[primeValue] = domainValues.len
        domainValues.add primeValue
      domainEntry.add((domainIndexOf[primeValue], exponent))
    domainFactors.add domainEntry
    var codomainEntry = newSeq[(int, int)]()
    for factorEntry in factorNumber(imageText):
      let primeValue = factorEntry[0]
      let exponent = factorEntry[1]
      if codomainIndexOf[primeValue] == missingIndex:
        codomainIndexOf[primeValue] = codomainValues.len
        codomainValues.add primeValue
      codomainEntry.add((codomainIndexOf[primeValue], exponent))
    codomainFactors.add codomainEntry
  let domainCount = domainValues.len
  let codomainCount = codomainValues.len
  var expMatrix = newSeq[int](pairCount * domainCount)
  var imageMatrix = newSeq[int](pairCount * codomainCount)
  for pairIndex in 0 .. pairCount - 1:
    for factorEntry in domainFactors[pairIndex]:
      expMatrix[pairIndex * domainCount + factorEntry[0]] = factorEntry[1]
    for factorEntry in codomainFactors[pairIndex]:
      imageMatrix[pairIndex * codomainCount + factorEntry[0]] = factorEntry[1]
  var candidateLists = newSeq[seq[(int, int)]](codomainCount)
  var consistent = true
  for primeIndex in 0 .. codomainCount - 1:
    var anchorPair = missingIndex
    for pairIndex in 0 .. pairCount - 1:
      if imageMatrix[pairIndex * codomainCount + primeIndex] > 0:
        anchorPair = pairIndex
        break
    if anchorPair == missingIndex:
      continue
    let targetExponent = imageMatrix[anchorPair * codomainCount + primeIndex]
    var candidateList = newSeq[(int, int)]()
    for domainIndex in 0 .. domainCount - 1:
      let anchorFactor = expMatrix[anchorPair * domainCount + domainIndex]
      if anchorFactor == 0 or targetExponent mod anchorFactor != 0:
        continue
      let factorValue = targetExponent div anchorFactor
      var works = true
      for pairIndex in 0 .. pairCount - 1:
        if imageMatrix[pairIndex * codomainCount + primeIndex] !=
           factorValue * expMatrix[pairIndex * domainCount + domainIndex]:
          works = false
          break
      if works:
        candidateList.add((domainIndex, factorValue))
    if candidateList.len == 0:
      consistent = false
    candidateLists[primeIndex] = candidateList
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let queryText = nextNumber(inputData, scanPos)
    if not consistent:
      appendOutput("NO\n")
      continue
    var weights = newSeq[int](domainCount)
    var productExponents = newSeq[int](codomainCount)
    var ambiguous = false
    for factorEntry in factorNumber(queryText):
      let primeValue = factorEntry[0]
      let exponent = factorEntry[1]
      if primeValue < 0 or primeValue > maxPrimeValue:
        ambiguous = true
        break
      if domainIndexOf[primeValue] == missingIndex:
        ambiguous = true
        break
      weights[domainIndexOf[primeValue]] = exponent
    if not ambiguous:
      for primeIndex in 0 .. codomainCount - 1:
        if candidateLists[primeIndex].len == 0:
          productExponents[primeIndex] = 0
        else:
          var expectedExponent = missingIndex
          for candidateEntry in candidateLists[primeIndex]:
            let candidateExponent = weights[candidateEntry[0]] * candidateEntry[1]
            if expectedExponent == missingIndex:
              expectedExponent = candidateExponent
            elif candidateExponent != expectedExponent:
              ambiguous = true
              break
          if ambiguous:
            break
          productExponents[primeIndex] = expectedExponent
    if ambiguous:
      appendOutput("NO\n")
    else:
      appendProduct(codomainValues, productExponents)

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const scaleFactor = 1000000
const maxTotalCents = 2000
const productLimit = 2000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatCents(amount: int64): string =
  let wholePart = amount div 100
  let fractionPart = amount mod 100
  if fractionPart < 10:
    return $(wholePart) & ".0" & $(fractionPart)
  return $(wholePart) & "." & $(fractionPart)

for firstCents in 1 .. maxTotalCents:
  if int64(firstCents) * firstCents * firstCents * firstCents > productLimit:
    break
  for secondCents in firstCents .. maxTotalCents:
    if int64(firstCents) * secondCents * secondCents * secondCents > productLimit:
      break
    for thirdCents in secondCents .. maxTotalCents:
      if int64(firstCents) * secondCents * thirdCents * thirdCents > productLimit:
        break
      let divisor = int64(firstCents) * secondCents * thirdCents - scaleFactor
      if divisor <= 0:
        continue
      let numerator = scaleFactor * (firstCents + secondCents + thirdCents)
      if numerator mod divisor != 0:
        continue
      let fourthCents = numerator div divisor
      if fourthCents < thirdCents:
        continue
      let totalCents = firstCents + secondCents + thirdCents + fourthCents
      if totalCents > maxTotalCents:
        continue
      if int64(firstCents) * secondCents * thirdCents * fourthCents != scaleFactor * totalCents:
        continue
      appendOutput(formatCents(firstCents))
      outputBuffer.add ' '
      appendOutput(formatCents(secondCents))
      outputBuffer.add ' '
      appendOutput(formatCents(thirdCents))
      outputBuffer.add ' '
      appendOutput(formatCents(fourthCents))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

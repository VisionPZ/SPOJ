import sys

divisorValue = 11

inputData = sys.stdin.buffer.read()
caseBlocks = []
for rawLine in inputData.split(b"\n"):
    numberText = rawLine.strip()
    if not numberText:
        continue
    if numberText == b"0":
        break
    remainingValue = int(numberText)
    originalText = str(remainingValue)
    stepLines = [originalText]
    while len(str(remainingValue)) > 2:
        truncatedValue, lastDigit = divmod(remainingValue, 10)
        remainingValue = truncatedValue - lastDigit
        stepLines.append(str(remainingValue))
    if remainingValue % divisorValue == 0:
        verdictText = "El numero " + originalText + " es divisible por 11."
    else:
        verdictText = "El numero " + originalText + " no es divisible por 11."
    caseBlocks.append("\n".join(stepLines) + "\n" + verdictText + "\n")

outputBuffer = "\n".join(caseBlocks)
if caseBlocks:
    outputBuffer += "\n"
sys.stdout.write(outputBuffer)

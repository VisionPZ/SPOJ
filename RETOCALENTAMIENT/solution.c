#include <stdio.h>
#include <stdlib.h>

#define FIRST_DIGIT 48
#define FLUSH_BYTES 131072
#define CYCLE_LENGTH 30

static char moonCycle[CYCLE_LENGTH];
static char moonRecord[1 << 20];
static char inputData[1 << 26];
static char outputBuffer[FLUSH_BYTES];
static int outputLength = 0;

static void appendText(const char *text) {
  int index = 0;
  while (text[index] != '\0') {
    if (outputLength == FLUSH_BYTES) {
      fwrite(outputBuffer, 1, outputLength, stdout);
      outputLength = 0;
    }
    outputBuffer[outputLength++] = text[index++];
  }
}

static int nextInteger(const char *data, int length, int *position) {
  while (*position < length && (data[*position] < '0' || data[*position] > '9')) {
    (*position)++;
  }
  if (*position >= length) {
    return -1;
  }
  int value = 0;
  while (*position < length && data[*position] >= '0' && data[*position] <= '9') {
    value = value * 10 + (data[*position] - FIRST_DIGIT);
    (*position)++;
  }
  return value;
}

int main(void) {
  int dayIndex;
  for (dayIndex = 0; dayIndex < 16; dayIndex++) {
    moonCycle[dayIndex] = (char)dayIndex;
  }
  for (dayIndex = 0; dayIndex < 14; dayIndex++) {
    moonCycle[16 + dayIndex] = (char)(14 - dayIndex);
  }

  int inputLength = 0;
  size_t bytesRead;
  while (inputLength < (int)sizeof(inputData)) {
    bytesRead = fread(inputData + inputLength, 1, sizeof(inputData) - (size_t)inputLength, stdin);
    if (bytesRead == 0) {
      break;
    }
    inputLength += (int)bytesRead;
  }

  int scanPosition = 0;
  while (scanPosition < inputLength) {
    int dayCount = nextInteger(inputData, inputLength, &scanPosition);
    if (dayCount < 0) {
      break;
    }
    int recordIndex;
    for (recordIndex = 0; recordIndex < dayCount; recordIndex++) {
      moonRecord[recordIndex] = (char)nextInteger(inputData, inputLength, &scanPosition);
    }
    int decidedDirection = 0;
    int mixedDirections = 0;
    int phase;
    for (phase = 0; phase < CYCLE_LENGTH; phase++) {
      int matches = 1;
      for (recordIndex = 0; recordIndex < dayCount; recordIndex++) {
        if ((int)moonCycle[(phase + recordIndex) % CYCLE_LENGTH] != (int)moonRecord[recordIndex]) {
          matches = 0;
          break;
        }
      }
      if (!matches) {
        continue;
      }
      int lastSize = (int)moonCycle[(phase + dayCount - 1) % CYCLE_LENGTH];
      int nextSize = (int)moonCycle[(phase + dayCount) % CYCLE_LENGTH];
      int direction = nextSize > lastSize ? 1 : -1;
      if (decidedDirection == 0) {
        decidedDirection = direction;
      } else if (decidedDirection != direction) {
        mixedDirections = 1;
        break;
      }
    }
    if (mixedDirections || decidedDirection == 0) {
      appendText("-1\n");
    } else if (decidedDirection > 0) {
      appendText("CRECIENTE\n");
    } else {
      appendText("MENGUANTE\n");
    }
  }

  if (outputLength > 0) {
    fwrite(outputBuffer, 1, outputLength, stdout);
  }
  return 0;
}

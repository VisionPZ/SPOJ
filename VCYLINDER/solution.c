#include <stdio.h>

#define FLUSH_BLOCK_BYTES (1 << 17)

static char inputData[FLUSH_BLOCK_BYTES];
static char outputBuffer[FLUSH_BLOCK_BYTES];
static int outputLength = 0;

static void flushOutput(void) {
  if (outputLength > 0) {
    fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
    outputLength = 0;
  }
}

static void appendOutput(const char *text) {
  while (*text != '\0') {
    if (outputLength >= FLUSH_BLOCK_BYTES) {
      flushOutput();
    }
    outputBuffer[outputLength++] = *text++;
  }
}

static int readInt(const char *data, int length, int *position) {
  int value = 0;
  while (*position < length && (data[*position] < '0' || data[*position] > '9')) {
    (*position)++;
  }
  while (*position < length && data[*position] >= '0' && data[*position] <= '9') {
    value = value * 10 + (data[*position] - '0');
    (*position)++;
  }
  return value;
}

int main(void) {
  int inputLength = (int)fread(inputData, 1, sizeof(inputData), stdin);
  int position = 0;
  int diameter = readInt(inputData, inputLength, &position);
  int height = readInt(inputData, inputLength, &position);
  double radius = (double)diameter / 2.0;
  double volume = 3.14 * radius * radius * height;
  char formattedLine[64];
  sprintf(formattedLine, "%.2f cm^3\n", volume);
  appendOutput(formattedLine);
  flushOutput();
  return 0;
}

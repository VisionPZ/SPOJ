import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

class Main {
    public static void main(String[] args) throws Exception {
        InputStream in = System.in;
        ByteArrayOutputStream raw = new ByteArrayOutputStream();
        byte[] chunk = new byte[1 << 16];
        int got;
        while ((got = in.read(chunk)) > 0) {
            raw.write(chunk, 0, got);
        }
        byte[] data = raw.toByteArray();
        int pos = 0;
        while (pos < data.length && (data[pos] == '\n' || data[pos] == '\r' || data[pos] == ' ')) {
            pos++;
        }
        int end = pos;
        while (end < data.length && data[end] != '\n' && data[end] != '\r') {
            end++;
        }
        OutputStream out = System.out;
        out.write("Ol\u00e1 ".getBytes(StandardCharsets.UTF_8));
        out.write(data, pos, end - pos);
        out.write(", este \u00e9 seu primeiro programa!\n".getBytes(StandardCharsets.UTF_8));
        out.flush();
    }
}

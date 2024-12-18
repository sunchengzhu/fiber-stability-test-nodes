import org.nervos.ckb.Network;
import org.nervos.ckb.crypto.secp256k1.ECKeyPair;
import org.nervos.ckb.type.Script;
import org.nervos.ckb.utils.address.Address;

import java.io.*;
import java.util.Formatter;

public class GetArgs {
    public static Address getAddress(String privateKey) {
        ECKeyPair keyPair = ECKeyPair.create(privateKey);
        Script script = Script.generateSecp256K1Blake160SignhashAllScript(keyPair);
        Address address = new Address(script, Network.TESTNET);
        return address;
    }

    public static String bytesToHex(byte[] bytes) {
        Formatter formatter = new Formatter();
        for (byte b : bytes) {
            formatter.format("%02x", b);
        }
        String result = "0x" + formatter.toString();
        formatter.close();
        return result;
    }

    public static void main(String[] args) throws IOException {
        String filePath = "keys.txt";
        String outputFilePath = "args.txt";

        // 删除args.txt文件，如果存在
        File outputFile = new File(outputFilePath);
        if (outputFile.exists()) {
            outputFile.delete();
        }

        int index = 1;
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath));
             BufferedWriter writer = new BufferedWriter(new FileWriter(outputFilePath))) {
            String privateKey;
            while ((privateKey = reader.readLine()) != null) {
                if (!privateKey.trim().isEmpty()) {
                    Address address = getAddress(privateKey);
                    Script script = address.getScript();
                    String scriptArgs = bytesToHex(script.args);
                    // 写入到args.txt中
                    writer.write(scriptArgs);
                    writer.newLine(); // 换行
                    System.out.printf("Address %d: %s, args: %s%n", index, address.encode(), scriptArgs);
                    index++;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

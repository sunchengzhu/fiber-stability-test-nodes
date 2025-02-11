import org.nervos.ckb.CkbRpcApi;
import org.nervos.ckb.service.Api;
import org.nervos.ckb.utils.address.Address;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class GetBalance {

    public static void main(String[] args) throws IOException {
        CkbRpcApi ckbApi = new Api("https://testnet.ckb.dev/");
        String filePath = "keys.txt";

        int index = 1;
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String privateKey;
            while ((privateKey = reader.readLine()) != null) {
                if (!privateKey.trim().isEmpty()) {
                    Address address = Distribute.getAddress(privateKey);
                    long balance = Distribute.getBalance(address, ckbApi);
                    double formattedBalance = balance / 100000000.0; // 将余额除以 10^8
                    System.out.printf("Address %d: %s, Balance: %.8f CKB%n", index, address.encode(), formattedBalance);
                    index++;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

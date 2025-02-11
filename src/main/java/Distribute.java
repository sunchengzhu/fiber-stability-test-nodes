import org.nervos.ckb.CkbRpcApi;
import org.nervos.ckb.Network;
import org.nervos.ckb.crypto.secp256k1.ECKeyPair;
import org.nervos.ckb.service.Api;
import org.nervos.ckb.sign.TransactionSigner;
import org.nervos.ckb.sign.TransactionWithScriptGroups;
import org.nervos.ckb.transaction.CkbTransactionBuilder;
import org.nervos.ckb.transaction.InputIterator;
import org.nervos.ckb.transaction.TransactionBuilderConfiguration;
import org.nervos.ckb.type.Script;
import org.nervos.ckb.type.ScriptType;
import org.nervos.ckb.type.TransactionInput;
import org.nervos.ckb.utils.Numeric;
import org.nervos.ckb.utils.address.Address;
import org.nervos.indexer.model.SearchKeyBuilder;
import org.nervos.indexer.model.resp.CellCapacityResponse;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;


public class Distribute {

    public static Address getAddress(String privateKey) {
        ECKeyPair keyPair = ECKeyPair.create(privateKey);
        Script script = Script.generateSecp256K1Blake160SignhashAllScript(keyPair);
        Address address = new Address(script, Network.TESTNET);
        return address;
    }

    public static long getBalance(Address address, CkbRpcApi ckbApi) throws IOException {
        Script script = address.getScript();
        SearchKeyBuilder key = new SearchKeyBuilder();
        key.script(script);
        key.scriptType(ScriptType.LOCK);
        CellCapacityResponse capacity = ckbApi.getCellsCapacity(key.build());
        return capacity.capacity;
    }

    // 静态内部类
    static class Receiver {
        String address;
        long capacity;

        Receiver(String address, long capacity) {
            this.address = address;
            this.capacity = capacity;
        }
    }


    public static void main(String[] args) throws IOException {
        CkbRpcApi ckbApi = new Api("https://testnet.ckb.dev/");
        String filePath = "keys.txt";
        int baseAmount = 2000;

        int index = 1;
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String privateKey;
            while ((privateKey = reader.readLine()) != null) {
                if (!privateKey.trim().isEmpty()) {
                    Address address = getAddress(privateKey);
                    long balance = getBalance(address, ckbApi);
                    double formattedBalance = balance / 100000000.0; // 将余额除以 10^8
                    System.out.printf("Address %d: %s, Balance: %.8f CKB%n", index, address.encode(), formattedBalance);
                    index++;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println();

        int j = 1;
        List<Receiver> receivers = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String privateKey;
            while ((privateKey = reader.readLine()) != null) {
                if (!privateKey.trim().isEmpty()) { // 跳过空行
                    Address address = getAddress(privateKey);
                    long balance = getBalance(address, ckbApi);
                    if (balance < baseAmount * 100000000L) {
                        long capacity = baseAmount * 100000000L + (j * 100000000L);
                        receivers.add(new Receiver(address.encode(), capacity));
                        j++;
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        for (int i = 0; i < receivers.size(); i++) {
            Receiver receiver = receivers.get(i);
            System.out.println("Receiver " + (i + 1) + ": " + receiver.address + ", Capacity: " + receiver.capacity);
        }
        System.out.println();

        if (receivers.size() > 0) {
            TransactionWithScriptGroups txWithGroups = getTransactionWithScriptGroups(receivers);
            // 0. Set your private key
            String privateKey = "0xdbe003fd089247af5f7eaca57acd21fcf5890a9eecde4aab05478babac7a7be4";
            // 1. Sign transaction with your private key
            TransactionSigner.getInstance(Network.TESTNET).signTransaction(txWithGroups, privateKey);
            // 2. Send transaction to CKB node
            byte[] txHash = ckbApi.sendTransaction(txWithGroups.txView);
            System.out.println(Numeric.toHexString(txHash));
        } else {
            System.out.println("无需转账");
        }
    }

    private static TransactionWithScriptGroups getTransactionWithScriptGroups(List<Receiver> receivers) {
        String sender = "ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsq0yhqpawh0cw985ryf2xrzsqr5cu45qp6qy8xavl";
        Iterator<TransactionInput> iterator = new InputIterator(sender);
        TransactionBuilderConfiguration configuration = new TransactionBuilderConfiguration(Network.TESTNET);
        configuration.setFeeRate(1000);
        CkbTransactionBuilder builder = new CkbTransactionBuilder(configuration, iterator);
        for (Receiver receiver : receivers) {
            builder.addOutput(receiver.address, receiver.capacity);
        }
        builder.setChangeOutput(sender);
        TransactionWithScriptGroups txWithGroups = builder.build();
        return txWithGroups;
    }
}
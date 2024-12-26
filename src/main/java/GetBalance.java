import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.RoundingMode;
import java.text.DecimalFormat;

import okhttp3.*;
import org.json.JSONArray;
import org.json.JSONObject;

public class GetBalance {
    private final OkHttpClient client = new OkHttpClient();

    public static void main(String[] args) {
        GetBalance getBalance = new GetBalance();
        String fNodeIp = "43.198.254.225";
        int fNodePort = 8236;
        try {
            String peerId = getBalance.getPeerId(fNodeIp, fNodePort);
            if (peerId != null) {
                String aNodeIp = "18.167.71.41";
                int aNodePort = 8231;
                System.out.println("A → F");
                getBalance.listChannels(peerId, aNodeIp, aNodePort);
                String bNodeIp = "18.167.71.41";
                int bNodePort = 8232;
                System.out.println("B → F");
                getBalance.listChannels(peerId, bNodeIp, bNodePort);
                String gNodeIp = "43.199.108.57";
                int gNodePort = 8237;
                System.out.println("G → F");
                getBalance.listChannels(peerId, gNodeIp, gNodePort);
                String gPeerId = getBalance.getPeerId(gNodeIp, gNodePort);
                System.out.println("H → G");
                int hNodePort = 8238;
                getBalance.listChannels(gPeerId, gNodeIp, hNodePort);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public String getPeerId(String ip, int port) throws IOException {
        String url = "http://" + ip + ":" + port;
        MediaType JSON = MediaType.get("application/json; charset=utf-8");

        JSONObject jsonRequest = new JSONObject();
        jsonRequest.put("id", 1);
        jsonRequest.put("jsonrpc", "2.0");
        jsonRequest.put("method", "node_info");
        jsonRequest.put("params", new JSONObject[]{}); // Empty JSON array

        RequestBody body = RequestBody.create(jsonRequest.toString(), JSON);
        Request request = new Request.Builder()
                .url(url)
                .post(body)
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);
            String responseData = response.body().string();
            return new JSONObject(responseData).getJSONObject("result").getString("peer_id").replace("0.0.0.0", ip);
        }
    }

    private void listChannels(String peerId, String ip, int port) throws IOException {
        String url = "http://" + ip + ":" + port;
        MediaType JSON = MediaType.get("application/json; charset=utf-8");

        JSONObject jsonRequest = new JSONObject();
        jsonRequest.put("id", 1);
        jsonRequest.put("jsonrpc", "2.0");
        jsonRequest.put("method", "list_channels");
        JSONObject param = new JSONObject();
        param.put("peer_id", peerId);
        jsonRequest.put("params", new JSONObject[]{param});

        RequestBody body = RequestBody.create(jsonRequest.toString(), JSON);
        Request request = new Request.Builder()
                .url(url)
                .post(body)
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

            String responseBody = response.body().string();
            JSONObject jsonResponse = new JSONObject(responseBody);
            JSONArray channels = jsonResponse.getJSONObject("result").getJSONArray("channels");

            if (channels.length() > 0) {
                DecimalFormat df = new DecimalFormat("0.00000000"); // Ensure 8 decimal places
                for (int i = 0; i < channels.length(); i++) {
                    JSONObject channel = channels.getJSONObject(i);
                    String localBalanceHex = channel.getString("local_balance");
                    String remoteBalanceHex = channel.getString("remote_balance");

                    // Convert hex to decimal and scale down
                    BigDecimal localBalance = new BigDecimal(new BigInteger(localBalanceHex.substring(2), 16));
                    BigDecimal remoteBalance = new BigDecimal(new BigInteger(remoteBalanceHex.substring(2), 16));

                    // Scale down by 10^8 and format to 3 decimal places
                    BigDecimal scale = new BigDecimal("100000000");
                    localBalance = localBalance.divide(scale, 8, RoundingMode.HALF_UP);
                    remoteBalance = remoteBalance.divide(scale, 8, RoundingMode.HALF_UP);

                    // Format the output to ensure no scientific notation
                    System.out.println("Channel " + (i + 1) + ": Local Balance: " + df.format(localBalance) + ", Remote Balance: " + df.format(remoteBalance));
                }
            } else {
                System.out.println("No channels found.");
            }
            System.out.println();
        }
    }
}
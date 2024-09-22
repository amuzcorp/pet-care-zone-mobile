import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:petcarezone/constants/api_urls.dart';

import '../utils/logger.dart';

class LunaService {

  Future runSSHCommand({
    required String sshHost,
    required String command,
  }) async {
    final client = SSHClient(
      await SSHSocket.connect(sshHost, 22),
      username: 'root',
    );

    try {
      final result = await client.run(command);
      final decodedResult = utf8.decode(result);
      logD.i('$command\n-${utf8.decode(result)}');
      return jsonDecode(decodedResult);
    } catch (e) {
      logD.e('Error: $e');
      return e;
    } finally {
      client.close();
    }
  }

  Future checkWifiStatus(String sshHost) async {
    const String command = ApiUrls.lunaWifiStatusUrl;
    try {
      return await runSSHCommand(sshHost: sshHost, command: command);
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future scanWifi(String sshHost) async {
    const String command = ApiUrls.lunaWifiScan;
    try {
      final commandResult = await runSSHCommand(sshHost: sshHost, command: command);
      return commandResult['foundNetworks'];
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future connectWifi(String sshHost, String wifi, String passKey) async {
    final String command = ApiUrls.getLunaWifiConnectUrl(wifi, passKey);
    try {
       return await runSSHCommand(sshHost: sshHost, command: command);
     } catch (e) {
       throw Exception('Failed Response $e');
     }
  }

  Future startProvision(String sshHost) async {
    const String command = ApiUrls.lunaProvisionUrl;
    try {
      return await runSSHCommand(sshHost: sshHost, command: command);
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }

  Future setPetInfo(String sshHost, String userId, String petId) async {
    final String command = ApiUrls.setPetInfo(userId, petId);
    try {
      return await runSSHCommand(sshHost: sshHost, command: command);
    } catch (e) {
      throw Exception('Failed Response $e');
    }
  }
}

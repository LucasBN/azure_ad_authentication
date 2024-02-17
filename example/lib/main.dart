import 'dart:io';

import 'package:azure_ad_authentication/azure_ad_authentication.dart';
import 'package:azure_ad_authentication/exeption.dart';
import 'package:azure_ad_authentication/model/config.dart';
import 'package:azure_ad_authentication/model/user_ad.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _clientId = "24f6b811-7372-4560-851f-e13a0e2e9a10";

  String _output = 'NONE';
  static const List<String> kScopes = [
    "https://graph.microsoft.com/User.ReadBasic.All",
  ];

  Future<void> _acquireToken() async {
    await getResult();
  }

  Future<void> _acquireTokenSilently() async {
    await getResult(isAcquireToken: false);
  }

  Future<String> getResult({bool isAcquireToken = true}) async {
    AzureAdAuthentication pca = await intPca();
    String? res;
    UserAdModel? userAdModel;
    try {
      if (isAcquireToken) {
        userAdModel =
            await pca.acquireToken(scopes: kScopes, fetchUserModel: true);
      } else {
        userAdModel = await pca.acquireTokenSilent(scopes: kScopes);
      }
    } on MsalUserCancelledException {
      res = "User cancelled";
    } on MsalNoAccountException {
      res = "no account";
    } on MsalInvalidConfigurationException {
      res = "invalid config";
    } on MsalInvalidScopeException {
      res = "Invalid scope";
    } on MsalException {
      res = "Error getting token. Unspecified reason";
    }

    setState(() {
      _output = (userAdModel?.toJson().toString() ?? res)!;
    });

    print("Here");

    return (userAdModel?.toJson().toString() ?? res)!;
  }

  String _getRedirectUri() {
    switch (Platform.operatingSystem) {
      case "android":
        return "msauth://com.fsconceicao.azure_ad_authentication_example/U5rbvBLdFUbEazWhQfDgt6oRa24%3D";
      case "ios":
        return "msauth.com.fsconceicao.azureAdAuthenticationExample://auth";
    }
    throw UnimplementedError();
  }

  String? _getTenantId() {
    switch (Platform.operatingSystem) {
      case "android":
        return "e0e89c40-ac3f-4817-8d6d-05714d65705c";
      case "ios":
        return null;
    }
    throw UnimplementedError();
  }

  String? _getAuthorityUrl() {
    switch (Platform.operatingSystem) {
      case "android":
        return null;
      case "ios":
        return "https://login.microsoftonline.com/e0e89c40-ac3f-4817-8d6d-05714d65705c/saml2";
    }
    throw UnimplementedError();
  }

  Future<AzureAdAuthentication> intPca() async {
    return await AzureAdAuthentication.createPublicClientApplication(
      config: MsalConfig(
        clientId: _clientId,
        redirectUri: _getRedirectUri(),
        brokerRedirectUriRegistered: true,
        authorities: [
          MsalAuthority(
            AuthorityType.AAD,
            MsalAudience(
              AudienceType.AzureADMyOrg,
              tenantId: _getTenantId(),
            ),
            authorityUrl: _getAuthorityUrl(),
          ),
        ],
      ),
    );
  }

  Future _logout() async {
    AzureAdAuthentication pca = await intPca();
    String res;
    try {
      await pca.logout();
      res = "Account removed";
    } on MsalException {
      res = "Error signing out";
    } on PlatformException catch (e) {
      res = "some other exception ${e.toString()}";
    }

    setState(() {
      _output = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Plugin example app"),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _acquireToken,
                    child: const Text("AcquireToken()"),
                  ),
                ),
                ElevatedButton(
                    onPressed: _acquireTokenSilently,
                    child: const Text("AcquireTokenSilently()")),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: _logout, child: const Text("Logout")),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _output
                        .replaceAll(",", ",\n")
                        .replaceAll("{", "{\n")
                        .replaceAll("}", "\n}"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

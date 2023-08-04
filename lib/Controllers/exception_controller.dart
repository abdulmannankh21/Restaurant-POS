import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../Components/app_overlay.dart';
import '../Components/custom_circular_button.dart';
import '../Services/storage_services.dart';
import '/Components/AppDialogBox.dart';

import '/Config/app_config.dart';

class ExceptionController extends GetxController {
  static void errorOccurAlert() {
    showAppOverlayPre(
      overlayTxtTitle: "An Error occurred",
      overlayTxtMsg: "Please try again later!",
    );
  }

  Future exceptionAlert(
      {String? errorMsg, String? resBody, String? exceptionFormat}) async {
    String alertDesc = '';
    if (resBody != null) {
      try {
        alertDesc = json.decode('$resBody')['message'] +
            (json.decode('$resBody')['errors'] != null
                ? '\n${json.decode('$resBody')['errors']}'
                : null);
      } catch (e) {
        try {
          alertDesc = json.decode('$resBody')['message'] ??
              json.decode('$resBody')['errors'].toString();
        } catch (_e) {
          try {
            alertDesc = json.decode('$resBody').toString();
          } catch (_err) {
            alertDesc = resBody.toString();
          }
        }
      }
    } else if (errorMsg != null) {
      alertDesc = errorMsg;
    }

    // // if (isNeedResponse) {
    // //   AppAlert.warning(desc: alertDesc);
    // // } else {

    // showAppOverlayPre(overlayTxtTitle: 'Error', overlayTxtMsg: alertDesc);
    // // }
    // else
    debugPrint('${Get.currentRoute}');
    await appDialogBox(
      Get.context!,
      dialogTitle: 'Sorry for inconvenience!',
      contentPage: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$alertDesc'),
                SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 15,
            child: CustomButton(
              onTap: () {
                if (Get.currentRoute != '/LoginPage')
                  submitException(
                    errMsg: alertDesc,
                    compError: exceptionFormat ?? resBody,
                  );
                Get.back();
              },
              btnTxtAxisSize: MainAxisSize.min,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              btnTxt: (Get.currentRoute == '/LoginPage')
                  ? 'ok'.tr
                  : 'submit_report'.tr,
              // isOutLinedButton: true,
              // enableToolTip: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Send Email on address with exception details
  Future submitException({String? errMsg, compError}) async {
    // Configure the SMTP server settings
    String email = 'app@bizmodo.ae';
    final smtpServer = SmtpServer(
      'mail.bizmodo.ae',
      username: email,
      password: '%MUg1vhv*,2p',
      port: 465,
      ssl: true,
    );

    // Create the email message
    final message = Message()
      ..from = Address(
        '${AppStorage.getLoggedUserData()?.staffUser.email ?? email}',
        '${AppStorage.getLoggedUserData()?.staffUser.username}',
      )
      ..recipients.add(email)
      ..subject = 'Error Report:'
          '${AppConfig.appName}'
          ' - ${AppStorage.getBusinessDetailsData()?.businessData?.name}'
          ' - $errMsg'
      ..text = '$compError';

    try {
      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent! Message ID: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
    }
  }
}

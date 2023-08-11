import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../Config/DateTimeFormat.dart';
import '../../Config/utils.dart';
import '../../Models/PaymentMethodModel/paymentAccountModel.dart';
import '../../Services/api_services.dart';
import '../../Services/api_urls.dart';
import '../../Services/storage_services.dart';
import '../exception_controller.dart';

class FundsController extends GetxController {
  TextEditingController amountCtrl = TextEditingController();
  TextEditingController dateCtrl = TextEditingController();
  TextEditingController noteCtrl = TextEditingController();
  TextEditingController fromStatusCtrl = TextEditingController();
  String? fromStatus;
  String? fromStatusValue;
  String? toStatus;
  String? toStatusValue;
  File? image;

  PaymentAccountModel? paymentAccountModel;

  /// Fetching Payment Accounts
  Future fetchPaymentAccountList({String? pageUrl}) async {
    await ApiServices.getMethod(feedUrl: pageUrl ?? ApiUrls.paymentAccountApi)
        .then((_res) {
      update();
      if (_res == null) return null;
      paymentAccountModel = paymentAccountModelFromJson(_res);
      update();
    }).onError((error, stackTrace) async {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      await ExceptionController().exceptionAlert(
        errorMsg: '$error',
        exceptionFormat: ApiServices.methodExceptionFormat(
            'POST', ApiUrls.paymentAccountApi, error, stackTrace),
      );
      update();
    });
  }

  List<String> paymentAccountList() {
    List<String> paymentAccountsList = [];
    var length = paymentAccountModel?.data?.length ?? 0;
    for (int i = 0; i < length; i++) {
      if ('${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.paymentAccount?.first.account?.name}' !=
          '${paymentAccountModel?.data?[i].name}')
        paymentAccountsList.add('${paymentAccountModel?.data?[i].name}' ?? '');
    }
    return paymentAccountsList;
  }

  checkingFundsFromLocation() {
    var length = paymentAccountModel?.data?.length ?? 0;
    for (int i = 0; i < length; i++) {
      if ('${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.locationId}' ==
          '${paymentAccountModel?.data?[i].name}') {
        fromStatusCtrl.text = '${paymentAccountModel?.data?[i].name}';
        print('Matching id ${paymentAccountModel?.data?[i].name}');
      }
    }
  }

  clearAllFields() {
    fromStatus = null;
    toStatus = null;
    fromStatusValue = null;
    toStatusValue = null;
    amountCtrl.clear();
    dateCtrl.text = '${AppFormat.dateYYYYMMDDHHMM24(DateTime.now())}';
    image = null;
    noteCtrl.clear();
  }

  createFundsTransfer() async {
    // API Method with url

    String _url = '${ApiUrls.fundsTransferAPI}';
    Map<String, String> _fields = {};
    Map<String, String> _fieldForFile = {};

    _fields['from_account'] =
        '${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.paymentAccount?.first.account?.id}';

    _fields['to_account'] = '${toStatusValue}';
    _fields['amount'] = '${amountCtrl.text}';
    _fields['operation_date'] = '${dateCtrl.text}';
    _fields['note'] = '${noteCtrl.text}';
    _fieldForFile['document'] = '${image?.path}';

    logger.i(_fields);
    logger.i(_fieldForFile);
    return await ApiServices.postMultiPartQuery(
            feedUrl: _url, fields: _fields, files: _fieldForFile)
        .then((response) async {
      // logger.i('EndPoint => ${_url}'
      //     '\nStatus Code => {response.statusCode}'
      //     '\nResponse => $response');

      clearAllFields();
      stopProgress();
      showToast('Funds Transferred Successfully');
      Get.close(1);
    }).onError((error, stackTrace) {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      return null;
    });
  }
}

import 'package:bizmodo_emenu/Models/AllKitchenModel/AllKitchenModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../Config/utils.dart';
import '../../Models/ProductsModel/ProductModel.dart';
import '../../Services/api_services.dart';
import '../../Services/api_urls.dart';
import '../exception_controller.dart';

class AllKitchenController extends GetxController {
  AllKitchenModel? allKitchenModel;

  /// Fetching Stock Adjustment
  Future fetchShowProductList({String? pageUrl}) async {
    await ApiServices.getMethod(feedUrl: pageUrl ?? ApiUrls.allKitchenApi)
        .then((_res) {
      update();
      if (_res == null) return null;
      allKitchenModel = allKitchenModelFromJson(_res);
      update();
    }).onError((error, stackTrace) async {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      await ExceptionController().exceptionAlert(
        errorMsg: '$error',
        exceptionFormat: ApiServices.methodExceptionFormat(
            'POST', ApiUrls.unitListApi, error, stackTrace),
      );
      update();
    });
  }

  List<String> printersList(
    AllKitchenController allKitchenCtrlObj,
  ) {
    //int? index, List<ProductModel>? productModelObjs
    // List<String> options = [
    //   'Kitchen 1',
    //   'Kitchen 2',
    //   'Kitchen 12',
    // ];
    List<String> options = [];
    for (int i = 0;
        i < allKitchenCtrlObj.allKitchenModel!.kitchens!.length;
        i++) {
      options.add('${allKitchenCtrlObj.allKitchenModel?.kitchens?[i].name}');
    }
    // print(productModelObjs[index].)
    return options;
  }
}

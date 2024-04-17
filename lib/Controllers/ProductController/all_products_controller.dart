import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '/Config/app_format.dart';
import '/Config/utils.dart';
import '/Controllers/ProductController/product_cart_controller.dart';
import '/Models/ProductsModel/ListProductsModel.dart';
import '/Models/ProductsModel/ProductShowListModel.dart';
import '/Models/ProductsModel/all_products_model.dart';
import '/Models/ProductsModel/product.dart';
import '/Models/ReceiptModel.dart';
import '/Models/UnitModels/UnitListModel.dart';
import '/Models/order_type_model/SaleOrderModel.dart';
import '/Pages/Orders/Controller/OrderController.dart';
import '/Pages/PrintDesign/invoice_print_screen.dart';
import '/Pages/PrintDesign/pdfGenerate.dart';
import '/Pages/PrintDesign/receiptPdfGenerate.dart';
import '/Pages/Tabs/View/TabsPage.dart';
import '/Services/api_services.dart';
import '/Services/api_urls.dart';
import '/Services/storage_services.dart';
import '/const/dimensions.dart';
import '../AllSalesController/allSalesController.dart';
import '../ContactController/ContactController.dart';
import '../Tax Controller/TaxController.dart';
import '../exception_controller.dart';
import 'PaymentController.dart';

class AllProductsController extends GetxController {
  RxBool isFetchingProduct = false.obs;
  CategoriesProductsModel? allCategoriesProductsData;
  PaymentController paymentCtrlObj = Get.find<PaymentController>();
  List<TextEditingController> productQuantityCtrl = [];
  final TaxController taxCtrlObj = Get.find<TaxController>();
  final ContactController contactCtrlObj = Get.find<ContactController>();
  final OrderController orderCtrlObj = Get.find<OrderController>();
  ProductCartController productCtrlCtrlObj = Get.find<ProductCartController>();
  TextEditingController payTermCtrl = TextEditingController();
  TextEditingController dateCtrl = TextEditingController();

  //String? totalAmount;
  List<double> productsAmount = [];
  double finalTotal = 0.00;
  double paidAmount = 0.00;
  String total = '0.00';
  String? paytermStatusValue;
  String? statusValue;
  String? invoiceSchemaStatusValue;
  bool isUpdate = false;
  String updateOrderId = '';
  bool isPDFView = false;
  bool isDirectCheckout = false;

  //loading more variables:
  int allSaleOrdersPage = 1;
  bool isFirstLoadRunning = true;
  bool hasNextPage = true;
  RxBool isLoadMoreRunning = false.obs;

  ListProductsModel? listProductsModel;

  void qtyOrderCalculation() {
    var inlineTax =
        AppStorage.getBusinessDetailsData()?.businessData?.enableInlineTax;
  }

  Future fetchAllProducts({String? pageUrl}) async {
    await ApiServices.getMethod(
      feedUrl: pageUrl ??
          '${ApiUrls.allProducts}?'
              'location_id=${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.id ?? AppStorage.getLoggedUserData()?.staffUser.locationId}',
    ).then((_res) {
      update();
      if (_res == null) return null;
      listProductsModel = listProductsModelFromJson(_res);
      print(listProductsModel?.data);
      showingAllItems();
      update();
    }).onError((error, stackTrace) async {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      await ExceptionController().exceptionAlert(
        errorMsg: '$error',
        exceptionFormat: ApiServices.methodExceptionFormat(
            'POST', ApiUrls.allProducts, error, stackTrace),
      );
      update();
    });
  }

  List<Product> productModelObjs = [];
  List<Product> searchedProducts = [];
  List<Product> selectedProducts = [];
  List<String> selectedQuantityList = [];
  List<String> selectedUnitsList = [];
  List<String> selectedUnitsNames = [];

  // List<String> selected
  List<String> unitListStatusIds = [];

  showingAllItems() {
    productModelObjs.clear();
    var categoriesLength = listProductsModel?.data?.length ?? 0;
    for (int i = 0; i < categoriesLength; i++) {
      for (int j = 0; j < listProductsModel!.data![i].products!.length; j++) {
        productModelObjs.add(listProductsModel!.data![i].products![j]);
        productQuantityCtrl.add(TextEditingController());
        unitListStatusIds
            .add(listProductsModel!.data![i].products![j].unitId.toString());
        productsAmount.add(0.00);
      }
    }

    searchedProducts = productModelObjs;

    for (int i = 0; i < productModelObjs.length; i++) {
      // checkUnits(product: productModelObjs[i]);
      unitListStatus.add(checkUnits(product: productModelObjs[i]));
    }

    for (int i = 0; i < productModelObjs.length; i++) {
      nestedist.add(addingSpecifiedUnitsInList(product: productModelObjs[i]));
      // print(addingSpecifiedUnitsInList(product: productModelObjs[i]));
    }

    return null;
  }

  checkProductStockLocationBased({
    int? locationId,
    required int index,
  }) {
    return searchedProducts[index]
        .productVariations
        ?.first
        .variations
        ?.first
        .variationLocationDetails
        ?.firstWhereOrNull((i) => i.locationId == locationId)
        ?.qtyAvailable;
  }

  checkProductStockLocationBasedForOrderCreate({
    int? locationId,
    required int index,
  }) {
    return productModelObjs[index]
        .productVariations
        ?.first
        .variations
        ?.first
        .variationLocationDetails
        ?.firstWhereOrNull((i) => i.locationId == locationId)
        ?.qtyAvailable;
  }

  checkUnitsInList({int? id, List<Product>? product, required int index}) {
    return (product?.firstWhere((unitId) =>
        product[index].unitId == unitListModel?.data?.first.baseUnitId));
  }

  ///function to show the unit id actual names...
  checkUnits({
    Product? product,
  }) {
    try {
      return unitListModel?.data
              ?.firstWhereOrNull((i) => i.id == product?.unitId)
              ?.shortName ??
          '';
    } catch (e) {}
  }

  checkUnitsShortName({
    int? unitId,
  }) {
    return unitListModel?.data
        ?.firstWhereOrNull((i) => i.id == unitId)
        ?.shortName;
  }

  checkUnitsActualBaseMultiplier({
    String? unitName,
  }) {
    return unitListModel?.data
            ?.firstWhereOrNull((i) => i.shortName == unitName)
            ?.baseUnitMultiplier ??
        '1.00';
  }

  checkSelectedUnitsIds({
    String? unitName,
  }) {
    return unitListModel?.data
        ?.firstWhereOrNull((i) => i.shortName == unitName)
        ?.id
        .toString();
  }

  checkUnitValueWithGivenId({
    int? idNumber,
  }) {
    return unitListModel?.data
            ?.firstWhereOrNull((i) => i.id == idNumber)
            ?.baseUnitMultiplier ??
        1;
  }

  List<List<String>> nestedist = [];

  addingSpecifiedUnitsInList({
    Product? product,
  }) {
    List<String> names = [];
    // names.add('Pieces');
    // names.add('Plate');
    names.add(checkUnits(product: product));
    for (int i = 0; i < (unitListModel?.data?.length ?? 0); i++) {
      // if (unitListModel?.data?[i].baseUnitId == product?.unitId)
      if (unitListModel?.data?[i].baseUnitId != null) {
        if (product?.unitId == unitListModel?.data?[i].baseUnitId) {
          names.add(unitListModel?.data?[i].shortName ?? '');
        }
      }
    }

    return names;
    // return unitListModel?.data
    //     ?.firstWhereOrNull((i) => i.id == product?.unitId)
    //     ?.actualName;
  }

  addSelectedItemsInList() {
    for (int i = 0; i < productModelObjs.length; i++) {
      if (productQuantityCtrl[i].text.isNotEmpty &&
          productQuantityCtrl[i].text != '0') {
        selectedProducts.add(productModelObjs[i]);
        selectedQuantityList.add(productQuantityCtrl[i].text);
        selectedUnitsList.add(unitListStatusIds[i]);
        selectedUnitsNames.add(unitListStatus[i]);
      }
    }
    print(selectedQuantityList);
  }

  ///Function to fetch the list of units
  UnitListModel? unitListModel;
  List<String> unitListStatus = [];

  Future fetchUnitList({String? pageUrl}) async {
    await ApiServices.getMethod(feedUrl: pageUrl ?? '${ApiUrls.unitListApi}')
        .then((_res) {
      update();
      if (_res == null) return null;
      unitListModel = unitListModelFromJson(_res);
      print(listProductsModel?.data);
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

  ProductShowListModel? productShowListModel;

  Future getProductShowList({String? pageUrl}) async {
    await ApiServices.getMethod(
            feedUrl: pageUrl ??
                '${ApiUrls.productListApi}location_id=${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.id ?? AppStorage.getLoggedUserData()?.staffUser.locationId}&per_page=50')
        .then((_res) {
      update();
      if (_res == null) return null;
      productShowListModel = productShowListModelFromJson(_res);
      print(productShowListModel?.data);
      update();
    }).onError((error, stackTrace) {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      update();
    });
  }

  // load more order page
  void loadMoreSaleOrders() async {
    logger.wtf('load more items function called!');
    //if (hasNextPage && !isFirstLoadRunning && !isLoadMoreRunning.value) {
    isLoadMoreRunning.value = true;

    allSaleOrdersPage += 1;

    await fetchProductsList(allSaleOrdersPage).then((bool? _isFinished) {
      if (_isFinished == null) {
        allSaleOrdersPage -= 1;
      } else if (_isFinished) {
        // This means there is no more data
        // and therefore, we will not send another request
        hasNextPage = false;
      }
    });
    isLoadMoreRunning.value = false;
    // }
  }

  // fetch all sale orders list
  Future<bool?> fetchProductsList(int _page) async {
    print('========================================');
    print('Function calling');
    return await ApiServices.getMethod(
            feedUrl:
                '${ApiUrls.productListApi}&page=$_page&location_id=${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.id ?? AppStorage.getLoggedUserData()?.staffUser.locationId}'
                '&per_page=20')
        .then((_res) {
      if (_res == null) return null;
      final _data = productShowListModelFromJson(_res);
      if (_page > 1 && productShowListModel != null) {
        productShowListModel!.data?.addAll(_data.data!);
      } else {
        productShowListModel = _data;
      }
      update();

      /* fallback end status means is all item finished or not */
      if (productShowListModel?.lastPage != null &&
          _page == productShowListModel?.lastPage) {
        return true;
      }

      return false;
    }).onError((error, stackTrace) {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      return null;
    });
  }

  // void getAllProductsFromStorage({res}) async {
  //   allCategoriesProductsData = AppStorage.getProductsData(res: res);
  //   print('get all products from storage');
  //   print(allCategoriesProductsData?.categories.length);
  //   isFetchingProduct.value = false;
  // }

  // initial order page load function
  callFirstOrderPage() async {
    allSaleOrdersPage = 1;
    isFirstLoadRunning = true;
    hasNextPage = true;
    isLoadMoreRunning.value = false;
    await fetchProductsList(1);
    isFirstLoadRunning = false;
  }

  calculateFinalAmount() {
    finalTotal = 0.00;
    for (int i = 0; i < productsAmount.length; i++) {
      finalTotal += productsAmount[i];
    }
    // finalTotal = finalTotal + orderedTotalAmount;
    print('final Total = ${finalTotal}');
  }

  // bool isProductPriceInclusiveTax(String taxType){
  //   return Get.find<TaxController>().isInlineTaxEnable &&
  //       taxType == "inclusive" ;
  // }
  String calculatingProductAmountForUnit({required int index}) {
    // var productPrice = productModelObjs[index].taxType == "inclusive"
    //     ?
    // var productPrice = isProductPriceInclusiveTax('${productModelObjs[index].taxType}') ?
    //
    // productModelObjs[index].
    // productVariations?.first.variations?.first.sellPriceIncTax
    //     : productModelObjs[index].
    // productVariations?.first.variations?.first.defaultSellPrice;
    return (double.parse(
                '${productQuantityCtrl[index].text.isEmpty ? '0.00' : productQuantityCtrl[index].text}') *
            (double.parse(
                    '${productModelObjs[index].productVariations?.first.variations?.first.sellPriceIncTax}') *
                double.parse(checkUnitsActualBaseMultiplier(
                        unitName: unitListStatus[index]) ??
                    '1.00')))
        .toStringAsFixed(1);
  }

  String calculatingStock({required int index}) {
    if (unitListStatus.isEmpty) return '';
    return AppFormat.doubleToStringUpTo2(
          '${double.parse(checkProductStockLocationBasedForOrderCreate(locationId: AppStorage.getBusinessDetailsData()?.businessData?.locations.first.id, index: index) ?? '0.00') / double.parse(checkUnitsActualBaseMultiplier(unitName: unitListStatus[index]))}',
        ) ??
        '0.00';
  }

  List<String> payTermList() {
    List<String> options = ['Months', 'Days'];
    return options;
  }

  List<String> statusList() {
    List<String> options = ['Final', 'Draft', 'Quotation', 'Proforma'];
    return options;
  }

  List<String> invoiceSchemaList() {
    List<String> options = ['Default', 'Restro'];
    return options;
  }

  calculatingProductAmountForOrder({required int i}) {
    // var productPrice = selectedProducts[i].taxType == "inclusive"
    //     ?
    // selectedProducts[i].
    // productVariations?.first.variations?.first.sellPriceIncTax
    //     : selectedProducts[i].
    // productVariations?.first.variations?.first.defaultSellPrice;
    // var productPrice = isProductPriceInclusiveTax('${selectedProducts[i].taxType}') ?
    //
    // selectedProducts[i].
    // productVariations?.first.variations?.first.sellPriceIncTax
    //     : selectedProducts[i].
    // productVariations?.first.variations?.first.defaultSellPrice;
    return '${double.parse(AppFormat.doubleToStringUpTo2('${double.parse('${selectedProducts[i].productVariations?.first.variations?.first.sellPriceIncTax ?? 0.0}') * double.parse(checkUnitsActualBaseMultiplier(unitName: selectedUnitsNames[i]) ?? '1.00')}') ?? '0.00') * double.parse(selectedQuantityList[i])}';
  }

  //
  // calculatingProductAmountAfterTaxForOrder({required int i}) {
  //   return '${double.parse(calculatingProductAmountForOrder(i: i)) - taxCtrlObj.inlineTaxAmount(selectedProducts[i], calculatingProductAmountForOrder(i: i))}';
  // }

  String subTotalAmount({double ordersItemsSubTotalAmount = 0.0}) {
    double itemsPriceCount = 0.0;
    double itemsTax = 0.0;
    try {
      for (int i = 0; i < selectedProducts.length; i++) {
        // itemsPriceCount += _itr.productTotalPrice;
        // var productPrice = isProductPriceInclusiveTax("${selectedProducts[i].taxType}")
        //     ?
        // selectedProducts[i].
        // productVariations?.first.variations?.first.sellPriceIncTax
        //     : selectedProducts[i].
        // productVariations?.first.variations?.first.defaultSellPrice;
        itemsPriceCount += (double.parse(
                    '${selectedProducts[i].productVariations?.first.variations?.first.defaultSellPrice ?? 0.0}') *
                double.parse(checkUnitsActualBaseMultiplier(
                        unitName: selectedUnitsNames[i]) ??
                    '1.00')) *
            double.parse(selectedQuantityList[i]);
      }
    } catch (e) {
      logger.e('Error to calculate sub total amount => $e');
    }
    try {
      if (!taxCtrlObj.isTaxEnable) {
        // koi calculation nahi because inclusive tax of items already calculate ho rahi han or sava ho rahi han itemspricecount variable main
      } else {
        // itemsTax = (itemsPriceCount *
        //         double.parse(
        //             taxCtrlObj.listTaxModel?.data?[0].amount.toString() ??
        //                 '0')) /
        //     (100 +
        //         double.parse(
        //             taxCtrlObj.listTaxModel?.data?[0].amount.toString() ??
        //                 '0'));
        itemsPriceCount -= itemsTax;
      }
      // finalAmountIncVAT = '${itemsPriceCount + itemsTax}';
    } catch (e) {
      logger.e('Error to calculate sub total amount with tax => $e');
    }
    print(itemsPriceCount);
    return AppFormat.doubleToStringUpTo2(
            '${itemsPriceCount + ordersItemsSubTotalAmount}') ??
        '0';
  }

  // String subTotalAmounta({double ordersItemsSubTotalAmount = 0.0}) {
  //   double itemsPriceCount = 0.0;
  //   double itemsTax = 0.0;
  //   try {
  //     for (int i = 0; i < selectedProducts.length; i++) {
  //       // itemsPriceCount += _itr.productTotalPrice;
  //       itemsPriceCount += double.parse(
  //               '${selectedProducts[i].productVariations?.first.variations?.first.defaultSellPrice ?? 0.0}') *
  //           double.parse(selectedQuantityList[i]);
  //     }
  //     // itemsPriceCount = finalTotal - itemsPriceCount;
  //   } catch (e) {
  //     logger.e('Error to calculate sub total amount => $e');
  //   }
  //   try {
  //     // if (!taxCtrlObj.isTaxEnable) {
  //     //   // koi calculation nahi because inclusive tax of items already calculate ho rahi han or sava ho rahi han itemspricecount variable main
  //     // } else {
  //     //   // itemsTax = (itemsPriceCount *
  //     //   //         double.parse(
  //     //   //             taxCtrlObj.listTaxModel?.data?[0].amount.toString() ??
  //     //   //                 '0')) /
  //     //   //     (100 +
  //     //   //         double.parse(
  //     //   //             taxCtrlObj.listTaxModel?.data?[0].amount.toString() ??
  //     //   //                 '0'));
  //     //   itemsPriceCount = itemsPriceCount - itemsTax;
  //     // }
  //     //finalAmountIncVAT = '${itemsPriceCount + itemsTax}';
  //   } catch (e) {
  //     logger.e('Error to calculate sub total amount with tax => $e');
  //   }
  //   print(itemsPriceCount);
  //   return AppFormat.doubleToStringUpTo2(
  //           '${itemsPriceCount + ordersItemsSubTotalAmount}') ??
  //       '0';
  // }

  ///Function to create order:::::
  orderCreate() async {
    // if (orderCtrlObj.singleOrderData?.id == null) {
    //   showToast('Reference for update order is missing!');
    //   return;
    // }

    /// Working with 2nd approach
    multipartPutMethod();
  }

  multipartPutMethod() async {
    // API Method with url

    String _url = '${ApiUrls.createOrder}'; //
    /*
    Approach 2 (Multipart Request simple )
    */

    Map<String, String> _fields = {};
    _fields['transaction_date'] =
        '${AppFormat.dateYYYYMMDDHHMM24(DateTime.now())}';
    _fields['contact_id'] = '${contactCtrlObj.id}';
    _fields['service_staff_id'] =
        '${AppStorage.getLoggedUserData()?.staffUser.id}';
    _fields['created_by'] = '${AppStorage.getLoggedUserData()?.staffUser.id}';

    _fields['status'] = '${statusValue != null ? statusValue : 'final'}';
    _fields['type'] = 'sell';
    _fields['discounttype'] =
        '${productCtrlCtrlObj.discountType.text.toLowerCase()}';
    _fields['discount_amount'] = '${productCtrlCtrlObj.discoutCtrl.text}';
    _fields['final_total'] = getPayableFinalTotalAmount();
    _fields['exchange_rate'] = '0.00';
    _fields['packing_charge'] = '0.00';
    _fields['packing_charge_type'] = 'fixed';
    _fields['business_id'] =
        '${AppStorage.getBusinessDetailsData()?.businessData?.id ?? AppStorage.getLoggedUserData()?.staffUser.businessId}';
    _fields['location_id'] =
        '${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.id ?? AppStorage.getLoggedUserData()?.staffUser.locationId}';
    _fields['shipping_charges'] =
        '${productCtrlCtrlObj.shippingChargeCtrl.text.isNotEmpty ? productCtrlCtrlObj.shippingChargeCtrl.text : '0'}';
    _fields['is_suspend'] = '0';
    // _fields['total_before_tax'] = '${subTotalAmount()}';
    _fields['total_before_tax'] = getPayableFinalTotalAmount();
    // request.fields['discount_type'] = 'Fixed';
    _fields['tax_amount'] = '${taxCtrlObj.orderTaxAmount}';
    for (int i = 0; i < selectedProducts.length; i++) {
      if (selectedQuantityList[i].isNotEmpty) {
        _fields['product_id[$i]'] = '${selectedProducts[i].id}';
        _fields['variation_id[$i]'] =
            '${selectedProducts[i].productVariations?.first.variations?.first.id}';
        _fields['quantity[$i]'] =
            '${double.parse(selectedQuantityList[i]) * double.parse(checkUnitsActualBaseMultiplier(unitName: selectedUnitsNames[i]) ?? '1.00')}'; //
        _fields['line_discount_type[$i]'] = 'fixed';
        _fields['unit_price_before_discount[$i]'] =
            // calculatingProductAmountAfterTaxForOrder(i: i);
            '${AppFormat.doubleToStringUpTo2('${double.parse(selectedProducts[i].productVariations?.first.variations?.first.defaultSellPrice ?? '0.00')}')}'; //* double.parse(checkUnitsActualBaseMultiplier(unitName: selectedUnitsNames[i]) ?? '1.00')
        _fields['unit_price[$i]'] =
            // calculatingProductAmountAfterTaxForOrder(i: i);
            '${AppFormat.doubleToStringUpTo2('${double.parse(selectedProducts[i].productVariations?.first.variations?.first.defaultSellPrice ?? '0.00')}')}'; //* double.parse(checkUnitsActualBaseMultiplier(unitName: selectedUnitsNames[i]) ?? '1.00')
        _fields['unit_price_inc_tax[$i]'] =
            // calculatingProductAmountForOrder(i: i);
            '${AppFormat.doubleToStringUpTo2('${double.parse(selectedProducts[i].productVariations?.first.variations?.first.sellPriceIncTax ?? '0.00')}')}'; //* double.parse(checkUnitsActualBaseMultiplier(unitName: selectedUnitsNames[i]) ?? '1.00')

        if (selectedProducts[i].productTax != null) {
          _fields['tax_id'] = '${selectedProducts[i].productTax?.id}';
        }
        _fields['item_tax[$i]'] =
            '${taxCtrlObj.calculateItemTax(selectedProducts[i], productCtrlCtrlObj.discoutCtrl.text)}';
        // '${taxCtrlObj.inlineTaxAmount(selectedProducts[i], calculatingProductAmountForOrder(i: i))}';
        _fields['sub_unit_id[$i]'] = '${selectedUnitsList[i]}';
      }
    }

    if (paymentCtrlObj.totalPayingAmount() == 0) {
      _fields['payment_status'] = 'due';
    } else {
      _fields['payment_status'] =
          paymentCtrlObj.totalPayingAmount() < double.parse('${finalTotal}')
              ? 'partial'
              : 'paid';
    }
    // for order suspend = due, cash = paid / partial,

    // Get.find<PaymentController>().fieldsForCheckout(request);
    /// OR

    if (isDirectCheckout == false)
      for (int checkoutIndex = 0;
          checkoutIndex < paymentCtrlObj.paymentWidgetList.length;
          checkoutIndex++) {
        _fields['amount[$checkoutIndex]'] =
            '${paymentCtrlObj.paymentWidgetList[checkoutIndex].amountCtrl.text}';
        _fields['method[$checkoutIndex]'] =
            '${paymentCtrlObj.paymentWidgetList[checkoutIndex].selectedPaymentOption?.paymentMethod}';
        _fields['account_id[$checkoutIndex]'] =
            '${paymentCtrlObj.paymentWidgetList[checkoutIndex].selectedPaymentOption?.account?.id}';
        _fields['card_type[$checkoutIndex]'] = 'credit'; // debit

        if (paymentCtrlObj.isSelectedPaymentOptionCheque(
            index: checkoutIndex)) {
          _fields['cheque_number[$checkoutIndex]'] =
              '${paymentCtrlObj.paymentWidgetList[checkoutIndex].checkNoCtrl.text}';
        } else if (!paymentCtrlObj.isSelectedPaymentOptionCash(
            index: checkoutIndex)) {
          for (int tranIndex = 0; tranIndex < 8; tranIndex++) {
            _fields['transaction_no_$tranIndex'] = '';
          }
          _fields['transaction_no_$checkoutIndex'] =
              '${paymentCtrlObj.paymentWidgetList[checkoutIndex].transactionNoCtrl.text}';
          // _fields['transaction_no_1[$checkoutIndex]'] =
          //     '${paymentCtrlObj.paymentWidgetList[checkoutIndex].transactionNoCtrl.text}';
        }

        _fields['note[$checkoutIndex]'] =
            '${paymentCtrlObj.paymentWidgetList[checkoutIndex].paymentNoteCtrl.text}';
      }

    if (isDirectCheckout == true) {
      _fields['amount[0]'] = '';
      _fields['method[0]'] = 'credit';
      _fields['account_id[0]'] = '';
      _fields['card_type[0]'] = 'credit';
      _fields['cheque_number[0]'] = '';
      _fields['transaction_no_1[0]'] = '';
      _fields['note[0]'] = '';
    }

    logger.i(_fields);

    // selectedProducts.clear();
    // selectedQuantityList.clear();
    // selectedUnitsList.clear();
    // selectedUnitsNames.clear();
    // stopProgress();
    // return;

    // return await request.send().then((response) async {
    //   String result = await response.stream.bytesToString();
    return await ApiServices.postMethod(feedUrl: _url, fields: _fields)
        .then((response) async {
      // logger.i('EndPoint => ${_url}'
      //     '\nStatus Code => {response.statusCode}'
      //     '\nResponse => $response');

      if (response == null) {
        stopProgress();
        Get.offAll(TabsPage());
        showToast('Error occurred');
        return;
      }
      // clearOnOrderPlaceSuccess();
      try {
        salesOrderModel = await saleOrderDataModelFromJson(
            jsonDecode(response)['transaction_data'][0]); //

        stopProgress();
        showToast('Finalize Created Successfully');
        receiptPayment = false;
        update();
        if (isPDFView == false) {
          print('inside print invoice');

          Get.dialog(Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            insetPadding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: InVoicePrintScreen(),
          ));
        }

        logger.i(salesOrderModel?.sellLines);
        print(
            'Sale Order Data Model Sell Lines --> ${salesOrderModel?.sellLines.first.product?.name}');

        if (isPDFView == true) {
          Get.offAll(TabsPage());
          Get.to(PrintData(
            salesView: false,
            saleOrderDataModel: salesOrderModel,
          ));
          isPDFView = false;
        }

        // Get.find<AllPrinterController>().orderDataForPrinting = salesOrderModel;
      } catch (e) {
        debugPrint('Error -> created order response parsing: $e');
      }

      clearAllOtherFields();
    }).onError((error, stackTrace) async {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      await ExceptionController().exceptionAlert(
        errorMsg: '$error',
        exceptionFormat: ApiServices.methodExceptionFormat(
            'POST', ApiUrls.createOrder, error, stackTrace),
      );
      return null;
    });
  }

  SaleOrderDataModel? salesOrderModel;

  void clearAllAddPaymentControllerInformation() {
    paymentCtrlObj.amountCtrl.clear();
    receiptPayment = false;
    paymentCtrlObj.transactionNoCtrl.clear();
    paymentCtrlObj.checkNoCtrl.clear();
    paymentCtrlObj.paymentNoteCtrl.clear();
    paymentCtrlObj.paymentAccountCtrl.clear();
    paymentCtrlObj.fileNameCtrl.clear();
    paymentCtrlObj.paymentMethodCtrl.clear();
    paymentCtrlObj.accountIdCtrl.clear();
    nestedist.clear();
    paidAmount = 0.00;
    unitListStatusIds.clear();
    unitListStatus.clear();
    selectedUnitsList.clear();
    selectedUnitsNames.clear();
    for (int checkoutIndex = 0;
        checkoutIndex < paymentCtrlObj.paymentWidgetList.length;
        checkoutIndex++) {
      paymentCtrlObj.paymentWidgetList[checkoutIndex].amountCtrl.clear();
      paymentCtrlObj.paymentWidgetList[checkoutIndex].transactionNoCtrl.clear();
      paymentCtrlObj.paymentWidgetList[checkoutIndex].checkNoCtrl.clear();
      paymentCtrlObj.paymentWidgetList[checkoutIndex].paymentNoteCtrl.clear();
    }
  }

  void clearAllOtherFields() {
    statusValue = null;
    productQuantityCtrl.clear();
    listProductsModel = null;
    paidAmount = 0.00;
    receiptPayment = false;
    paymentCtrlObj.amountCtrl.clear();
    paymentCtrlObj.transactionNoCtrl.clear();
    paymentCtrlObj.paymentMethodCtrl.clear();
    paymentCtrlObj.accountIdCtrl.clear();
    paymentCtrlObj.paymentMethodCtrl.clear();
    paymentCtrlObj.staffNoteCtrl.clear();
    paymentCtrlObj.sellNoteCtrl.clear();
    paymentCtrlObj.paymentNoteCtrl.clear();
    nestedist.clear();
    unitListStatusIds.clear();
    unitListStatus.clear();
    selectedUnitsList.clear();
    selectedUnitsNames.clear();
    for (int checkoutIndex = 0;
        checkoutIndex < paymentCtrlObj.paymentWidgetList.length;
        checkoutIndex++) {
      paymentCtrlObj.paymentWidgetList[checkoutIndex].amountCtrl.clear();
      paymentCtrlObj.paymentWidgetList[checkoutIndex].transactionNoCtrl.clear();
      paymentCtrlObj.paymentWidgetList[checkoutIndex].checkNoCtrl.clear();
      paymentCtrlObj.paymentWidgetList[checkoutIndex].paymentNoteCtrl.clear();
    }
  }

  fieldsForAddPayment(http.MultipartRequest request) {
    request.fields['amount[0]'] = '${paymentCtrlObj.amountCtrl.text}';
    request.fields['method[0]'] = '${paymentCtrlObj.paymentMethodCtrl.text}';
    // '${paymentWidgetList[checkoutIndex].selectedPaymentOption?.paymentMethod}';
    request.fields['account_id[0]'] =
        '${paymentCtrlObj.accountIdCtrl.text}'; //'27';
    // '${paymentWidgetList[checkoutIndex].selectedPaymentOption?.account?.id}';
    request.fields['card_type[0]'] = 'credit'; // debit

    request.fields['transaction_no_1[0]'] =
        '${paymentCtrlObj.transactionNoCtrl.text}';

    // if (isSelectedPaymentOptionCheque(index: checkoutIndex)) {
    //   request.fields['cheque_number[$checkoutIndex]'] =
    //       '${paymentWidgetList[checkoutIndex].checkNoCtrl.text}';
    // } else if (!isSelectedPaymentOptionCash(index: checkoutIndex)) {
    //   request.fields['transaction_no_1[$checkoutIndex]'] =
    //       '${paymentWidgetList[checkoutIndex].transactionNoCtrl.text}';
    // }

    request.fields['note[0]'] = '${paymentCtrlObj.paymentNoteCtrl.text}';
  }

  ListProductsModel? listProductModel;

  /// Showing Product
  // Future showProductList({String? pageUrl, String? term}) async {
  //   await ApiServices.getMethod(
  //       feedUrl: pageUrl ??
  //           '${ApiUrls.allProducts}?location_id=${AppStorage.getBusinessDetailsData()?.businessData?.locations.first.id}') //
  //       .then((_res) {
  //     update();
  //     if (_res == null) return null;
  //     listProductModel = listProductsModelFromJson(_res);
  //     // var length = searchProductModel?.length ?? 0;
  //     // for (int i = 0; i < length; i++) {
  //     //   productQuantityCtrl.add(TextEditingController());
  //     //   totalAmount.add('0.00');
  //     // }
  //     update();
  //   }).onError((error, stackTrace) {
  //     debugPrint('Error => $error');
  //     logger.e('StackTrace => $stackTrace');
  //     update();
  //   });
  // }

  bool receiptPayment = false;
  String receiptsFinalPayment = '0.00';

  ///Receipts Multiple payment Function
  Future<bool> addReceipt() async {
    // if (orderCtrlObj.singleOrderData?.id == null) {
    //   showToast('Reference for update order is missing!');
    //   return;
    // }

    /// Working with 2nd approach
    return await multipartReceiptPutMethod();
  }

  ReceiptModel? receiptData;

  Future<bool> multipartReceiptPutMethod() async {
    // API Method with url
    // PaymentController _paymentCtrlObj = Get.find<PaymentController>();
    AllSalesController allSalesCtrl = Get.find<AllSalesController>();
    String _url = '${ApiUrls.multiPaymentApi}';
    var length = allSalesCtrl.allSaleOrders?.saleOrdersData.length ?? 0;

    // 'card_number': '',

    Map<String, String> _fields = {};
    for (int i = 0; i < length; i++) {
      if (allSalesCtrl.allSaleOrders?.saleOrdersData[i].isSelected != false)
        _fields['transaction_id[$i]'] =
            '${allSalesCtrl.allSaleOrders?.saleOrdersData[i].id}';
      // _fields['method'] = '${paymentCtrlObj.paymentWidgetList[i].selectedPaymentOption?.paymentMethod}';
      print('${allSalesCtrl.allSaleOrders?.saleOrdersData[i].id}');
    }

    _fields['method'] = 'cash';
    _fields['note'] =
        '${paymentCtrlObj.paymentWidgetList[0].paymentNoteCtrl.text}';
    _fields['card_type'] = 'credit';
    _fields['is_return'] = '0';
    _fields['paid_on'] = '${DateTime.now()}';
    _fields['created_by'] = '${AppStorage.getLoggedUserData()?.staffUser.id}';
    _fields['amount'] = '$receiptsFinalPayment';
    _fields['payment_ref_no'] = '';
    _fields['account_id'] =
        '${paymentCtrlObj.paymentWidgetList[0].selectedPaymentOption?.account?.id}';
    _fields['transaction_no_1'] = '';
    _fields['transaction_no_2'] = '';
    _fields['transaction_no_3'] = '';
    _fields['transaction_no_4'] = '';
    _fields['transaction_no_5'] = '';
    _fields['transaction_no_6'] = '';
    _fields['transaction_no_7'] = '';
    _fields['bank_account_number'] = '';
    _fields['cheque_number'] = '';
    _fields['card_security'] = '';
    _fields['card_year'] = '';
    _fields['card_month'] = '';
    _fields['card_year'] = '';
    _fields['card_month'] = '';
    _fields['card_type'] = 'credit';
    _fields['card_transaction_number'] = '';
    _fields['card_holder_name'] = '';
    _fields['card_number'] = '';
    logger.i(_fields);

    // return await request.send().then((response) async {
    //   String result = await response.stream.bytesToString();
    return await ApiServices.postMethod(feedUrl: _url, fields: _fields)
        .then((response) async {
      logger.i('EndPoint => ${_url}'
          '\nResponse => $response');

      if (response == null) {
        stopProgress();
        Get.offAll(() => TabsPage());
        showToast('Unable to complete the action. Response Issue!');
        return false;
      }

      receiptPayment = true;
      update();
      receiptData = await receiptModelFromJson(response);

      //   for (int i = 0; i < receiptData!.data!.length; i++) {
      stopProgress();
      try {
        if (!isPDFView) {
          debugPrint('printing calling function');
          await Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              insetPadding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: InVoicePrintScreen(isPrintReceipt: true),
            ),
          );
        } else if (isPDFView) {
          // Get.offAll(() => TabsPage());
          print('pdf calling function');
          await Get.to(
            () => ReceiptPdfGenerate(singleReceiptModel: receiptData?.data),
          );
          // for (int i = 0; i < receiptData!.data!.length; i++) {
          //   Get.to(ReceiptPdfGenerate(
          //     singleReceiptModel: receiptData?.data?[i],
          //   ))?.then((value) {
          //     print('Inside -> then ');
          //     print(
          //         'PDF generated for receipt ${receiptData?.data?[i].invoiceNo}');
          //     // Get.to(
          //     //     ReceiptPdfGenerate(singleReceiptModel: receiptData?.data?[i]));
          //   });
          // }

          isPDFView = false;
        }
      } catch (e) {
        print('Error -> $e');
      }

      // }

      // receiptPayment = false;
      update();
      clearAllOtherFields();
      clearAllAddPaymentControllerInformation();

      // Get.find<AllSalesController>().callFirstOrderPageForReceipt();
      // Get.close(1);
      //await Get.to(() => OrderPlaced());
      // Get.offAll(HomePage());
      return true;
    }).onError((error, stackTrace) {
      stopProgress();
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      showToast('Error: $error');
      return true;
    });
  }

  // ///work on edit order:::
  // void addAllOrderedItemsInCart(SaleOrderDataModel singleOrderData) {
  //   //itemCartList.clear();
  //   for (SellLine sellLineItem in singleOrderData.sellLines) {
  //     addOrderItemInCart(sellLineItem);
  //   }
  // }

  void editOrderFunction(SaleOrderDataModel? saleOrderData) {
    // List<String> sku = [];
    List<String> sku2 = [];

    productQuantityCtrl.clear();
    // for (int i = 0; i < searchProductModel.length; i++) {
    //   sku.add(searchProductModel[i].subSku ?? '');
    // }
    for (int i = 0; i < saleOrderData!.sellLines.length; i++) {
      sku2.add(saleOrderData.sellLines[i].product?.sku ?? '');
    }
    for (int i = 0; i < productModelObjs.length; i++) {
      productQuantityCtrl.add(TextEditingController(
        text: getOrderedProductQuantity(i, saleOrderData),
      ));
    }
    calculateFinalAmount();
    print('${orderedTotalAmount}');
    update();
  }

  double orderedTotalAmount = 0.00;

  String getOrderedProductQuantity(
      int allProductsIndex, SaleOrderDataModel saleOrderData) {
    try {
      // print(productModelObjs[allProductsIndex].sku);
      print(saleOrderData.sellLines
              .firstWhereOrNull((saleLine) =>
                  saleLine.product?.sku ==
                  productModelObjs[allProductsIndex].sku)
              ?.quantity
              .toString() ??
          '');
      orderedTotalAmount = ((saleOrderData.sellLines
                      .firstWhereOrNull((saleLine) =>
                          saleLine.product?.sku ==
                          productModelObjs[allProductsIndex].sku)
                      ?.quantity ??
                  0) *
              double.parse(productModelObjs[allProductsIndex]
                      .productVariations
                      ?.first
                      .variations
                      ?.first
                      .sellPriceIncTax ??
                  '0.00') +
          orderedTotalAmount);

      return saleOrderData.sellLines
              .firstWhereOrNull((saleLine) =>
                  saleLine.product?.sku ==
                  productModelObjs[allProductsIndex].sku)
              ?.quantity
              .toString() ??
          '';
    } catch (e) {
      debugPrint(
          'Error -> getOrderedProductQuantity -> all_product_controller => $e');
      return '';
    }
  }

  ///update order function
  updateOrder({bool isOnlyCheckout = false, bool isPay = false}) async {
    // if (orderCtrlObj.singleOrderData?.id == null) {
    //   showToast('Reference for update order is missing!');
    //   return;
    // }

    // simplePutMethod();

    /// Working with 2nd approach
    multipartUpdatePutMethod();

    /// Worked but old method and invoice no issue was there
    // requestPutMethod();
  }

  multipartUpdatePutMethod() async {
    print(updateOrderId);
    // API Method with url
    String _url =
        '${ApiUrls.sellUpdateOrder}${updateOrderId}'; //orderCtrlObj.singleOrderData?.id

    /*
    Approach 2 (Multipart Request simple )
    */

    Map<String, String> _fields = {};

    var _request = http.MultipartRequest('POST', Uri.parse(_url));
    // if (isPay) {
    //   Get.find<PaymentController>()
    //       .fieldsForCheckout(_request, finalTotalAmount());
    //   // checkoutFieldsForCart(request);
    // } else {
    //   activeOrderFields(_request);
    // }
    _fields = _request.fields;

    int _productIteration = 0;

    // _fields['is_suspend'] = '$isSuspend';
    _fields['is_suspend'] = '0';

    _fields['transaction_date'] =
        '${AppFormat.dateYYYYMMDDHHMM24(DateTime.now())}';

    // res waiter id and created by ???
    _fields['service_staff_id'] =
        '${AppStorage.getLoggedUserData()?.staffUser.id}';
    // _fields['created_by'] = '${AppStorage.getLoggedUserData()?.staffUser.id}';

    _fields['contact_id'] = '${contactCtrlObj.id}';

    _fields['status'] = 'final';
    _fields['type'] = 'sell';
    // payment sy related kam
    // _fields['total_before_tax'] = subTotalAmount();
    _fields['total_before_tax'] = '${finalTotal - calculatingTotalDiscount()}';
    _fields['tax_amount'] = ''; //'${taxCtrlObj.orderTaxAmount}';
    if (orderCtrlObj.singleOrderData?.taxId != null)
      _fields['tax_rate__id'] = '${orderCtrlObj.singleOrderData?.taxId}';
    _fields['discounttype'] = '${productCtrlCtrlObj.discountType.text}';
    _fields['discount_amount'] = '${productCtrlCtrlObj.discoutCtrl.text}';

    _fields['final_total'] = '${finalTotal - calculatingTotalDiscount()}';
    // AppFormat.doubleToStringUpTo2('${double.parse(finalAmount())}') ??
    //     '${orderCtrlObj.singleOrderData?.finalTotal}';

    // _fields['exchange_rate'] = '${orderCtrlObj.singleOrderData?.exchangeRate}';

    _fields['packing_charge'] = '0.00';
    // packingChargeCtrl.text.isEmpty
    //     ? (orderManageCtrlObj.selectedOrderType?.packingCharge ?? '0')
    //     : packingChargeCtrl.text;
    _fields['packing_charge_type'] = 'fixed';
    // orderManageCtrlObj.selectedOrderType?.packingChargeType ?? 'fixed';

    _fields['shipping_charges'] = '0.00';
    // shippingChargeCtrl.text.isEmpty ? '0' : shippingChargeCtrl.text;

    _fields['no_of_person'] = '0';
    // noOfPersonsCtrl.text.isEmpty ? '0' : noOfPersonsCtrl.text;

    for (int i = 0; i < selectedProducts.length; i++) {
      if (selectedQuantityList[i].isNotEmpty) {
        _fields['product_id[$i]'] = '${selectedProducts[i].id}';
        _fields['variation_id[$i]'] =
            '${selectedProducts[i].productVariations?.first.variations?.first.id}';
        _fields['quantity[$i]'] = '${selectedQuantityList[i]}';
        _fields['sub_unit_id[$i]'] = '${selectedUnitsList[i]}';
        if (selectedProducts[i].productTax != null) {
          _fields['tax_rate_id[$i]'] = '${selectedProducts[i].productTax?.id}';
        }
        // _fields['tax_rate_id[$_productIteration]'] = '${_itr.productTax?.id}';
        if (selectedProducts[i].productVariations != null) {
          _fields['line_discount_type[$i]'] = 'fixed';
          _fields['unit_price_before_discount[$i]'] =
              '${selectedProducts[i].productVariations?.first.variations?.first.defaultSellPrice}';
          _fields['unit_price[$i]'] =
              '${selectedProducts[i].productVariations?.first.variations?.first.defaultSellPrice}';
          _fields['unit_price_inc_tax[$i]'] =
              '${selectedProducts[i].productVariations?.first.variations?.first.sellPriceIncTax}';
          _fields['item_tax[$i]'] = '0.00';
        }
      }
    }

    if (paymentCtrlObj.totalPayingAmount() == 0) {
      _fields['payment_status'] = 'due';
    } else {
      _fields['payment_status'] =
          paymentCtrlObj.totalPayingAmount() < double.parse('${finalTotal}')
              ? 'partial'
              : 'paid';
    }
    // for order suspend = due, cash = paid / partial,

    // Get.find<PaymentController>().fieldsForCheckout(request);
    /// OR
    for (int checkoutIndex = 0;
        checkoutIndex < paymentCtrlObj.paymentWidgetList.length;
        checkoutIndex++) {
      _fields['amount[$checkoutIndex]'] =
          '${paymentCtrlObj.paymentWidgetList[checkoutIndex].amountCtrl.text}';
      _fields['method[$checkoutIndex]'] =
          '${paymentCtrlObj.paymentWidgetList[checkoutIndex].selectedPaymentOption?.paymentMethod}';
      _fields['account_id[$checkoutIndex]'] =
          '${paymentCtrlObj.paymentWidgetList[checkoutIndex].selectedPaymentOption?.account?.id}';
      _fields['card_type[$checkoutIndex]'] = 'credit'; // debit

      if (paymentCtrlObj.isSelectedPaymentOptionCheque(index: checkoutIndex)) {
        _fields['cheque_number[$checkoutIndex]'] =
            '${paymentCtrlObj.paymentWidgetList[checkoutIndex].checkNoCtrl.text}';
      } else if (!paymentCtrlObj.isSelectedPaymentOptionCash(
          index: checkoutIndex)) {
        // _fields['transaction_no_1[$checkoutIndex]'] =
        //     '${paymentCtrlObj.paymentWidgetList[checkoutIndex].transactionNoCtrl.text}';
        for (int tranIndex = 0; tranIndex < 8; tranIndex++) {
          _fields['transaction_no_$tranIndex'] = '';
        }
        _fields['transaction_no_$checkoutIndex'] =
            '${paymentCtrlObj.paymentWidgetList[checkoutIndex].transactionNoCtrl.text}';
      }

      _fields['note[$checkoutIndex]'] =
          '${paymentCtrlObj.paymentWidgetList[checkoutIndex].paymentNoteCtrl.text}';
    }

    // for (var _itr in selectedProducts) {
    //   if (_itr.modifier.isNotEmpty) {
    //     List<int> allModifierIds = [], allModifierVariationIds = [];
    //     _itr.modifier?.forEach(
    //       (_mod) {
    //         if (!allModifierIds.contains(_mod.productModifier.id)) {
    //           _mod.productModifier.variations.forEach(
    //             (_vars) {
    //               if (!allModifierVariationIds.contains(_vars.id)) {
    //                 allModifierIds.add(_mod.productModifier.id);
    //                 allModifierVariationIds.add(_vars.id);
    //               }
    //             },
    //           );
    //         }
    //       },
    //     );
    //     _fields['parent_sell_line_id[$_productIteration]'] =
    //         '$allModifierIds';
    //     // request.fields['variation_id[$i]'] = '$allModifierVariationIds';
    //   }
    //
    //   _productIteration++;
    // }

    // if (orderCtrlObj.singleOrderData != null &&
    //     orderCtrlObj.singleOrderData!.sellLines.isNotEmpty)
    //   for (var _itr in orderCtrlObj.singleOrderData!.sellLines) {
    //     _fields['product_id[$_productIteration]'] = '${_itr.productId}';
    //     _fields['variation_id[$_productIteration]'] = '${_itr.productId}';
    //     _fields['quantity[$_productIteration]'] = '${_itr.quantity}';
    //     _fields['unit_price[$_productIteration]'] = '${_itr.unitPrice}';
    //     _fields['unit_price_inc_tax[$_productIteration]'] =
    //         '${_itr.unitPriceIncTax}';
    //     _productIteration++;
    //   }

    logger.i(_fields);

    showProgress();
    return await ApiServices.postMethod(feedUrl: _url, fields: _fields)
        .then((response) async {
      // logger.i('EndPoint => ${_url}'
      //     '\nStatus Code => {response.statusCode}'
      //     '\nResponse => $response');

      if (response == null) {
        stopProgress();
        Get.offAll(TabsPage());
        showToast('Error occurred');
        return;
      }

      receiptPayment = false;
      update();
      try {
        salesOrderModel = await saleOrderDataModelFromJson(
            jsonDecode(response)['transaction'][0]); //

        stopProgress();
        showToast('Order Updated Successfully');
        if (isPDFView == false) {
          print('inside print invoice');

          Get.dialog(Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            insetPadding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: InVoicePrintScreen(),
          ));
        }

        logger.i(salesOrderModel?.sellLines);
        print(
            'Sale Order Data Model Sell Lines --> ${salesOrderModel?.sellLines.first.product?.name}');

        if (isPDFView == true) {
          Get.offAll(TabsPage());
          Get.to(PrintData(
            salesView: false,
            saleOrderDataModel: salesOrderModel,
          ));
          isPDFView = false;
        }

        // Get.find<AllPrinterController>().orderDataForPrinting = salesOrderModel;
      } catch (e) {
        debugPrint('Error -> created order response parsing: $e');
      }

      // -----
      showToast('Order Updated Successfully');
      clearAllOtherFields();
      isUpdate = false;
      update();
      //setting home page side area to order type selection
      //to fetch the active orders
      // Get.find<OrderController>().fetchActiveOrders();
      clearAllAddPaymentControllerInformation();
      // Get.offAll(HomePage());
    }).onError((error, stackTrace) async {
      debugPrint('Error => $error');
      logger.e('StackTrace => $stackTrace');
      await ExceptionController().exceptionAlert(
        errorMsg: '$error',
        exceptionFormat: ApiServices.methodExceptionFormat(
            'POST', ApiUrls.updateOrder, error, stackTrace),
      );
      return null;
    });
  }

  addOrderedItemsQty({SaleOrderDataModel? salesOrderData}) {
    var length = salesOrderData?.sellLines.length ?? 0;
    for (int i = 0; i < length; i++) {
      // print(productModelObjs.indexOf(salesOrderData!.sellLines[i].product!));
      // productQuantityCtrl[
      //         productModelObjs.indexOf(salesOrderData!.sellLines[i].product!)]
      //     .text = salesOrderData.sellLines[i].product?.alertQuantity ?? '';
      print('Checking id');
      print(salesOrderData?.sellLines[i].product?.id);
      print(checkTheIndex(id: salesOrderData?.sellLines[i].product?.id));
    }
  }

  checkTheIndex({int? id}) {
    return productModelObjs.firstWhereOrNull((i) => i.id == id)?.name;
  }

  ProductCartController prodCtrl = Get.find<ProductCartController>();

  //function to calculate total discount
  double calculatingTotalDiscount() {
    double itemsDiscountCount = 0.0;
    try {
      if ('Percentage' == prodCtrl.discountType.text) {
        itemsDiscountCount =
            (double.parse(prodCtrl.discoutCtrl.text) / 100) * finalTotal;
        print('Executing Percentage Discount');
        update();
      } else if (prodCtrl.discountType.text == 'Fixed') {
        itemsDiscountCount = double.parse(prodCtrl.discoutCtrl.text);
        print('Executing Fixed Discount');
        update();
      }
    } catch (e) {
      logger.e('Error to calculate Discount Amount => $e');
    }

    return itemsDiscountCount;
  }

// doubleToStringUpTo2 is not using for round off its just want to use in view
  // function to get total payable amount
  String getPayableFinalTotalAmount() {
    return ('${(finalTotal - calculatingTotalDiscount()).toStringAsFixed(2)}') ??
        '0';
  }
}

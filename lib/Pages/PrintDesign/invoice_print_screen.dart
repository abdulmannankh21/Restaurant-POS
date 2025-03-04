import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3_sdt/flutter_pos_printer_platform_image_3_sdt.dart';
// import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/Components/custom_circular_button.dart';
import '/Config/utils.dart';
import '/Controllers/ProductController/all_products_controller.dart';
import '/Pages/PrintDesign/pos_print_layout.dart';
import '/Pages/PrintDesign/pos_receipt_print_layout.dart';
import '/Pages/Tabs/View/TabsPage.dart';
import '/Theme/colors.dart';
import '/Theme/style.dart';
import '../../Controllers/AllPrinterController/allPrinterController.dart';
import '../../const/dimensions.dart';
import '../CreateOrder/selectionDialogue.dart';

// class CustomPrintPaperSize {
//   const CustomPrintPaperSize._internal(this.value);
//   final int value;
//   static const mm58 = CustomPrintPaperSize._internal(1);
//   static const mm80 = CustomPrintPaperSize._internal(2);
//   static const mm113 = CustomPrintPaperSize._internal(3);
//
//   int get width {
//     if (value == CustomPrintPaperSize.mm113.value)
//       return 836;
//     else if (value == CustomPrintPaperSize.mm58.value)
//       return 372;
//     else
//       return 558;
//   }
// }

class InVoicePrintScreen extends StatefulWidget {
  final bool isPrintReceipt;
  final bool isPrintCustomer;

  InVoicePrintScreen({
    Key? key,
    this.isPrintCustomer = false,
    this.isPrintReceipt = false,
  }) : super(key: key);

  @override
  State<InVoicePrintScreen> createState() => _InVoicePrintScreenState();
}

class _InVoicePrintScreenState extends State<InVoicePrintScreen> {
  AllPrinterController allPrinterCtrl = Get.find<AllPrinterController>();

  StreamSubscription<BTStatus>? _subscriptionBtStatus;

  String ipAddress = '';
  String port = '9100';
  bool isZebra = false;
  bool isDialogShown = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _searchingMode = true;

  @override
  void initState() {
    if (Platform.isWindows) allPrinterCtrl.defaultPrinterType = PrinterType.usb;
    super.initState();
    loadIsDialogShown();
    zebraPrintCheck();
    _portController.text = port;
    allPrinterCtrl.scan();

    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
      log(' ----------------- status bt $status ------------------ ');
      allPrinterCtrl.currentStatus = status;

      if (status == BTStatus.connected && allPrinterCtrl.pendingTask != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          PrinterManager.instance.send(
              type: PrinterType.bluetooth, bytes: allPrinterCtrl.pendingTask!);
          allPrinterCtrl.pendingTask = null;
        });
      }
    });
  }

  zebraPrintCheck() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // isZebra = prefs.getBool('zebraPrinter')!;
    // isZebra = AppStorage.getZebraPrinter();
  }

  @override
  void dispose() {
    allPrinterCtrl.subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _portController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  // method to scan devices according PrinterType

  void _setPort(String value) {
    if (value.isEmpty) value = '9100';
    port = value;
    var device = BluetoothPrinter(
      deviceName: value,
      address: ipAddress,
      port: port,
      typePrinter: PrinterType.network,
      state: false,
    );
    _selectDevice(device);
  }

  void _setIpAddress(String value) {
    ipAddress = value;
    BluetoothPrinter device = BluetoothPrinter(
      deviceName: value,
      address: ipAddress,
      port: port,
      typePrinter: PrinterType.network,
      state: false,
    );
    _selectDevice(device);
  }

  void _selectDevice(BluetoothPrinter device) async {
    if (allPrinterCtrl.selectedPrinters != null) {
      if ((device.address != allPrinterCtrl.selectedPrinters!.address) ||
          (device.typePrinter == PrinterType.usb &&
              allPrinterCtrl.selectedPrinters!.vendorId != device.vendorId)) {
        await PrinterManager.instance
            .disconnect(type: allPrinterCtrl.selectedPrinters!.typePrinter);
      }
    }
    allPrinterCtrl.selectedPrinters = device;
    setState(() {});
  }

  Future<void> loadIsDialogShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Retrieve the value of isDialogShown from SharedPreferences
      isDialogShown = prefs.getBool('isDialogShown') ?? false;
    });
  }

  Future<void> saveIsDialogShown(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Save the value of isDialogShown to SharedPreferences
    await prefs.setBool('isDialogShown', value);
  }

  @override
  Widget build(BuildContext context) {
    return // _searchingMode ?
        SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.fontSizeLarge),
      child: GetBuilder<AllPrinterController>(
          builder: (AllPrinterController allPrinterCtrlObj) {
        if (allPrinterCtrlObj.bluetoothDevices == []) {
          return progressIndicator();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'paper_size'.tr,
                  style: appBarHeaderStyle,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.15,
                ),
                CustomButton(
                  title: Text(''),
                  leading: Icon(
                    Icons.refresh,
                    color: kWhiteColor,
                  ),
                  onTap: () {
                    allPrinterCtrl.scan();
                  },
                )
              ],
            ),
            Row(children: [
              Expanded(
                  child: RadioListTile(
                title: Text('80 mm'),
                groupValue: allPrinterCtrlObj.selectedPaperSize,
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: PaperSize.mm80,
                onChanged: (value) {
                  allPrinterCtrlObj.selectedPaperSize = PaperSize.mm80;
                  allPrinterCtrlObj.update();
                  setState(() {});
                },
              )),
              // Expanded(
              //     child: RadioListTile(
              //   title: Text('113 mm'),
              //   groupValue: allPrinterCtrlObj.selectedPaperSize,
              //   dense: true,
              //   contentPadding: EdgeInsets.zero,
              //   value: PaperSize.mm113,
              //   onChanged: (value) {
              //     allPrinterCtrlObj.selectedPaperSize = PaperSize.mm113;
              //     allPrinterCtrlObj.update();
              //     setState(() {});
              //   },
              // )),
              Expanded(
                child: RadioListTile(
                  title: Text('58 mm'),
                  groupValue: allPrinterCtrlObj.selectedPaperSize,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: PaperSize.mm58,
                  onChanged: (value) {
                    allPrinterCtrlObj.selectedPaperSize = PaperSize.mm58;
                    allPrinterCtrlObj.update();
                    setState(() {});
                  },
                ),
              ),
            ]),
            // Text("${allPrinterCtrlObj.selectedPaperSize.width}"),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            // ElevatedButton(
            //   child: Text('print tab action bypass'),
            //   onPressed: () async {
            //     setState(() {
            //       _searchingMode = false;
            //     });
            //     Get.offAll(() => TabsPage());
            //
            //     await Get.dialog(
            //       barrierDismissible: false,
            //       Dialog(
            //         shape: RoundedRectangleBorder(
            //           borderRadius:
            //               BorderRadius.circular(Dimensions.radiusSmall),
            //         ),
            //         insetPadding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            //         child: CustomerCopyDialogue(),
            //       ),
            //     ).then((isCustomerCopyDone) {
            //       if (isCustomerCopyDone != null && isCustomerCopyDone) {
            //         Get.back();
            //       }
            //     });
            //   },
            // ),
            ListView.builder(
              itemCount: allPrinterCtrlObj.bluetoothDevices.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: Dimensions.paddingSizeSmall),
                  child: InkWell(
                    onTap: () async {
                      _selectDevice(allPrinterCtrlObj.bluetoothDevices[index]);
                      allPrinterCtrl.selectedPrinters =
                          allPrinterCtrlObj.bluetoothDevices[index];

                      // Uint8List printPDF = await PrintData(
                      //         saleOrderDataModel:
                      //             Get.find<AllProductsController>()
                      //                 .salesOrderModel)
                      //     .generatePdf(PdfPageFormat.roll113);
                      //
                      // final tempDir = await getTemporaryDirectory();
                      // File printPDFFile =
                      //     await File('${tempDir.path}/generated_print.pdf')
                      //         .create();
                      // await printPDFFile.writeAsBytes(printPDF);
                      //
                      // // String pdfPrintFilePath = File(printPDF).path;
                      // // debugPrint('PDF Print File Path => ${printPDFFile.path}');
                      //
                      // // Zebra Printer
                      // if (isZebra == true) {
                      //   final value = await zsdk.printPdfFileOverTCPIP(
                      //     filePath: printPDFFile.path,
                      //     address:
                      //         '${allPrinterCtrlObj.bluetoothDevices[index].address}',
                      //     port: int.tryParse(
                      //             '${allPrinterCtrlObj.bluetoothDevices[index].port}') ??
                      //         9100,
                      //   );
                      //
                      //   final printerResponse = PrinterResponse.fromMap(value);
                      //   Status status = printerResponse.statusInfo.status;
                      //   print(status);
                      //   if (printerResponse.errorCode == ErrorCode.SUCCESS) {
                      //     //Do something
                      //     Get.back();
                      //   } else {
                      //     Cause cause = printerResponse.statusInfo.cause;
                      //     print(cause);
                      //     Get.back();
                      //
                      //   }
                      // } else {
                      // Other Printers
                      List<int> bytes = [];
                      CapabilityProfile profile =
                          await CapabilityProfile.load();
                      Generator generator = Generator(
                          allPrinterCtrlObj.selectedPaperSize, profile);
                      // bytes += generator.text('Retail App Print');
                      print(Get.find<AllProductsController>().receiptPayment);
                      if (widget.isPrintReceipt) {
                        print('Inside receipt print screen');
                        bytes = await posReceiptLayout(
                          generator,
                          singleReceiptModel: Get.find<AllProductsController>()
                              .receiptData
                              ?.data,
                        );
                        allPrinterCtrlObj.printEscPos(bytes, generator);
                      } else {
                        bytes = await posInvoiceAndKotPrintLayout(
                          generator,
                          selectedSaleOrderData:
                              Get.find<AllProductsController>().salesOrderModel,
                        );
                        allPrinterCtrlObj.printEscPos(bytes, generator);
                      }

                      setState(() {
                        _searchingMode = false;
                      });

                      print(allPrinterCtrlObj.bluetoothDevices[index].address);
                      print(allPrinterCtrlObj.bluetoothDevices[index].port);
                      Get.offAll(() => TabsPage());
                      if (!widget.isPrintCustomer)
                        await Get.dialog(
                          // barrierDismissible: false,
                          Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSmall)),
                            insetPadding:
                                EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: CustomerCopyDialogue(
                                // callback: () {
                                //   debugPrint('Selection Dialog Callback');
                                // },
                                ),
                          ),
                        ).then((isCustomerCopyDone) {
                          if (isCustomerCopyDone != null &&
                              isCustomerCopyDone) {
                            // AppStorage.removeCutomerCopy();
                            Get.back();
                          }
                        });

                      // loadIsDialogShown();
                      // if (!isDialogShown) {
                      //   setState(() {
                      //     isDialogShown = true;
                      //   });
                      //
                      //   // Save the updated value of isDialogShown to SharedPreferences
                      //   saveIsDialogShown(true);
                      // } else {
                      //   // If the dialog has already been shown, simply navigate back
                      //   // Get.back();
                      //   // Get.back();
                      //   // Get.back();
                      //   Get.offAll(() => TabsPage());
                      //
                      // }
                    },
                    child: Stack(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${allPrinterCtrlObj.bluetoothDevices[index].deviceName}'),
                            Platform.isAndroid &&
                                    allPrinterCtrlObj.defaultPrinterType ==
                                        PrinterType.usb
                                ? const SizedBox()
                                : Visibility(
                                    visible: !Platform.isWindows,
                                    child: Text(
                                        "${allPrinterCtrlObj.bluetoothDevices[index].address}"),
                                  ),
                            index !=
                                    allPrinterCtrlObj.bluetoothDevices.length -
                                        1
                                ? Divider(
                                    color: Theme.of(context).disabledColor)
                                : const SizedBox(),
                          ]),
                      (allPrinterCtrl.selectedPrinters != null &&
                              ((allPrinterCtrlObj.bluetoothDevices[index]
                                                  .typePrinter ==
                                              PrinterType.usb &&
                                          Platform.isWindows
                                      ? allPrinterCtrlObj
                                              .bluetoothDevices[index]
                                              .deviceName ==
                                          allPrinterCtrl
                                              .selectedPrinters!.deviceName
                                      : allPrinterCtrlObj
                                                  .bluetoothDevices[index]
                                                  .vendorId !=
                                              null &&
                                          allPrinterCtrl
                                                  .selectedPrinters!.vendorId ==
                                              allPrinterCtrlObj
                                                  .bluetoothDevices[index]
                                                  .vendorId) ||
                                  (allPrinterCtrlObj.bluetoothDevices[index]
                                              .address !=
                                          null &&
                                      allPrinterCtrl
                                              .selectedPrinters!.address ==
                                          allPrinterCtrlObj
                                              .bluetoothDevices[index]
                                              .address)))
                          ? const Positioned(
                              top: 5,
                              right: 5,
                              child: Icon(Icons.check, color: Colors.green),
                            )
                          : const SizedBox(),
                    ]),
                  ),
                );
              },
            ),
            Visibility(
              visible:
                  allPrinterCtrlObj.defaultPrinterType == PrinterType.network &&
                      Platform.isWindows,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _ipController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(
                    label: Text('ip_address'.tr),
                    prefixIcon: const Icon(Icons.wifi, size: 24),
                  ),
                  onChanged: _setIpAddress,
                ),
              ),
            ),
            Visibility(
              visible:
                  allPrinterCtrlObj.defaultPrinterType == PrinterType.network &&
                      Platform.isWindows,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  controller: _portController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(
                    label: Text('port'.tr),
                    prefixIcon: const Icon(Icons.numbers_outlined, size: 24),
                  ),
                  onChanged: _setPort,
                ),
              ),
            ),
            Visibility(
              visible:
                  allPrinterCtrlObj.defaultPrinterType == PrinterType.network &&
                      Platform.isWindows,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: OutlinedButton(
                  onPressed: () async {
                    if (_ipController.text.isNotEmpty)
                      _setIpAddress(_ipController.text);
                    setState(() {
                      _searchingMode = false;
                    });
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 50),
                    child: Text("print_ticket".tr, textAlign: TextAlign.center),
                  ),
                ),
              ),
            )
          ],
        );
      }),
    );
    //     : InvoiceDialog(
    //   order: widget.order, orderDetails: widget.orderDetails,
    //   onPrint: (i.Image? image) => _printReceipt(image!),
    // );
  }
}

// class InvoiceDialog extends StatelessWidget {
//   final OrderModel? order;
//   final List<OrderDetailsModel>? orderDetails;
//   final Function(i.Image? image) onPrint;
//   const InvoiceDialog({Key? key, required this.order, required this.orderDetails, required this.onPrint}) : super(key: key);
//
//   String _priceDecimal(double price) {
//     return price.toStringAsFixed(Get.find<SplashController>().configModel!.digitAfterDecimalPoint!);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double fontSize = window.physicalSize.width > 1000 ? Dimensions.fontSizeExtraSmall : Dimensions.paddingSizeSmall;
//     ScreenshotController controller = ScreenshotController();
//     Restaurant restaurant = Get.find<AuthController>().profileModel!.restaurants![0];
//
//     double itemsPrice = 0;
//     double addOns = 0;
//
//     for(OrderDetailsModel orderDetails in orderDetails!) {
//       for(AddOn addOn in orderDetails.addOns!) {
//         addOns = addOns + (addOn.price! * addOn.quantity!);
//       }
//       itemsPrice = itemsPrice + (orderDetails.price! * orderDetails.quantity!);
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//
//         Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
//             boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300]!, spreadRadius: 1, blurRadius: 5)],
//           ),
//           width: context.width - ((window.physicalSize.width - 700) * 0.4),
//           padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//           child: Screenshot(
//             controller: controller,
//             child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
//
//               Text(restaurant.name!, style: robotoMedium.copyWith(fontSize: fontSize)),
//               Text(restaurant.address!, style: robotoRegular.copyWith(fontSize: fontSize)),
//               Text(restaurant.phone!, style: robotoRegular.copyWith(fontSize: fontSize), textDirection: TextDirection.ltr),
//               Text(restaurant.email!, style: robotoRegular.copyWith(fontSize: fontSize)),
//               const SizedBox(height: 10),
//
//               Wrap(
//                 children: [
//                   Row(children: [
//                     Text('${'order_id'.tr}:', style: robotoRegular.copyWith(fontSize: fontSize)),
//                     const SizedBox(width: 5),
//                     Text(order!.id.toString(), style: robotoMedium.copyWith(fontSize: fontSize)),
//                   ]),
//
//                   Text(DateConverter.dateTimeStringToMonthAndTime(order!.createdAt!), style: robotoRegular.copyWith(fontSize: fontSize)),
//                 ],
//               ),
//               order!.scheduled == 1 ? Text(
//                 '${'scheduled_order_time'.tr} ${DateConverter.dateTimeStringToDateTime(order!.scheduleAt!)}',
//                 style: robotoRegular.copyWith(fontSize: fontSize),
//               ) : const SizedBox(),
//               const SizedBox(height: 5),
//
//               Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//                 Text(order!.orderType!.tr, style: robotoRegular.copyWith(fontSize: fontSize)),
//                 Text(order!.paymentMethod!.tr, style: robotoRegular.copyWith(fontSize: fontSize)),
//               ]),
//               Divider(color: Theme.of(context).textTheme.bodyLarge!.color, thickness: 1),
//
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('${order!.customer!.fName} ${order!.customer!.lName}', style: robotoRegular.copyWith(fontSize: fontSize)),
//                 Text(order!.deliveryAddress?.address ?? '', style: robotoRegular.copyWith(fontSize: fontSize)),
//                 Text(order!.deliveryAddress?.contactPersonNumber ?? '', style: robotoRegular.copyWith(fontSize: fontSize)),
//               ]),
//               const SizedBox(height: 10),
//
//               Row(children: [
//                 Expanded(flex: 1, child: Text('sl'.tr.toUpperCase(), style: robotoMedium.copyWith(fontSize: fontSize))),
//                 Expanded(flex: 5, child: Text('item_info'.tr, style: robotoMedium.copyWith(fontSize: fontSize))),
//                 Expanded(flex: 2, child: Text(
//                   'qty'.tr, style: robotoMedium.copyWith(fontSize: fontSize),
//                   textAlign: TextAlign.center,
//                 )),
//                 Expanded(flex: 2, child: Text(
//                   'price'.tr, style: robotoMedium.copyWith(fontSize: fontSize),
//                   textAlign: TextAlign.right,
//                 )),
//               ]),
//               Divider(color: Theme.of(context).textTheme.bodyLarge!.color, thickness: 1),
//
//               ListView.builder(
//                 itemCount: orderDetails!.length,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 padding: EdgeInsets.zero,
//                 itemBuilder: (context, index) {
//
//                   String addOnText = '';
//                   for (var addOn in orderDetails![index].addOns!) {
//                     addOnText = '$addOnText${(addOnText.isEmpty) ? '' : ',  '}${addOn.name} X ${addOn.quantity} = ${addOn.price! * addOn.quantity!}';
//                   }
//
//                   String? variationText = '';
//                   if(orderDetails![index].variation!.isNotEmpty) {
//                     for(Variation variation in orderDetails![index].variation!) {
//                       variationText = '${variationText!}${variationText.isNotEmpty ? ', ' : ''}${variation.name} (';
//                       for(VariationOption value in variation.variationValues!) {
//                         variationText = '${variationText!}${variationText.endsWith('(') ? '' : ', '}${value.level}';
//                       }
//                       variationText = '${variationText!})';
//                     }
//                   }else if(orderDetails![index].oldVariation!.isNotEmpty) {
//                     variationText = orderDetails![index].oldVariation![0].type;
//                   }
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
//                     child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                       Expanded(flex: 1, child: Text(
//                         (index+1).toString(),
//                         style: robotoRegular.copyWith(fontSize: fontSize),
//                       )),
//                       Expanded(flex: 5, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
//                         Text(
//                           orderDetails![index].foodDetails!.name!,
//                           style: robotoMedium.copyWith(fontSize: fontSize),
//                         ),
//                         const SizedBox(height: 2),
//
//                         addOnText.isNotEmpty ? Text(
//                           '${'addons'.tr}: $addOnText',
//                           style: robotoRegular.copyWith(fontSize: fontSize),
//                         ) : const SizedBox(),
//
//                         (orderDetails![index].foodDetails!.variations != null && orderDetails![index].foodDetails!.variations!.isNotEmpty) ? Text(
//                           '${'variations'.tr}: ${variationText!}',
//                           style: robotoRegular.copyWith(fontSize: fontSize),
//                         ) : const SizedBox(),
//
//                       ])),
//                       Expanded(flex: 2, child: Text(
//                         orderDetails![index].quantity.toString(), textAlign: TextAlign.center,
//                         style: robotoRegular.copyWith(fontSize: fontSize),
//                       )),
//                       Expanded(flex: 2, child: Text(
//                         _priceDecimal(orderDetails![index].price!), textAlign: TextAlign.right,
//                         style: robotoRegular.copyWith(fontSize: fontSize),
//                       )),
//                     ]),
//                   );
//                 },
//               ),
//               Divider(color: Theme.of(context).textTheme.bodyLarge!.color, thickness: 1),
//
//               PriceWidget(title: 'item_price'.tr, value: _priceDecimal(itemsPrice), fontSize: fontSize),
//               const SizedBox(height: 5),
//               addOns > 0 ? PriceWidget(title: 'add_ons'.tr, value: _priceDecimal(addOns), fontSize: fontSize) : const SizedBox(),
//               SizedBox(height: addOns > 0 ? 5 : 0),
//               PriceWidget(title: 'subtotal'.tr, value: _priceDecimal(itemsPrice + addOns), fontSize: fontSize),
//               const SizedBox(height: 5),
//               PriceWidget(title: 'discount'.tr, value: _priceDecimal(order!.restaurantDiscountAmount!), fontSize: fontSize),
//               const SizedBox(height: 5),
//               PriceWidget(title: 'coupon_discount'.tr, value: _priceDecimal(order!.couponDiscountAmount!), fontSize: fontSize),
//                 const SizedBox(height: 5),
//               PriceWidget(title: 'vat_tax'.tr, value: _priceDecimal(order!.totalTaxAmount!), fontSize: fontSize),
//               const SizedBox(height: 5),
//               PriceWidget(title: 'delivery_fee'.tr, value: _priceDecimal(order!.deliveryCharge!), fontSize: fontSize),
//               Divider(color: Theme.of(context).textTheme.bodyLarge!.color, thickness: 1),
//               PriceWidget(title: 'total_amount'.tr, value: _priceDecimal(order!.orderAmount!), fontSize: fontSize+2),
//               Divider(color: Theme.of(context).textTheme.bodyLarge!.color, thickness: 1),
//
//               Text('thank_you'.tr, style: robotoRegular.copyWith(fontSize: fontSize)),
//               Divider(color: Theme.of(context).textTheme.bodyLarge!.color, thickness: 1),
//
//               Text(
//                 '${Get.find<SplashController>().configModel!.businessName}. ${Get.find<SplashController>().configModel!.footerText}',
//                 style: robotoRegular.copyWith(fontSize: fontSize),
//               ),
//
//             ]),
//           ),
//         ),
//         const SizedBox(height: Dimensions.paddingSizeSmall),
//
//         CustomButton(buttonText: 'print_invoice'.tr, height: 40, onPressed: () {
//           controller.capture(delay: const Duration(milliseconds: 10)).then((capturedImage) async {
//             Get.back();
//             onPrint(i.decodeImage(capturedImage!));
//           }).catchError((onError) {
//           });
//         }),
//
//       ]),
//     );
//   }
//
// }

// class PriceWidget extends StatelessWidget {
//   final String title;
//   final String value;
//   final double fontSize;
//   const PriceWidget(
//       {Key? key,
//       required this.title,
//       required this.value,
//       required this.fontSize})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Text(
//         title,
//       ),
//       Text(
//         value,
//       ),
//     ]);
//   }
// }

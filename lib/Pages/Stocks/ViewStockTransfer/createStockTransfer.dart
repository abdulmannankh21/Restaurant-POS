import 'package:bizmodo_emenu/Components/custom_circular_button.dart';
import 'package:bizmodo_emenu/Config/utils.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

import '../../../Components/p4Headings.dart';
import '../../../Components/textfield.dart';
import '../../../Config/DateTimeFormat.dart';
import '../../../Controllers/ProductController/all_products_controller.dart';
import '../../../Controllers/StockTransferController/stockTransferController.dart';
import '../../../Services/storage_services.dart';
import '../../../Theme/colors.dart';
import '../../../Theme/style.dart';

class CreateStockTransfer extends StatefulWidget {
  const CreateStockTransfer({Key? key}) : super(key: key);

  @override
  State<CreateStockTransfer> createState() => _CreateStockTransferState();
}

class _CreateStockTransferState extends State<CreateStockTransfer> {
  StockTransferController stockTranCtrlObj =
      Get.find<StockTransferController>();
  // AllProductsController allProdCtrlObj = Get.find<AllProductsController>();
  Future<void> _showDatePicker() async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1600).subtract(const Duration(days: 3652)),
      lastDate: DateTime.now().add(
        const Duration(days: 3652),
      ),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      selectableDayPredicate: (dateTime) {
        // Disable 25th Feb 2023
        if (dateTime == DateTime(2023, 2, 25)) {
          return false;
        } else {
          return true;
        }
      },
    );

    stockTranCtrlObj.dateCtrl.text = '${AppFormat.dateDDMMYY(dateTime!)}';
    print(dateTime);
  }

  List<String> getStatusList() {
    // List<String> options = ['Pending', 'In Transit', 'Completed'];
    List<String> options = [];
    if (stockTranCtrlObj.statusListModel != null) {
      for (int i = 0; i < stockTranCtrlObj.statusListModel!.length; i++) {
        options.add('${stockTranCtrlObj.statusListModel?[i].value}');
      }
    }

    return options;
  }

  @override
  void initState() {
    // TODO: implement initState
    stockTranCtrlObj.fetchStatusList();
    stockTranCtrlObj.searchProductList(term: '');
    super.initState();
  }

  void dispose() {
    stockTranCtrlObj.finalTotal = 0.00;
    stockTranCtrlObj.totalAmount.clear();
    stockTranCtrlObj.productQuantityCtrl.clear();
    stockTranCtrlObj.searchProductModel.clear();
    stockTranCtrlObj.selectedProducts.clear();
    stockTranCtrlObj.selectedQuantityList.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text('create_stock_transfer'.tr),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10, top: 20),
          child: SingleChildScrollView(
            child: GetBuilder<StockTransferController>(
                builder: (StockTransferController stockTransferCtrlObj) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headings(txt: 'date'.tr + ':*'),
                          AppFormField(
                            width: width * 0.43,
                            readOnly: true,
                            controller: stockTranCtrlObj.dateCtrl,
                            labelText: 'select_date'.tr,
                            prefixIcon: Icon(Icons.calendar_month),
                            onTap: () {
                              setState(() {
                                _showDatePicker();

                                //_show(context);
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headings(txt: 'status'.tr + ':*'),
                          GetBuilder<StockTransferController>(
                              builder: (StockTransferController stockCtrl) {
                            if (stockCtrl.statusListModel == null) {
                              return progressIndicator();
                            }
                            return DropdownButtonHideUnderline(
                              child: DropdownButton2(
                                isExpanded: true,
                                hint: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      'please_select'.tr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: txtFieldHintColor,
                                      ),
                                    )),
                                items: getStatusList().map((e) {
                                  return DropdownMenuItem(
                                      value: e, child: Text(e));
                                }).toList(),
                                value: stockTransferCtrlObj.statusValue,
                                dropdownDirection:
                                    DropdownDirection.textDirection,
                                dropdownPadding:
                                    EdgeInsets.only(left: 5, right: 5),
                                buttonPadding:
                                    EdgeInsets.only(left: 15, right: 15),
                                onChanged: (String? value) {
                                  setState(() {
                                    stockTransferCtrlObj.statusValue = value;
                                  });
                                },
                                buttonHeight: height * 0.06,
                                buttonWidth: width * 0.43,
                                buttonDecoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    borderRadius: BorderRadius.circular(15),
                                    color: kWhiteColor),
                                itemHeight: 40,
                                itemPadding: EdgeInsets.zero,
                                itemHighlightColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ///Location From
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headings(txt: 'location_from'.tr + ':*'),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              isExpanded: true,
                              hint: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    'please_select'.tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: txtFieldHintColor,
                                    ),
                                  )),
                              items: stockTransferCtrlObj
                                  .getBusinessLocationItems()
                                  .map((e) {
                                return DropdownMenuItem(
                                    value: e, child: Text(e));
                              }).toList(),
                              value:
                                  stockTransferCtrlObj.locationFromStatusValue,
                              dropdownDirection:
                                  DropdownDirection.textDirection,
                              dropdownPadding:
                                  EdgeInsets.only(left: 5, right: 5),
                              buttonPadding:
                                  EdgeInsets.only(left: 15, right: 15),
                              onChanged: (String? value) {
                                setState(() {
                                  stockTransferCtrlObj.locationFromStatusValue =
                                      value;
                                  stockTranCtrlObj.locationFromID =
                                      AppStorage.getBusinessDetailsData()
                                          ?.businessData
                                          ?.locations[stockTransferCtrlObj
                                              .getBusinessLocationItems()
                                              .indexOf(value!)]
                                          .id
                                          .toString();

                                  print(stockTranCtrlObj.locationFromID);
                                });
                              },
                              buttonHeight: height * 0.06,
                              buttonWidth: width * 0.43,
                              buttonDecoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(15),
                                  color: kWhiteColor),
                              itemHeight: 40,
                              itemPadding: EdgeInsets.zero,
                              itemHighlightColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      ///Location to
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headings(txt: 'location_to'.tr + ':*'),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              isExpanded: true,
                              hint: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    'please_select'.tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: txtFieldHintColor,
                                    ),
                                  )),
                              items: stockTransferCtrlObj
                                  .getBusinessLocationItems()
                                  .map((e) {
                                return DropdownMenuItem(
                                    value: e, child: Text(e));
                              }).toList(),
                              value: stockTransferCtrlObj.locationToStatusValue,
                              dropdownDirection:
                                  DropdownDirection.textDirection,
                              dropdownPadding:
                                  EdgeInsets.only(left: 5, right: 5),
                              buttonPadding:
                                  EdgeInsets.only(left: 15, right: 15),
                              onChanged: (String? value) {
                                setState(() {
                                  stockTransferCtrlObj.locationToStatusValue =
                                      value;

                                  stockTranCtrlObj.locationToID =
                                      AppStorage.getBusinessDetailsData()
                                          ?.businessData
                                          ?.locations[stockTransferCtrlObj
                                              .getBusinessLocationItems()
                                              .indexOf(value!)]
                                          .id
                                          .toString();

                                  print(stockTranCtrlObj.locationFromID);
                                });
                              },
                              buttonHeight: height * 0.06,
                              buttonWidth: width * 0.43,
                              buttonDecoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(15),
                                  color: kWhiteColor),
                              itemHeight: 40,
                              itemPadding: EdgeInsets.zero,
                              itemHighlightColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  IntrinsicHeight(
                    child: Container(
                      width: width,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: kWhiteColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // headings(txt: 'Search Products'),
                          // AppFormField(
                          //   controller: stockTranCtrlObj.searchCtrl,
                          //   labelText: 'Search products for stock',
                          //   onEditingComp: () {
                          //     stockTranCtrlObj.searchProductList(
                          //         term: stockTranCtrlObj.searchCtrl.text);
                          //     print(stockTranCtrlObj.searchCtrl.text);
                          //   },
                          // ),

                          Product4Headings(
                            txt1: 'product_name'.tr,
                            txt2: 'qty'.tr,
                            txt3: 'price'.tr,
                            txt4: 'total'.tr,
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: GetBuilder<StockTransferController>(builder:
                                (StockTransferController stockTransferCtrl) {
                              if (stockTransferCtrl.searchProductModel ==
                                  null) {
                                return progressIndicator();
                              }
                              return ListView.builder(
                                  padding: EdgeInsetsDirectional.only(
                                      top: 5, bottom: 5, start: 10, end: 10),
                                  physics: ScrollPhysics(),
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemCount: stockTransferCtrl
                                      .searchProductModel.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: EdgeInsets.only(
                                        bottom: 5,
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5),
                                      color: index.isEven
                                          ? kWhiteColor
                                          : Colors.grey.withOpacity(0.1),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //name
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '${stockTransferCtrl.searchProductModel[index].name}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: true,
                                                ),
                                              ),

                                              //Quantity
                                              Expanded(
                                                flex: 1,
                                                child: AppFormField(
                                                    controller: stockTransferCtrl
                                                            .productQuantityCtrl[
                                                        index],
                                                    padding: EdgeInsets.only(
                                                        right: 5),
                                                    isOutlineBorder: false,
                                                    isColor: index.isEven
                                                        ? kWhiteColor
                                                        : Colors.transparent,
                                                    onChanged: (value) {
                                                      stockTransferCtrl
                                                                  .totalAmount[
                                                              index] =
                                                          '${double.parse('${stockTransferCtrl.productQuantityCtrl[index].text.isEmpty ? '0.00' : stockTransferCtrl.productQuantityCtrl[index].text}') * double.parse('${stockTransferCtrl.searchProductModel[index].sellingPrice.toString()}')}';
                                                      stockTransferCtrl
                                                          .calculateFinalAmount();
                                                      debugPrint(
                                                          'Product Amount');
                                                      debugPrint(
                                                          stockTranCtrlObj
                                                                  .totalAmount[
                                                              index]);
                                                      stockTransferCtrl
                                                          .update();
                                                    }),
                                              ),
                                              //unit
                                              Expanded(
                                                flex: 1,
                                                child: Center(
                                                  child: Text(
                                                    '${AppFormat.doubleToStringUpTo2(stockTransferCtrl.searchProductModel[index].sellingPrice)}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Center(
                                                  child: Text(
                                                    '${stockTransferCtrl.totalAmount[index]}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  IntrinsicHeight(
                    child: Container(
                      width: width,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: kWhiteColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headings(txt: 'additional_notes'.tr),
                          AppFormField(
                            controller: stockTranCtrlObj.additionalNotes,
                            labelText: 'additional_notes'.tr,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  headings(
                                      txt: 'total_amount'.tr +
                                          ': ${stockTranCtrlObj.finalTotal}'),
                                  CustomButton(
                                    title: Text(
                                      'save'.tr,
                                      style: TextStyle(color: kWhiteColor),
                                    ),
                                    onTap: () {
                                      showProgress();
                                      stockTranCtrlObj.addSelectedItemsInList();
                                      stockTranCtrlObj.createStockTransfer();
                                    },
                                    bgColor:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Text headings({required String txt}) {
    return Text(
      txt,
      style: appBarHeaderStyle,
    );
  }
}

import 'package:bizmodo_emenu/Components/custom_circular_button.dart';
import 'package:bizmodo_emenu/Config/utils.dart';
import 'package:bizmodo_emenu/Controllers/ContactController/ContactController.dart';
import 'package:bizmodo_emenu/Controllers/CustomerVisits/CustomerVisitsController.dart';
import 'package:bizmodo_emenu/Controllers/ListUserController/ListUserController.dart';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

import '../../../Components/textfield.dart';
import '../../../Config/DateTimeFormat.dart';

import '../../../Theme/colors.dart';
import '../../../Theme/style.dart';

class CreateCustomerVisits extends StatefulWidget {
  CustomerVisitsController? custVisitCtrl;
  int? index;
  bool editCustVisit;
  CreateCustomerVisits(
      {Key? key, this.custVisitCtrl, this.index, this.editCustVisit = false})
      : super(key: key);

  @override
  State<CreateCustomerVisits> createState() => _CreateCustomerVisitsState();
}

class _CreateCustomerVisitsState extends State<CreateCustomerVisits> {
  CustomerVisitsController customerVisitsCtrlObj =
      Get.find<CustomerVisitsController>();
  ListUserController listUserCtrl = Get.find<ListUserController>();
  ContactController contactCtrl = Get.find<ContactController>();

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

    customerVisitsCtrlObj.dateCtrl.text = '${AppFormat.dateDDMMYY(dateTime!)}';
    print(dateTime);
  }

  @override
  void initState() {
    // TODO: implement initState
    listUserCtrl.fetchListUsers();
    contactCtrl.fetchCustomerList(30);
    if (widget.editCustVisit == true) initialFunction();
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  initialFunction() {
    if (widget.editCustVisit == true &&
        widget.custVisitCtrl?.customerVisitsListModel?.data[widget.index!]
                .contactId !=
            null) {
      customerVisitsCtrlObj.valuefirst = true;
    } else if (widget.editCustVisit == true &&
        widget.custVisitCtrl?.customerVisitsListModel?.data[widget.index!]
                .contactId ==
            null) {
      customerVisitsCtrlObj.valuefirst = false;
      customerVisitsCtrlObj.companyCtrl.text = widget
          .custVisitCtrl!.customerVisitsListModel!.data[widget.index!].company;
      customerVisitsCtrlObj.visitAddressCtrl.text = widget.custVisitCtrl!
          .customerVisitsListModel!.data[widget.index!].visitingAddress;
    }

    customerVisitsCtrlObj.idCtrl.text = widget
        .custVisitCtrl!.customerVisitsListModel!.data[widget.index!].id
        .toString();
    customerVisitsCtrlObj.dateCtrl.text = widget
        .custVisitCtrl!.customerVisitsListModel!.data[widget.index!].visitOn;
    customerVisitsCtrlObj.statusValue =
        '${widget.custVisitCtrl!.customerVisitsListModel?.data[widget.index!].firstName ?? ''} ${widget.custVisitCtrl!.customerVisitsListModel?.data[widget.index!].lastName ?? ''}';
    customerVisitsCtrlObj.purposeOfVisitingCtrl.text = widget.custVisitCtrl!
        .customerVisitsListModel!.data[widget.index!].purposeOfVisiting;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headings(txt: 'Add Visit'),
            Divider(),
            SizedBox(
              height: 10,
            ),
            headings(txt: 'Whom you\'ll be visiting?*'),
            GetBuilder<CustomerVisitsController>(
                builder: (CustomerVisitsController creatsVisitsCtrlObj) {
              return Row(
                children: [
                  Expanded(
                    // height: 20,
                    // width: M,
                    child: CheckboxListTile(
                        value: creatsVisitsCtrlObj.valuefirst,
                        onChanged: (bool? value) {
                          setState(() {
                            creatsVisitsCtrlObj.valuefirst = value!;
                            creatsVisitsCtrlObj.valueSecond = false;
                            creatsVisitsCtrlObj.contactStatusValue = null;
                            creatsVisitsCtrlObj.companyCtrl.clear();
                            creatsVisitsCtrlObj.visitAddressCtrl.clear();
                            creatsVisitsCtrlObj.update();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Contact',
                          style: TextStyle(color: blackColor),
                        )),
                  ),
                  Expanded(
                    // height: 20,
                    // width: 20,
                    child: CheckboxListTile(
                        value: creatsVisitsCtrlObj.valueSecond,
                        onChanged: (bool? value) {
                          setState(() {
                            creatsVisitsCtrlObj.valueSecond = value!;
                            creatsVisitsCtrlObj.valuefirst = false;
                            creatsVisitsCtrlObj.contactStatusValue = null;
                            creatsVisitsCtrlObj.companyCtrl.clear();
                            creatsVisitsCtrlObj.visitAddressCtrl.clear();
                            creatsVisitsCtrlObj.update();
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Other',
                          style: TextStyle(color: blackColor),
                        )),
                  ),
                ],
              );
            }),
            if (customerVisitsCtrlObj.valuefirst == true)
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headings(txt: 'Contact:'),
                      GetBuilder<ContactController>(
                          builder: (ContactController contactCtrll) {
                        if (contactCtrll.customerContacts != null)
                          return DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              isExpanded: true,
                              hint: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    'Please Select',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: txtFieldHintColor,
                                    ),
                                  )),
                              items: customerVisitsCtrlObj
                                  .contactList(contactCtrl)
                                  .map((e) {
                                return DropdownMenuItem(
                                    value: e, child: Text(e));
                              }).toList(),
                              value: customerVisitsCtrlObj.contactStatusValue,
                              dropdownDirection:
                                  DropdownDirection.textDirection,
                              dropdownMaxHeight: height * 0.4,
                              dropdownPadding:
                                  EdgeInsets.only(left: 5, right: 5),
                              buttonPadding:
                                  EdgeInsets.only(left: 15, right: 15),
                              onChanged: (String? value) {
                                setState(() {
                                  customerVisitsCtrlObj.contactStatusValue =
                                      value;
                                });
                              },
                              buttonHeight: height * 0.06,
                              buttonWidth: width * 0.885,
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
                        else
                          return progressIndicator();
                      }),
                    ],
                  ),
                ],
              ),
            if (customerVisitsCtrlObj.valueSecond == true)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headings(txt: 'Person/Company:'),
                      AppFormField(
                        width: width * 0.43,
                        controller: customerVisitsCtrlObj.companyCtrl,
                        labelText: '',
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headings(txt: 'Visit Address:'),
                      AppFormField(
                        width: width * 0.43,
                        controller: customerVisitsCtrlObj.visitAddressCtrl,
                        labelText: '',
                      ),
                    ],
                  ),
                ],
              ),
            SizedBox(
              height: 15,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headings(txt: 'Visit On:*'),
                    AppFormField(
                      width: width * 0.43,
                      readOnly: true,
                      controller: customerVisitsCtrlObj.dateCtrl,
                      labelText: 'Select Date',
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
                    headings(txt: 'Assigned To:*'),
                    GetBuilder<ListUserController>(
                        builder: (ListUserController listUserCtrll) {
                      if (listUserCtrll.listuserModel != null)
                        return DropdownButtonHideUnderline(
                          child: DropdownButton2(
                            isExpanded: true,
                            hint: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  'Please Select',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: txtFieldHintColor,
                                  ),
                                )),
                            items: customerVisitsCtrlObj
                                .assignedToList(listUserCtrll)
                                .map((e) {
                              return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(fontSize: 14),
                                  ));
                            }).toList(),
                            value: customerVisitsCtrlObj.statusValue,
                            dropdownDirection: DropdownDirection.textDirection,
                            dropdownMaxHeight: height * 0.2,
                            dropdownPadding: EdgeInsets.only(left: 5, right: 5),
                            buttonPadding: EdgeInsets.only(left: 15, right: 15),
                            onChanged: (String? value) {
                              setState(() {
                                customerVisitsCtrlObj.statusValue = value;
                              });
                            },
                            buttonHeight: height * 0.06,
                            buttonWidth: width * 0.43,
                            buttonDecoration: BoxDecoration(
                                border: Border.all(
                                    width: 1,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(15),
                                color: kWhiteColor),
                            itemHeight: 40,
                            itemPadding: EdgeInsets.zero,
                            itemHighlightColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        );
                      else
                        return progressIndicator();
                    }),
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
                    headings(txt: 'Purpose of visiting:'),
                    AppFormField(
                      controller: customerVisitsCtrlObj.purposeOfVisitingCtrl,
                      labelText: '',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          title: Text(
                            (widget.editCustVisit == true) ? 'Update' : 'Save',
                            style: TextStyle(color: kWhiteColor),
                          ),
                          onTap: () {
                            showProgress();
                            if (widget.editCustVisit == true) {
                              print('update is pressed');
                              customerVisitsCtrlObj.updateCustomerVisits();
                            } else {
                              print(' save is pressed');
                              customerVisitsCtrlObj.createCustomerVisits();
                            }
                          },
                          bgColor: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        CustomButton(
                          title: Text(
                            'Close',
                            style: TextStyle(color: kWhiteColor),
                          ),
                          onTap: () {
                            Get.back();
                          },
                          bgColor: buttonColor,
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
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

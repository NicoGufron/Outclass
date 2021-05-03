import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mcourse.dart';
import 'package:shiftsoft/models/mcourseuser.dart';
import 'package:shiftsoft/models/mresult.dart';
import 'package:shiftsoft/models/mtransaction.dart';
import 'package:shiftsoft/models/mvoucher.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/transactionApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/enrichment.dart';
import 'package:shiftsoft/widgets/imageBox.dart';

class TransactionConfirmation extends StatefulWidget {
  final int mode,id;
  const TransactionConfirmation({Key key, this.mode, this.id}) : super(key: key);

  @override
  _TransactionConfirmationState createState() => _TransactionConfirmationState();
}

class _TransactionConfirmationState extends State<TransactionConfirmation> {

  int courseId;
  int transactionMasterID = 0;

  double totalPrice = 0;

  String paymentMethod;
  String method;
  String tempPaymentName = "";

  bool courseLoading = true;
  bool transactionMasterStatusLoading = true;
  bool courseUserLoading = true;

  Course course;
  List<CourseUser> courseUser;
  Transaction transactionMaster;
  Voucher voucher;
  Widget paymentMethodWidget;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "paymentMethod", "checkOut", "sessionPrice", "totalBill", "discount", "useVoucher", "session", "student", 
    "chooseYourPaymentMethod", "seeMore", "buyNow", "paymentInOutclass", "doYouWantToJoinCourse", "yesIDo", "noThanks",
    "sessionRegister", "yesRegister",  "registerConfirmation", "payBefore", "hours", "payBeforeContd"
  ];

  @override
  void initState(){
    super.initState();
    courseId = widget.id;
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();
    
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    if(courseLoading){
      initCourseById();
    }
  }

  initTransactionMasterById() async {
    setState(() {
      transactionMasterStatusLoading = true;
    });

    transactionMaster = await transactionApi.getTransactionMaster(context, transactionMasterID);

    setState(() {
      transactionMasterStatusLoading = false;
      transactionMaster = transactionMaster;
    });
  }

  initCourseById() async {
    setState(() {
      courseLoading = true;
    });

    course = await courseApi.getCourse(context, widget.id, parameter: "with[0]=Teacher.User");

    setState(() {
      courseLoading = false;
      course = course;
      //default paymentMethod ketika baru buka halaman
      paymentMethodWidget = _createpaymentMethodWidget(imagePath: "assets/icon/logo-ovo.png", paymentName: "OVO Cash", channel: "ovo");
      tempPaymentName = "OVO";
    });
  }

  Future<Null> _refresh() async {
    await initCourseById();
  }

  Widget _createpaymentMethodWidget({String imagePath = "", String paymentName = "", String channel = ""}){
    setState(() {
      method = channel;
      tempPaymentName = paymentName.toUpperCase();
    });
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Image.asset(imagePath, width: 63, height: 32),
        ),
        SizedBox(width: 10),
        Container(
          padding: EdgeInsets.only(left: 5),
          child: SSText(paymentName, 4)
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    if(courseLoading == false){
      if(voucher != null){
        if(voucher.isDiscountPercent){
          double tempPrice = course.pricePayment * voucher.discount / 100;
          totalPrice = course.pricePayment - tempPrice;
        }
        else
          totalPrice = double.parse(course.pricePayment.toString()) - voucher.discount;
      }else{
        totalPrice = double.parse(course.pricePayment.toString());
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(message["checkOut"], 4, color: config.blueColor),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor), 
        onPressed: (){
          customNavigator(context, "enrichmentDetail/$courseId/3");
        }),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          height: MediaQuery.of(context).size.height,
          child: courseLoading ? 
          Center(
            child: CircularProgressIndicator(),
          )
          :
          ListView.builder(
            itemCount: 1,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index){
              final item = course;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white),
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Enrichment(course: course, message: message, inBookingList: 0, enrichmentCard: true,),
                      InkWell(
                          child: Card(
                          elevation: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                child: Image.asset("assets/icon/voucher.png", width:24, height:24, color: config.greenColor),
                              ),
                              Expanded(
                                flex:1,
                                child: Container(
                                  padding: EdgeInsets.only(left: 5),
                                  child: SSText(voucher == null ? message["useVoucher"] : voucher.name, 6, color: config.greenColor))),
                              Icon(Icons.keyboard_arrow_right, color: config.greenColor)
                            ],
                          ),
                        ),
                        onTap: () async {
                          final tempVoucher = await customNavigator(context, "voucherList/$courseId/3") as Voucher;
                          if(tempVoucher != null){
                            setState(() {
                              voucher = tempVoucher;
                            });
                          }
                        },
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 25, bottom: 15, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SSText(message["sessionPrice"], 8, color: config.lightGrayColor),
                            SSText(numberFormat(item.pricePayment, ""), 6)
                          ],
                        ),
                      ),
                      voucher != null ?
                      Container(
                        padding: EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SSText(message["discount"], 8, color: config.lightGrayColor),
                            voucher.isDiscountPercent ?
                            SSText(voucher.discount.toString() + "%", 6, color: Colors.red)
                            :
                            SSText( "-" +numberFormat(voucher.discount, ""), 6, color: Colors.red)
                          ],
                        ),
                      ) : Container(
                        padding: EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SSText(message["discount"], 8, color: config.lightGrayColor),
                            SSText("0", 6),
                          ],
                        )
                      ),
                      SizedBox(height: 16.5),
                      Divider(thickness: 1),
                      voucher != null ?
                      Container(
                        padding: EdgeInsets.only(top:18.5, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SSText(message["totalBill"], 8, color: config.lightGrayColor),
                            SSText(numberFormat(totalPrice, ""), 6)
                          ],
                        ),
                      ) 
                      :
                      Container(padding: EdgeInsets.only(top:18.5, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SSText(message["totalBill"], 8, color: config.lightGrayColor),
                            SSText(numberFormat((item.pricePayment), ""), 5,)
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: SSText(message["paymentMethod"], 1, size: 24, color: config.blueColor)
                              ),
                            InkWell(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Center(
                                  child: SSText(message["seeMore"], 8, color: config.blueColor),
                                ),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: config.lightBlueColor,
                                ),
                              ),
                              onTap: (){
                                // customNavigator(context,"enrichmentSearch");
                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  isDismissible: false,
                                  context: context,
                                  builder: (BuildContext context){
                                    return Container(
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight:Radius.circular(10))),
                                      height: MediaQuery.of(context).size.height * 0.85,
                                      child: Column(
                                        children: <Widget>[  
                                          Container(
                                            child: Row(
                                              children: <Widget>[
                                                IconButton(icon: Icon(Icons.close), onPressed: (){Navigator.pop(context);},),
                                                SSText(message["chooseYourPaymentMethod"], 4),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: MediaQuery.of(context).size.height * 0.75,
                                            child: ListView.builder(
                                              itemCount: 1,
                                              itemBuilder: (BuildContext context, int index){
                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
                                                      child: SSText(message["paymentInOutclass"], 4, fontWeight: FontWeight.w600,),
                                                    ),
                                                    InkWell(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: <Widget>[
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                                            child: Image.asset("assets/icon/logo-ovo.png", width: 53, height: 22),
                                                          ),
                                                          Expanded(
                                                            flex:1,
                                                            child: Container(
                                                              padding: EdgeInsets.only(left: 5),
                                                              child: SSText("OVO Cash", 6)
                                                            )
                                                          ),
                                                          Icon(Icons.keyboard_arrow_right)
                                                        ],
                                                      ),
                                                      onTap: (){
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          paymentMethodWidget = _createpaymentMethodWidget(imagePath: "assets/icon/logo-ovo.png", paymentName: "OVO Cash", channel: "ovo");
                                                        });
                                                      },
                                                    ),
                                                    InkWell(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: <Widget>[
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                                            child: Image.asset("assets/icon/mandiri.png", width: 53, height: 22),
                                                          ),
                                                          Expanded(
                                                            flex:1,
                                                            child: Container(
                                                              padding: EdgeInsets.only(left: 5),
                                                              child: SSText("Mandiri Virtual Account", 6)
                                                            )
                                                          ),
                                                          Icon(Icons.keyboard_arrow_right)
                                                        ],
                                                      ),
                                                      onTap: (){
                                                        // payment("mandiri_virtual");
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          paymentMethodWidget = _createpaymentMethodWidget(imagePath: "assets/icon/mandiri.png", paymentName: "Mandiri Virtual Account", channel: "mandiri_virtual");
                                                        });
                                                      },
                                                    ),
                                                    InkWell(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: <Widget>[
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                                            child: Image.asset("assets/icon/dana.png", width: 53, height: 22),
                                                          ),
                                                          Expanded(
                                                            flex:1,
                                                            child: Container(
                                                              padding: EdgeInsets.only(left: 5),
                                                              child: SSText("Dana", 6)
                                                            )
                                                          ),
                                                          Icon(Icons.keyboard_arrow_right)
                                                        ],
                                                      ),
                                                      onTap: (){
                                                        // payment("dana");
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          paymentMethodWidget = _createpaymentMethodWidget(imagePath: "assets/icon/dana.png", paymentName: "Dana", channel: "dana");
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  }
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      //metode pembayaran
                      paymentMethodWidget == null ?
                      Container() :
                      paymentMethodWidget
                      // InkWell(
                      //   child: Card(
                      //     elevation: 2,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Padding(
                      //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      //           child: Image.asset("assets/icon/alfamart.png", width: 53, height: 22),
                      //         ),
                      //         Expanded(
                      //           flex:1,
                      //           child: Container(
                      //             padding: EdgeInsets.only(left: 5),
                      //             child: SSText("Alfamart", 6)
                      //           )
                      //         ),
                      //         Icon(Icons.keyboard_arrow_right)
                      //       ],
                      //     ),
                      //   ),
                      //   onTap: (){
                      //     payment("alfagroup");
                      //   },
                      // ),
                      // InkWell(
                      //   child: Card(
                      //     elevation: 2,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Padding(
                      //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      //           child: Image.asset("assets/icon/shopeepay.png", width: 53, height: 22),
                      //         ),
                      //         Expanded(
                      //           flex:1,
                      //           child: Container(
                      //             padding: EdgeInsets.only(left: 5),
                      //             child: SSText("ShopeePay QRIS", 6)
                      //           )
                      //         ),
                      //         Icon(Icons.keyboard_arrow_right)
                      //       ],
                      //     ),
                      //   ),
                      //   onTap: (){
                      //     payment("shopeepay_qris");
                      //   },
                      // ),
                      // InkWell(
                      //   child: Card(
                      //     elevation: 2,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Padding(
                      //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      //           child: Image.asset("assets/icon/shopeepay.png", width: 53, height: 22),
                      //         ),
                      //         Expanded(
                      //           flex:1,
                      //           child: Container(
                      //             padding: EdgeInsets.only(left: 5),
                      //             child: SSText("ShopeePay", 6)
                      //           )
                      //         ),
                      //         Icon(Icons.keyboard_arrow_right)
                      //       ],
                      //     ),
                      //   ),
                      //   onTap: (){
                      //     payment("shopeepay_jump");
                      //   },
                      // ),
                      // InkWell(
                      //   child: Card(
                      //     elevation: 2,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Padding(
                      //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      //           child: Image.asset("assets/icon/linkaja_logo.png", width: 53, height: 22),
                      //         ),
                      //         Expanded(
                      //           flex:1,
                      //           child: Container(
                      //             padding: EdgeInsets.only(left: 5),
                      //             child: SSText("LinkAja!", 6)
                      //           )
                      //         ),
                      //         Icon(Icons.keyboard_arrow_right)
                      //       ],
                      //     ),
                      //   ),
                      //   onTap: (){
                      //     payment("linkaja");
                      //   },
                      // ),
                      // InkWell(
                      //   child: Card(
                      //     elevation: 2,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Padding(
                      //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      //           child: Image.asset("assets/icon/mandiri.png", width: 53, height: 22),
                      //         ),
                      //         Expanded(
                      //           flex:1,
                      //           child: Container(
                      //             padding: EdgeInsets.only(left: 5),
                      //             child: SSText("Mandiri Virtual Account", 6)
                      //           )
                      //         ),
                      //         Icon(Icons.keyboard_arrow_right)
                      //       ],
                      //     ),
                      //   ),
                      //   onTap: (){
                      //     payment("mandiri_virtual");
                      //   },
                      // ),
                      // InkWell(
                      //   child: Card(
                      //     elevation: 2,
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: <Widget>[
                      //         Padding(
                      //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      //           child: Image.asset("assets/icon/dana.png", width: 53, height: 22),
                      //         ),
                      //         Expanded(
                      //           flex:1,
                      //           child: Container(
                      //             padding: EdgeInsets.only(left: 5),
                      //             child: SSText("Dana", 6)
                      //           )
                      //         ),
                      //         Icon(Icons.keyboard_arrow_right)
                      //       ],
                      //     ),
                      //   ),
                      //   onTap: (){
                      //     payment("dana");
                      //   },
                      // ),
                    ]
                  ),
                ),
              );
            }
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: config.blueColor),
        child: FlatButton(
          child: SSText(message["buyNow"], 4, color: Colors.white),
          onPressed: () async {
            // buat createTransactionApi

            int tempVoucherId = 0;
            if (voucher != null) {
              tempVoucherId = voucher.id;
            }
            
            showDialog(context: context, builder: (BuildContext context){
              return AlertDialog(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SSText(message["sessionRegister"], 4),
                    SizedBox(height: 10),
                    SSText(message["registerConfirmation"] + numberFormat(course.pricePayment, "idr"), 5),
                    SizedBox(height: 10),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(color: config.orangeColor),
                      child: FlatButton(
                        child: SSText(message["yesRegister"], 4, color: config.whiteGrayColor),
                        onPressed: () async {
                          Alert(context: context, loading: true, disableBackButton: true);
                          
                          Result result;
                          result = await courseApi.createTransaction(context, config.user.id.toString(), widget.id.toString(), tempPaymentName.toUpperCase(), "1", voucherId: tempVoucherId.toString());
                          Navigator.pop(context);

                          checkAPIResponse(
                            context,
                            result,
                            successContent: message["payBefore"] + " 2 " + message["hours"].toLowerCase() + ", " + message["payBeforeContd"].toLowerCase() + " " + numberFormat(course.priceBooking, "idr"),
                            successGoBack: true,
                            success: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              customNavigator(context, "transactionMaster");
                              customNavigator(context, "transactionDetail/${result.data["ID"]}/3");
                              customNavigator(
                                context,
                                "transactionConfirmationPayment/${result.data["ID"]}/3",
                                arguments: method
                              );
                            }
                          );
                        },
                      ),
                    )
                  ],
                )
              );
            });
            // Navigator.pop(context);

            
            // buat faspay
          },
        ),
      ),
    );
  }
}
  

// klo dana -> ganti link channel=dana
// alfamart dkk -> ganti link channel=alfagroup
// linkaja -> ganti link channel=linkaja

// PENTING SEKALI INI GAN
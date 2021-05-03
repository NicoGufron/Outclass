import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mcourseuser.dart';
import 'package:shiftsoft/models/mdetailtransaction.dart';
import 'package:shiftsoft/models/mtransaction.dart';
import 'package:shiftsoft/resources/courseApi.dart';
import 'package:shiftsoft/resources/transactionApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shiftsoft/widgets/starRating.dart';
import 'package:shiftsoft/widgets/imageBox.dart';

class TransactionDetail extends StatefulWidget {
  final int mode, id;
  const TransactionDetail({Key key, this.mode, this.id}) : super(key: key);
  @override
  _TransactionDetailState createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {

  int transactionId;

  String paymentMethod;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "transactionProcessed", "thanksUsingOutclass", "waitingConfirmation", "sessionDone", "transactionProcessed",
    "theme", "subTheme", "transactionCancelled", "transactionDetail", "transactionCancelledSub", "addNewReview", "cancelledTime",
    "startTime", "registerTime", "sessionPrice", "discount", "totalPrice", "paymentMethod", "cancelled", "transferDate", "paidAt",
    "lesson", "payNow", "pleaseCompleteTransaction", "waitingPayment", "paymentCompleted"
  ];

  Transaction transactionMaster;

  bool transactionMasterLoading = true;
  bool transactionDetailLoading = true;

  void didChangeDependencies() async {
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();
    
    if(transactionMasterLoading)
      initTransactionMaster();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    transactionId = widget.id;
  }

  initTransactionMaster() async {
    setState(() {
      transactionMasterLoading = true;
    });

    // transactionMaster = await transactionApi.getTransactionMasterList(context, parameter: "with[0]=TransactionDetail.Course.Teacher.User&filtersArr[0][]=id|=|$transactionId|god");
    transactionMaster = await transactionApi.getTransactionMaster(context, transactionId, parameter: "&with[0]=TransactionDetail.Course.Teacher.User&with[1]=TransactionDetail.Course.Lesson");

    setState(() {
      transactionMasterLoading = false;
      transactionMaster = transactionMaster;
    });
  }

  @override
  Widget build(BuildContext context) {
  Configuration config = Configuration.of(context);
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: SSText(transactionMasterLoading ? "" : transactionMaster.invoice, 3, color: config.blueColor),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color:config.blueColor), 
        onPressed: (){
          Navigator.pop(context);
      }),
    ),
    body: Container(
      decoration: BoxDecoration(color:Colors.white),
      height: MediaQuery.of(context).size.height,
      child: transactionMasterLoading?
      Center(
        child: CircularProgressIndicator()
      )
      :
      Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: 1,
          itemBuilder: (BuildContext context, int index){
            final itemMaster = transactionMaster;
            final item = itemMaster.detailTransactionList[0];
            return Container(
                child: Column(
                children: <Widget>[
                // DIPAKE KETIKA SUDAH SELESAI SESINYA
                itemMaster.status >= 4 ?
                Container(
                  decoration: BoxDecoration(color: config.darkGreenColor),
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SSText(message["paymentCompleted"], 4, color: Colors.white, fontWeight: FontWeight.bold),
                            SSText(message["thanksUsingOutclass"], 6, color: Colors.white)
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Icon(Icons.check_circle, color: Colors.white),
                      )
                    ]
                  )
                )
                :
                //menunggu sesi transsaksi selesai diproses
                itemMaster.status == 2 ?
                Container(
                  decoration: BoxDecoration(color: config.orangeColor),
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SSText(message["waitingPayment"], 4, color: Colors.white, fontWeight: FontWeight.bold),
                            SSText(message["pleaseCompleteTransaction"], 6, color: Colors.white)
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.timelapse,color: config.orangeColor)
                        ),
                      )
                    ]
                  )
                )
                :
                // DIPAKE KETIKA SESI DIBATALKAN
                itemMaster.status == 1 ?
                Container(
                  decoration: BoxDecoration(color: Colors.red),
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SSText(message["transactionCancelled"], 4, color: Colors.white, fontWeight: FontWeight.bold),
                            SSText(message["transactionCancelledSub"], 6, color: Colors.white)
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.close,color: Colors.red)
                        ),
                      )
                    ]
                  )
                ) 
                :
                Container(),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white),
                    padding:EdgeInsets.only(bottom:25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Card(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                InkWell(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: ImageBox(
                                      CompanyAsset("avatar",  item.course.teacher.user.pic), 
                                      0, 
                                      fit: BoxFit.cover, 
                                      width: 45, 
                                      height: 45
                                    )
                                  ),
                                  onTap: (){
                                    customNavigator(context, "teacherDetail/${item.course.teacherId}/3");
                                  }
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      InkWell(
                                        child: SSText(item.course.teacher.user.name, 3, color: Colors.black),
                                        onTap: (){
                                          customNavigator(context, "teacherDetail/${item.course.teacherId}/3");
                                        }
                                      ),
                                      SizedBox(height: 5),
                                      Container(
                                        child: SSText(item.course.title, 8)
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: <Widget>[
                                          StarRating(
                                            starCount: 5,
                                            color: config.orangeColor,
                                            size: 12,
                                            rating: item.course.teacher.rating
                                          ),
                                          SizedBox(width: 5),
                                          SSText("(" + double.parse(item.course.teacher.rating.toString()).toStringAsFixed(1) + ")", 7, color: config.orangeColor)
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal:15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SSText(message["registerTime"] , 4, size: 12, color: config.lightGrayColor),
                                    SSText(DateFormat('dd-MM-yyyy hh:mm').format(itemMaster.createdAt), 5),
                                  ],
                                ),
                                itemMaster.status == 1 ? 
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SSText(message["cancelledTime"],  4, size: 12, color: config.lightGrayColor),
                                    SSText(DateFormat('dd-MM-yyyy hh:mm').format(itemMaster.cancelDate), 5,)
                                  ],
                                )
                                :
                                itemMaster.status == 2 ?
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SSText(message["startTime"], 4, size: 12, color: config.lightGrayColor),
                                    SSText(DateFormat('dd-MM-yyyy hh:mm').format(item.course.startTime), 5)
                                  ],
                                )
                                //taruh
                                :
                                itemMaster.status == 3 ? 
                                SSText(message["paidAt"], 4, size: 12, color: config.lightGrayColor)
                                :
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SSText(message["transferDate"],  4, size: 12, color: config.lightGrayColor),
                                    SSText(DateFormat('dd-MM-yyyy hh:mm').format(itemMaster.transferDate), 5)
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      SSText(message["lesson"], 4, size: 12, color: config.lightGrayColor),
                                      SSText(item.course.lesson.name, 4)
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      SSText(message["theme"] , 4, size: 12, color: config.lightGrayColor),
                                      SSText(item.course.topic, 4)
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SSText(message["sessionPrice"], 4, size: 12, color: config.lightGrayColor),
                                SSText(numberFormat(itemMaster.subTotalPrice, "idr"), 4)
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SSText(message["discount"], 4, size: 12, color: config.lightGrayColor),
                                SSText(numberFormat(itemMaster.totalDiscount, "idr"), 4, color: Colors.red)
                              ],
                            ),
                            SizedBox(height: 5),
                            Divider(height: 1, color: Colors.black),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SSText(message["totalPrice"], 4, size: 12, color: config.lightGrayColor),
                                SSText(numberFormat(itemMaster.totalPrice, "idr"), 4)
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SSText(message["paymentMethod"], 4, size: 12, color: config.lightGrayColor),
                                itemMaster.paymentMethod == "OVO" ? 
                                Container(
                                  width: 38,
                                  height: 38,
                                  child: Image.asset("assets/icon/logo-ovo.png")
                                ) :
                                itemMaster.paymentMethod == "MANDIRI VIRTUAL ACCOUNT" ? 
                                Container(
                                  width: 50,
                                  height: 50,
                                  child: Image.asset("assets/icon/mandiri.png")
                                ) :
                                itemMaster.paymentMethod == "DANA" ? 
                                Container(
                                  width: 38,
                                  height: 38,
                                  child: Image.asset("assets/icon/dana.png")
                                ) :
                                itemMaster.paymentMethod == "TRANSFER" ?
                                Row(
                                  children: <Widget>[
                                    Image.asset("assets/icon/icon-cash.png", width: 40, height: 40),
                                    SizedBox(width: 5),
                                    SSText("Transfer", 4, color: Colors.black)
                                  ],
                                ) 
                                :
                                itemMaster.status == 1 ?
                                SSText(message["cancelled"].toUpperCase(), 4, color: Colors.red) 
                                : 
                                Container()
                              ],
                            ),
                          ],
                        )
                      )
                    ],
                  ),
                ),
              ),
            ],
          ));
          }
        ),
      )),
      bottomNavigationBar: 
        transactionMasterLoading ? 
        Center(
          child: CircularProgressIndicator(),
        ) 
        :
        transactionMaster.status == 2 ?
        Container(
          decoration: BoxDecoration(color: config.blueColor),
          child: FlatButton(
            child: SSText(message["payNow"], 4, color: Colors.white,),
            onPressed: () async {
              await customNavigator(
                context,
                "transactionConfirmationPayment/${transactionMaster.id}/3",
                arguments: transactionMaster.paymentMethod
              );
              setState(() {
                transactionMasterLoading = true;
              });

              await initTransactionMaster();

              setState(() {
                transactionMasterLoading = false;
              });
            },
          )
        ) : 
        Container(
          decoration: BoxDecoration(color: Colors.white),
          child: FlatButton(
            child: SSText("", 4, color: Colors.white),
          )
        )

      // bottomNavigationBar: Container(
      //   child:  ? 
      //   Center(
      //     child: CircularProgressIndicator(),
      //   ) 
      //   :
      //   !haveReviewed && transactionMaster.detailTransactionList[0].course.status == 5 ?
      //     Container(
      //       decoration: BoxDecoration(color: config.blueColor),
      //       child: FlatButton(
      //         child: SSText(message["addNewReview"],4 , color: Colors.white),
      //         onPressed: (){
      //           customNavigator(context, "reviewForm/${transactionMaster.detailTransactionList[0].course.teacherId}/3");
      //         },
      //         )
      //       )
      //       : Container(
      //         decoration: BoxDecoration(color: Colors.white),
      //         child: FlatButton(
      //           child: SSText("", 4, color: Colors.white),
      //         )
      //       )
      //   )
      );
    }
  }
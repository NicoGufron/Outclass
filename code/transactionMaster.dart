import 'dart:wasm';

import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mdetailtransaction.dart';
import 'package:shiftsoft/models/mtransaction.dart';
import 'package:shiftsoft/models/muser.dart';
import 'package:shiftsoft/resources/transactionApi.dart';
import 'package:shiftsoft/resources/userApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shiftsoft/widgets/imageBox.dart';

class TransactionMaster extends StatefulWidget {
  @override
  _TransactionMasterState createState() => _TransactionMasterState();
}

class _TransactionMasterState extends State<TransactionMaster> {

  List<Transaction> transactionMasterList;
  
  bool transactionMasterLoading = true;
  bool userLoading = true;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "totalPrice", "payNow", "writeAReview", "seeDetails", "cancelled", "waitingConfirmation", "paid",
    "transactionList", "waitingPayment"
  ];

  User user;

  void didChangeDependencies() async {
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    if(transactionMasterLoading)
      initTransactionMasterList();
      //gak perlu pakek await

    // await checkUser();
  }

  initUserById() async {
    Configuration config = Configuration.of(context);
    setState((){
      userLoading = true;
    });

    user = await userApi.getUser(context, config.user.id);

    setState((){
      userLoading = false;
      user = user;
    });
  }

  initTransactionMasterList() async{
    Configuration config = Configuration.of(context);
    setState(() {
      transactionMasterLoading = true;
    });

    transactionMasterList = await transactionApi.getTransactionMasterList(context, parameter: 
      "with[0]=TransactionDetail.Course.Teacher.User&filtersArr[0][]=user_id|=|"+config.user.id.toString()+"|god&order=created_at-desc"
    );

    setState(() {
      transactionMasterLoading = false;
      transactionMasterList = transactionMasterList;
    });
  }

  Future<void> _onRefresh() async {
    await initUserById();
    await initTransactionMasterList();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(icon: Icon(Icons.arrow_back), color: config.blueColor, onPressed: (){
          Navigator.pop(context);
          }
        ),
        title: SSText(message["transactionList"], 3, color: config.blueColor),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: Colors.white),
          child: transactionMasterLoading ?
          Center(
            child: CircularProgressIndicator()
          )
          :
          transactionMasterList.length > 0 ?
          ListView.builder(
            itemCount: transactionMasterList.length,
            itemBuilder: (BuildContext context, int index){
              final item = transactionMasterList[index];
              final itemDetail = item.detailTransactionList[0];
              return Column(
                children: <Widget>[ 
                  Container(
                    padding:EdgeInsets.only(left: 5, right: 5),
                    height: 150,
                    child: InkWell(
                      onTap: (){
                        customNavigator(context, "transactionDetail/${item.id}/3");
                      },
                      child: Card(
                        elevation: 5,
                        child: Container(
                          padding:EdgeInsets.only(left: 5, right: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: ImageBox(
                                        CompanyAsset("avatar",  itemDetail.course.teacher.user.pic), 
                                        0, 
                                        fit: BoxFit.cover, 
                                        width: 35, 
                                        height: 35
                                      )
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7, 
                                    child: SSText(itemDetail.course.teacher.user.name, 7)
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: InkWell(
                                      child: SSText(message["seeDetails"], 7, color: config.blueColor),
                                      onTap: (){
                                        customNavigator(context, "transactionDetail/${item.id}/3");
                                      }
                                    )
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SSText(item.invoice, 4),
                                    SSText(itemDetail.course.title, 7),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left:10, right: 12, top: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    SSText(numberFormat(itemDetail.price, "idr"), 8, color: Colors.black),
                                    Row(
                                      children: <Widget>[
                                        SSText(item.status == 4 ? message["paid"] : item.status == 3 ? message["waitingConfirmation"] : item.status == 2 ? message["waitingPayment"] : item.status == 1 ? message["cancelled"] : "", 8, color: item.status == 4 ? config.darkGreenColor : item.status == 2 ? config.orangeColor : item.status == 1 ? Colors.red : Colors.white),
                                        SizedBox(width: 5),
                                        Icon(item.status == 4 ? Icons.check : item.status == 3 ? message["waitingConfirmation"] : item.status == 2 ? Icons.timelapse :  item.status == 1 ? Icons.close : Icons.donut_small, color: item.status == 4 ? config.darkGreenColor : item.status == 2 ? config.orangeColor : item.status == 1 ? Colors.red : Colors.white),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ),
                    ),
                  )   
                ]
              );
            }
          ) :
          PlaceholderList(type: "transaction")
        )
      )
    );
  }
}


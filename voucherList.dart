import 'package:flutter/material.dart';
import 'package:shiftsoft/models/mvoucher.dart';
import 'package:shiftsoft/resources/voucherApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';

class VoucherList extends StatefulWidget {
  final int mode, id;

  const VoucherList({Key key, this.mode, this.id}) : super(key: key);
  @override
  _VoucherListState createState() => _VoucherListState();
}

class _VoucherListState extends State<VoucherList> {

  int courseId;

  bool voucherListLoading = true;
  List<bool> voucherExpired = [];

  List<Voucher> voucherList = [];

  Map<String, String> message = new Map();

  List<String> messageList = [
    "useVoucher", "termsAndCondition", "availableVouchers", "validTill", "unavailable", "voucherDetail", "expired", "voucherExpired",
    "useNow"
  ];

  @override
  void initState() {
    // TODO: implement initState
    courseId = widget.id;
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();

    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    // await checkUser();
    if(voucherListLoading)
      await initVoucherList();
    
  }

  initVoucherList() async {
    setState(() {
      voucherListLoading = true;
    });

    voucherList = await voucherApi.getVoucherList(context);

    for(int i = 0; i < voucherList.length; i++){
      if(voucherList[i].endAt.difference(DateTime.now()).inDays <= 0){
        voucherExpired.add(true);
      }else
        voucherExpired.add(false);
    }

    setState(() {
      voucherListLoading = false;
      voucherList = voucherList;
      voucherExpired = voucherExpired;
    });
  }


  //bakal dipake terus jadi pindahin kesini sbg fungsi
  //harusnya ada parameter lg buat nampilin datanya
  _showVoucherModalSheet(Voucher item, {bool expired = false}){
    Configuration config = Configuration.of(context);
    showModalBottomSheet(
      isScrollControlled: true,
      context: context, 
      builder: (BuildContext context){
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
              borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), 
              topRight: Radius.circular(30),
              bottomLeft: Radius.zero,
              bottomRight: Radius.zero,
              )
          ),
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SSText(message["voucherDetail"], 4, color: config.blueColor),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100), color: config.lightGrayColor,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: config.whiteGrayColor),
                      iconSize: 15,
                      onPressed: (){
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              Container(
                height: 500,
                child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (BuildContext context, int index){
                    return Container(
                      padding: EdgeInsets.only(top: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Card(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 19),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: item.isDiscountPercent ? config.lightBlueColor: config.lightGreenColor),
                                  child: Image.asset(item.isDiscountPercent ? "assets/icon/voucher-discount.png": "assets/icon/voucher-refund.png",width: 10, height: 10)
                                ),
                                SizedBox(width: 17),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      decoration: BoxDecoration(color: config.lightBlueColor, borderRadius: BorderRadius.circular(10)),
                                      padding: EdgeInsets.all(6),
                                      child: SSText(expired == true ? message["expired"] : item.isDiscountPercent ? "Percent" : "Nominal", 9, size: 10, color: config.blueColor)
                                    ),
                                    SizedBox(height: 10),
                                    SSText(item.name, 4),
                                    SizedBox(height: 10),
                                    SSText(message["validTill"] + ": " + DateFormat("dd MMM yyyy").format(item.endAt), 9)
                                  ],
                                ),
                              ],
                            ),
                          )
                        ),
                        SizedBox(height: 24),
                        SSText(message["termsAndCondition"], 6),
                        SizedBox(height: 24),
                        SSText(item.description, 6)
                        ],
                      )
                    );
                  },
                ),
              ),
              Center(
                child: Container(
                  width: 372,
                  height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), color: config.blueColor),
                  child: FlatButton(
                    child: SSText(message["useVoucher"], 4, color: Colors.white),
                    onPressed: (){
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(item);
                      // customNavigator(context, "transactionConfirmation/$courseId/3", arguments: item);
                    },
                  )
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Future<Null> _refresh() async {
    await initVoucherList();
  }
  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: config.blueColor),
          onPressed: (){
            customNavigator(context, "transactionConfirmation/$courseId/3");
          },
        ),
        backgroundColor: Colors.white,
        title: SSText("Voucher", 3, color: config.blueColor)
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: Colors.white),
          child: voucherListLoading ? 
          Center(
            child: CircularProgressIndicator(),
          )
          :
          ListView.builder(
            itemCount: 1,
            itemBuilder: (BuildContext context, int index){
              return Container(
                padding: EdgeInsets.only(left: 15, right: 15, bottom: 5, top: 5),
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: SSText(message["availableVouchers"], 6),
                    ),
                    voucherList.length != 0 ?
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: voucherList.length,
                      itemBuilder: (BuildContext context, int index){  
                      final item = voucherList[index];
                      final itemExpired = voucherExpired[index];
                        return Card(
                          elevation: 5,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 19),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: itemExpired ? config.grayNonActiveColor : item.isDiscountPercent ? config.lightBlueColor : config.lightGreenColor),
                                  child: Image.asset(
                                    item.isDiscountPercent ? "assets/icon/voucher-discount.png" : "assets/icon/voucher-refund.png", color: itemExpired ? config.grayColor : item.isDiscountPercent ? config.blueColor : config.greenColor, width: 10, height: 10)
                                ),
                                SizedBox(width: 17),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      decoration: BoxDecoration(color: itemExpired ? config.grayNonActiveColor : config.lightBlueColor, borderRadius: BorderRadius.circular(10)),
                                      padding: EdgeInsets.all(6),
                                      child: SSText(
                                        itemExpired ? message["expired"] : item.isDiscountPercent ? "Percent" : "Nominal", 9, size: 10, color: itemExpired ? config.grayColor : config.blueColor)
                                    ),
                                    SizedBox(height: 10),
                                    SSText(item.name, 4),
                                    SizedBox(height: 10),
                                    SSText(itemExpired == false ? message["validTill"] + ": " + DateFormat("dd MMM yyyy").format(item.endAt) : message["voucherExpired"], 9)
                                  ],
                                ),
                                Spacer(flex: 1),
                                itemExpired == false ?
                                InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: config.blueColor),
                                    width: 70,
                                    height: 35,
                                    child: Center(
                                      child: SSText(message["useNow"], 6, color: Colors.white, align: TextAlign.center,)
                                    ),
                                  ),
                                  onTap: (){
                                    _showVoucherModalSheet(item, expired: itemExpired);
                                  }
                                ) : Container()
                              ]
                            )
                          )
                        );
                      }
                    ) : PlaceholderList(type: "voucherlist")
                  ],
                )
              );
            },
          ),
        ),
      ),
    );
  }
}
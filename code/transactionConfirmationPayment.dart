import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:shiftsoft/models/mresult.dart';
import 'package:shiftsoft/models/mtransaction.dart';
import 'package:shiftsoft/resources/transactionApi.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/SSText.dart';
// import 'package:webview_flutter/webview_flutter.dart';

class TransactionConfirmationPayment extends StatefulWidget {
  final int mode, id;
  final String paymentMethod;
  // final String paymentMethod;

  const TransactionConfirmationPayment({Key key, this.mode, this.id, this.paymentMethod}) : super(key: key);
  @override
  _TransactionConfirmationPaymentState createState() => _TransactionConfirmationPaymentState();
}

class _TransactionConfirmationPaymentState extends State<TransactionConfirmationPayment> {

  bool gettingResponse = false;
  bool refreshOnBack = false;
  bool transactionMasterStatusLoading = true;

  int price = 45000;
  int page = 1;
  int transactionMasterID = 0;

  String paymentMethod;
  String redirectUrl = "";

  Map<String, String> message = new Map();

  List<String> messageList = [
    "paymentMethod", "payNow", "cancelTransactionWeb", "exitPage", "exitPageConfirmation", "continueToPay"
  ];

  Transaction transactionMaster;

  final FlutterWebviewPlugin webviewPlugin = new FlutterWebviewPlugin();
  // final WebView webView = new WebView();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    transactionMasterID = widget.id;
    paymentMethod = widget.paymentMethod;
    print("ID transaction" + transactionMasterID.toString());
    // webviewPlugin.onUrlChanged.listen((String url){
    //   print("print dari init state: " + url);
    //   print("masuk ke initstate");
      
    //   initTransactionMasterById();
        
    //   if(transactionMaster.status == )
    //     print("hadehhhh " + transactionMaster.status.toString());
    //     customNavigator(context, "transactionDetail/$transactionMasterID/3");
    // });
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();
    
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    // if(transactionListLoading)
    //   initTransactionList();
    // await checkUser();
  }

  Future<bool> willPopScope() async{
      
    return false;
  }  

  void getResponse(String method, int transactionMasterid) async {
    setState(() {
      gettingResponse = true;
    });
    redirectUrl = await transactionApi.getLinkResponse(context, transactionMasterid, method);
    print("channel : " + method);
    print("coba ini linknya: " + redirectUrl.toString());

    setState(() {
      gettingResponse = false;
      redirectUrl = redirectUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    if(redirectUrl == ""){
      getResponse(paymentMethod, transactionMasterID);
    }else{

    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: SSText("Confirmation Payment", 4, color: config.blueColor),
        leading: IconButton(icon: Icon(Icons.arrow_back), color: config.blueColor, onPressed: (){
          webviewPlugin.hide();
          return showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context){
              return Stack(
                children: [
                  AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Image.asset("assets/illustration/leave-web.png"),
                        SizedBox(height: 20),
                        SSText(message["exitPageConfirmation"], 4, fontWeight: FontWeight.bold),
                        SizedBox(height: 20),
                        SSText(message["cancelTransactionWeb"], 6, align: TextAlign.center),
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(color: config.blueColor, borderRadius: BorderRadius.circular(10)),
                          width: MediaQuery.of(context).size.width,
                          child: FlatButton(
                            child: SSText(message["continueToPay"], 4, color: Colors.white),onPressed: (){
                              Navigator.pop(context);
                              webviewPlugin.show();
                            },
                          )
                        ),
                        Container(
                          // decoration: BoxDecoration(color: config.blueColor),
                          width: MediaQuery.of(context).size.width,
                          child: FlatButton(
                            child: SSText(message["exitPage"], 4),
                            onPressed: (){
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          )
                        )
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 55),
                  //   child: Align(
                  //     alignment: Alignment.topCenter,
                  //     child: Image.asset("assets/illustration/leave-web.png", height: 175, width: 175)
                  //   ),
                  // ),
                ]
              );
            }
          );
        },)
      ),
      body: WillPopScope(
        onWillPop: willPopScope,
        child: Container(
          child: gettingResponse ? 
          Center(
            child: CircularProgressIndicator()
          ) 
          :
          // WebView(
          //   javascriptMode: JavascriptMode.unrestricted,
          //   initialUrl: redirectUrl,  
          // )

          // bingung antara menggunakan dua widget ini atas bawah ni
          WebviewScaffold(
            // withZoom : true,
            useWideViewPort: true,
            withJavascript: true,
            url: redirectUrl == "" ? "404" : redirectUrl,
            javascriptChannels: Set.from([
              JavascriptChannel(
                name: 'MessageInvoker', 
                onMessageReceived: (JavascriptMessage message){
                  printHelp(message.message);
                  Navigator.pop(context);
                }
              )
            ]),
          ),
        ),
      )
    );


    // katanya nanti di pake bawah ni, jadi biarin aja
    
    // print(paymentMethod);
    // return Scaffold(
    //   appBar: AppBar(
    //     backgroundColor: Colors.white,
    //     elevation: 0,
    //     title: SSText(message["paymentMethod"], 4, color: config.blueColor),
    //     leading: IconButton(icon: Icon(Icons.arrow_back, color: config.blueColor), 
    //     onPressed: (){
    //       Navigator.pop(context);
    //     }),
    //   ),
    //   body: Container(
    //     decoration: BoxDecoration(color: Colors.white),
    //     padding: EdgeInsets.all(20),
    //     child: Column(
    //       children: <Widget>[
    //         Container(
    //           width: 378,
    //           height: 82,
    //           child: Card(
    //             child: Row(
    //               children: <Widget>[
    //                 Expanded(flex:2, child: Image.asset("assets/icon/bca_logo.png", height: 16, width: 52 )), 
    //                 Expanded(
    //                   flex: 3,
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     mainAxisAlignment: MainAxisAlignment.center,
    //                     children: <Widget>[
    //                       SSText("BCA Virtual Account", 8),
    //                       SizedBox(height: 13),
    //                       SSText(numberFormat(price, 'idr'), 6, color: config.blueColor)
    //                       // SSText(price.toString(), 6, color: config.blueColor)
    //                   ]),
    //                 )
    //             ]),  
    //           ),
    //         ),
    //         SizedBox(height: 40),
    //         Row(
    //           children: <Widget>[
    //             Container(
    //               height: 9, 
    //               width: 9, 
    //               decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.circular(100)
    //               )
    //             ),
    //             SizedBox(width: 25),
    //             Flexible(child: SSText("Transaksi ini akan otomatis menggantikan tagihan BCA Virtual Account yang belum dibayar.", 8))
    //           ]
    //         ),
    //         SizedBox(height: 20),
    //         Row(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: <Widget>[
    //             Container(
    //               height: 9, 
    //               width: 9, 
    //               decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.circular(100)
    //               )
    //             ),
    //             SizedBox(width: 25),
    //             Flexible(child: SSText("Dapatkan kode pembayaran setelah klik 'Bayar'.", 8))
    //           ]
    //         )
    //       ]
    //     )
    //   ),
    //   bottomNavigationBar: Container(
    //     width: MediaQuery.of(context).size.width,
    //     decoration: BoxDecoration(color: config.blueColor),
    //     child: FlatButton(
    //       child: SSText(message["payNow"], 5, color: config.whiteGrayColor),
    //       onPressed: () async {
    //         // showDialog(
    //         //   context: context,
    //         //   builder: (BuildContext context){
    //         //     return AlertDialog(
    //         //       content: Row(
    //         //         children: <Widget>[
    //         //           CircularProgressIndicator(),
    //         //           SizedBox(width: 15),
    //         //           SSText("Purchasing...", 4)
    //         //         ],
    //         //       ),
    //         //     );
    //         //   }
    //         // );
    //         // Navigator.pop(context);
    //         // Result result = await transactionApi.createTransaction(
    //         //   // context, "1", widget.paymentMethod
    //         // );
    //         // if(result.success == 1){
    //         //   showDialog(context: context, builder: (BuildContext context){
    //         //     return AlertDialog(
    //         //       content: Row(
    //         //         children: <Widget>[
    //         //           Icon(Icons.check, color: Colors.green),
    //         //           SizedBox(width: 15),
    //         //           SSText("Thank you for purchasing!", 4)
    //         //           ]
    //         //         )
    //         //       );
    //         //     }
    //         //   );
    //         //   Navigator.pop(context);
    //         // }
    //       },
    //     )
    //   ),
    // );
  }
}
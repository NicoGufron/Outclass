// packages
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shiftsoft/screens/subscriptionPlanList.dart';
import 'package:shiftsoft/tools/functions.dart';
import 'package:shiftsoft/widgets/imageBox.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

// screens
import 'package:shiftsoft/screens/enrichmentBalanceHistoryPage.dart';
import 'package:shiftsoft/screens/login.dart';

// widgets
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/starRating.dart';

// resources
import 'package:shiftsoft/resources/pointApi.dart';
import 'package:shiftsoft/resources/teacherApi.dart';
import 'package:shiftsoft/resources/transactionApi.dart';
import 'package:shiftsoft/resources/userApi.dart';

// models
import 'package:shiftsoft/models/muser.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';
import 'package:shiftsoft/models/mteacher.dart';
import 'package:shiftsoft/models/mtransaction.dart';

// Future
// refresh indicator juga refresh saldo user
// Future

class EnrichmentProfilePage extends StatefulWidget {
  final int mode, id;

  EnrichmentProfilePage({Key key, this.mode, this.id}) : super(key: key);

  @override
  _EnrichmentProfilePageState createState() => _EnrichmentProfilePageState();
}

class _EnrichmentProfilePageState extends State<EnrichmentProfilePage> {

  int id;
  int mCurrentIndex = 2;

  bool isExit = false;
  bool teacherLoading = true;
  bool userLoading = true;
  bool transactionMasterLoading = true;
  bool isStudent = false, isTeacher = false;

  Map<String, String> message = new Map();

  List<String> messageList = [
    "transactionHistory",
    "profile",
    "income",
    "alert",
    "logOutWarning",
    "paymentHistory",
    "seeMore",
    "balance", 
    "cancelled", 
    "paid", 
    "waitingConfirmation", 
    "myReviewList",
    "browse",
    "account",
    "studySchedule",
    "upcomingSessions",
    "registerAsTuton",
    "verifyDataTuton",
    "waitingPayment"
  ];
  List<Transaction> transactionList;

  List<Teacher> teacher;
  User user;

  @override
  void initState() {
    super.initState();
    id = widget.id;
    print("ID: " + id.toString());
  }

  void didChangeDependencies() async {
    super.didChangeDependencies();
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkUser();

      if (transactionMasterLoading) 
        initTransactionMasterList();

      if (userLoading)
       initUserById();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  checkUser() async {
    var tempIsStudent = await checkPermission(
        context, "master.member.role", "BackendRole.IsStudent",
        mustLogin: true);
    var tempIsTeacher = await checkPermission(
        context, "master.member.role", "BackendRole.IsTeacher",
        mustLogin: true);

    isStudent = tempIsStudent ? true : false;
    isTeacher = tempIsTeacher ? true : false;

    setState(() {
      isStudent = isStudent;
      isTeacher = isTeacher;
    });
  }

  initTransactionMasterList() async {
    Configuration config = Configuration.of(context);
    setState(() {
      transactionMasterLoading = true;
    });

    transactionList = await transactionApi.getTransactionMasterList(context, parameter:"filtersArr[0][]=user_id|=|" + config.user.id.toString()+ "|god&&order=created_at-desc");

    setState(() {
      transactionMasterLoading = false;
      transactionList = transactionList;
    });
  }

  initUserById() async {
    Configuration config = Configuration.of(context);
    setState(() {
      userLoading = true;
    });

    // if (isStudent)
    //   user = await userApi.getUser(context, config.user.id);
    // else if (isTeacher)
      // teacher = await teacherApi.getTeacherById(context, id, parameter: "with[0]=User");
    teacher = await teacherApi.getTeacherList(context, parameter: "filtersArr[0][]=user_id|=|"+id.toString()+"|god");

    setState(() {
      userLoading = false;
      // user = user;
      teacher = teacher;
    });
  }

  Future<Null> _refresh() async {
    initTransactionMasterList();
    initUserById();
  }
  
  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SSText(mCurrentIndex == 2 ? message["profile"] : "", 3, color: config.blueColor),
        automaticallyImplyLeading: false,
        actions: <Widget>[
            IconButton(
              icon: Image.asset("assets/icon/search-white.png", width: 23.5, height: 23),
              onPressed: () {
                customNavigator(context, "enrichmentSearch");
              },
            ),
            // IconButton(
            //   icon: Image.asset("assets/icon/bookmark-white.png", width: 16, height: 23),
            //   onPressed: () {
            //     customNavigator(context, "bookmarkList");
            //   }
            // ),
            IconButton(
              icon: Image.asset("assets/icon/notification-white.png", width: 23.4, height: 25.5),
              onPressed: () {
                customNavigator(context, "notificationList");
            }
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: userLoading && teacherLoading ? 
          Center(
            child: CircularProgressIndicator(),
          )
          : 
          ListView.builder(
          itemCount: 1,
          itemBuilder: (context, int index) {
            final itemTeacher = teacher;
            return Container(
              decoration: BoxDecoration(color: Colors.white),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: ImageBox(
                            CompanyAsset("avatar", config.user.pic), 
                            0, 
                            fit: BoxFit.cover, 
                            width: 90, 
                            height: 90
                          )
                        ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SSText(config.user.name, 1, size: 24, color: Colors.black),
                            isTeacher && itemTeacher.isNotEmpty && itemTeacher[0].isVerified == true ? 
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: <Widget>[
                                  StarRating(
                                    rating: itemTeacher[0].rating.toDouble(),
                                    size: 12,
                                    color: config.orangeColor,
                                  ),
                                  Padding(
                                    padding:const EdgeInsets.only(left: 8),
                                    child: SSText( "(" + double.parse(itemTeacher[0].rating.toString()).toStringAsFixed(1) + ")",8,color: config.orangeColor),
                                  )
                                ],
                              ),
                            )
                            : 
                            isTeacher && itemTeacher.isNotEmpty ?
                            Container(
                              padding: EdgeInsets.only(top: 10),
                              child: SSText(itemTeacher[0].isVerified == false ? message["verifyDataTuton"] : "", 6),
                            )
                            :
                            isTeacher && itemTeacher.isEmpty ?
                            Container(
                              padding: EdgeInsets.only(top: 10),
                              child: SSText(message["registerAsTuton"], 6),
                            ) :
                            SizedBox(height: 10),
                            isTeacher && teacher.isNotEmpty && itemTeacher[0].isVerified == true ? 
                            InkWell(
                              child: Container(
                                width: 120,
                                padding: EdgeInsets.all(8),
                                child: Center(
                                  child: SSText(message["myReviewList"], 8,color: config.blueColor),
                                ),
                                decoration: BoxDecoration(borderRadius:BorderRadius.circular(5),color: config.lightBlueColor),
                              ),
                              onTap: () {
                                customNavigator(context,"enrichmentReviewTeacherList/${itemTeacher[0].id}/3",);
                              }
                            )
                            : Container()
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                //   Card(
                //     child: InkWell(
                //     onTap: () {
                //       // Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionPlanList(mode: 1)));
                //       customNavigator(context, "subscriptionPlanList/0/1");
                //     },
                //     child: Padding(
                //       padding: EdgeInsets.all(15),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: <Widget>[
                //           Row(
                //             children: <Widget>[
                //               ImageIcon(AssetImage("assets/icon/account-balance-wallet.png"),size: 16),
                //               SizedBox(width: 10),
                //               Text('Subscription List'),
                //             ],
                //           ),
                //         ],
                //       ),
                //     ),
                //   )
                // ),
                // SizedBox(height: 10),
                Card(
                  child: InkWell(
                  onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) =>EnrichmentBalanceHistoryPage(userModel: teacher.user, mode: 3)));
                        customNavigator(context, "enrichmentBalanceHistoryPage/${config.user.id}/3", arguments: config.user);
                     },
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                ImageIcon(AssetImage("assets/icon/account-balance-wallet.png"),size: 16),
                                SizedBox(width: 10),
                                Text(message['balance']),
                              ],
                            ),
                            SSText(numberFormat(config.user.balance, ""), 4,color: config.blueColor)
                          ],
                        ),
                      ),
                    )
                  ),
                  SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SSText(message["paymentHistory"], 2, color: config.blueColor),
                        InkWell(
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Center(
                              child: SSText(message["seeMore"], 8,color: config.blueColor),
                            ),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),color: config.lightBlueColor),
                          ),
                          onTap: () {
                            customNavigator(
                              context,
                              "transactionMaster",
                            );
                          }
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                        // width: MediaQuery.of(context).size.width * 0.8,
                        // height: MediaQuery.of(context).size.height * 0.8,
                      child: transactionMasterLoading ? 
                      Center(
                        child: CircularProgressIndicator()
                      )
                      : 
                      transactionList.length > 0 ? 
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: transactionList.length < 5 ? transactionList.length : 5,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, int index) {
                          final item = transactionList[index];
                          return InkWell(
                            onTap: (){
                              customNavigator(context, "transactionDetail/${item.id}/3");
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(height: 5),
                                SSText(numberFormat(item.totalPrice, ""),8),
                                Row(
                                  mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:CrossAxisAlignment.start,
                                        children: <Widget>[
                                          SSText(item.invoice, 8,color:Colors.black),
                                          SizedBox(height: 8),
                                          SSText(DateFormat("EEEE, dd-MMM-yyyy").format(item.createdAt),9)
                                        ],
                                      ),
                                    ),
                                    item.status == 4? 
                                    Column(
                                      crossAxisAlignment:CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Icon(Icons.check,color: config.greenColor,),
                                        SSText(message["paid"], 8,color: config.greenColor)
                                      ],
                                    )
                                    : item.status == 3 ? 
                                    Column(
                                      crossAxisAlignment:CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Icon(Icons.info,color: config.lighterGrayColor),
                                        // CircularProgressIndicator(value: 8),
                                        SizedBox(width: 5),
                                        SSText(message["waitingConfirmation"],8,color: config.lighterGrayColor),
                                      ],
                                    )
                                    : item.status == 2 ? 
                                    Column(
                                      crossAxisAlignment:CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Icon(Icons.timelapse,color: config.orangeColor),
                                        SizedBox(width:5),
                                        SSText(message["waitingPayment"],8,color: config.orangeColor),
                                      ],
                                    )
                                    : item.status == 1 ? 
                                    Column(
                                      crossAxisAlignment:CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Icon(Icons.close,color:Colors.red),
                                          SSText(message["cancelled"],8,color:Colors.red)
                                        ],
                                      )
                                    : Container(),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Divider(thickness: 1.5,color: config.blueColor)
                              ],
                            ),
                          );
                        }
                      )
                      : 
                      PlaceholderList(type: "transaction")
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
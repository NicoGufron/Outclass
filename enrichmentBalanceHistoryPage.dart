// packages
import 'package:flutter/material.dart';
import 'package:shiftsoft/resources/balanceApi.dart';
import 'package:shiftsoft/resources/userAccountApi.dart';
import 'package:shiftsoft/screens/login.dart';
import 'package:shiftsoft/settings/companies/active/configuration.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:shiftsoft/tools/functions.dart';

// widgets
import 'package:shiftsoft/widgets/OCTextField.dart';
import 'package:shiftsoft/widgets/OCDropdown.dart';
import 'package:shiftsoft/widgets/SSText.dart';
import 'package:shiftsoft/widgets/button.dart';

// models
import 'package:shiftsoft/models/mbalance.dart';
import 'package:shiftsoft/models/muser.dart';
import 'package:shiftsoft/models/museraccount.dart';
import 'package:shiftsoft/widgets/placeholderList.dart';

// Future
// refresh indicator juga refresh saldo user
// Future

class EnrichmentBalanceHistoryPage extends StatefulWidget {
  final User userModel;
  final int mode, id;

  EnrichmentBalanceHistoryPage({
    Key key,
    this.userModel,
    this.mode,
    this.id
  }):super(key:key);

  @override
  _EnrichmentBalanceHistoryPageState createState() => _EnrichmentBalanceHistoryPageState();
}

class _EnrichmentBalanceHistoryPageState extends State<EnrichmentBalanceHistoryPage> {
  List<Widget> listMyWidget = List();

  List<String> bankList = [];
  String selectedBank;
  bool userAccountLoading = true;

  List<DropdownMenuItem<String>> bankDropdownList = [];

  bool enrichmentBalanceProfilePageLoading = false;
  bool isLoading = false;
  bool filterApplied = false;
  ScrollController _scrollController;
  int page = 1;

  // utk history saldo user
  List<Balance> _balanceList;
  User user;

  // utk daftar rekening bank user
  List<UserAccount> _userAccountList;
  
  DateTime _dateStart, _dateEnd;
  String dateStart, dateEnd;
  var temp; 

  TextEditingController balanceController = TextEditingController();
  FocusNode balanceFocusNode = FocusNode();

  Map<String, String> message = new Map();
  List<String> messageList = [
    "income", "transactionHistory", "startDate", "endDate", 
    "withdrawBalance", "empty", "addAccount", "destinationAccount", 
    "bankAccount", "withdrawBalanceTo", "addNewAccount", "waitingConfirmation", "cancelled",
    "balanceWithdrawSuccess"
  ];

  void didChangeDependencies() async {
    super.didChangeDependencies();
    messageList.map((item) {
      message[item] = messages(context, item.split(","));
    }).toList();
  }

 @override
  void initState() {
    user = widget.userModel;
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _dateStart = _dateEnd = DateTime.now();
    dateStart = dateEnd = DateFormat('EE, dd MMM yyyy').format(DateTime.now()).toString();

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      initBalanceList();
      initUserAccountList();
    });
  }

  createBalanceWithdrawal(int value, String userAccountId) async {
    // Configuration config = Configuration.of(context);

    Alert(context: context, loading: true);
    UserAccount temp = _userAccountList.firstWhere((item) => item.id.toString() == userAccountId);
    String bankName = UserAccountTypeMap[temp.type][0];
    String title = "${message["withdrawBalanceTo"]} $bankName";
    String desc = "${message["withdrawBalanceTo"]} $bankName";

    var result = await balanceApi.createBalanceWithdrawal(context, userAccountId, -value, title, desc);
    Navigator.of(context).pop();

    String contentMsg = '';
    //convert dynamic to List<String>
    if(result.message is List<dynamic>){
      List<String> msg = [...result.message];
      contentMsg = msg.join('\n');
    }else{
      contentMsg = result.message;
    }
    if(result.success == 1){
      Alert(
        context: context,
        type: "success",
        title: message["success"],
        content: SSText(contentMsg, 5),
        cancel: false,
        disableBackButton: true,
        defaultAction: () {
          Navigator.of(context).pop(true);
          _refresh();
        },
      );
    }else{
      Alert(
        context: context,
        type: "error",
        title: message["error"],
        content: SSText(contentMsg, 5),
        cancel: false,
        disableBackButton: true,
        willPopAction: (){
          balanceFocusNode.unfocus();
        }
      );
    }
  }

  initUserAccountList() async {
    Configuration config = Configuration.of(context);
    setState(() {
      bankList = [
        "-"
      ];
      bankDropdownList = [];
      userAccountLoading = true;
    });

    _userAccountList = await userAccountApi.getUserAccountList(context, config.user.id);

    if(_userAccountList == null){
      _userAccountList = [];
      bankDropdownList = [];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context){
          return AlertDialog(
            title: Text("Alert"),
            content: Text("Login Gagal"),
            actions: <Widget>[
              FlatButton(
                key: Key("ok"),
                child: Text("OK"),
                onPressed: (){
                  return Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                },
              )
            ],
          );
        }
      );
    } else {
      _userAccountList.map((item){
        String bankName = UserAccountTypeMap[item.type][0];
        bankDropdownList.add(
          DropdownMenuItem(
            value: item.id.toString(),
            child: SSText('${bankName} - ${item.number.toString()}', 6, color: config.blueColor),
          )
        );
      }).toList();
      setState(() {
        if(_userAccountList.isNotEmpty)
          selectedBank = _userAccountList[0].id.toString();
        else
          selectedBank = '0';
      });
    }
    setState(() {
      selectedBank = selectedBank;
      _userAccountList = _userAccountList;
      bankDropdownList = bankDropdownList;
      userAccountLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    balanceController.dispose();
    balanceFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
  }
  
  loadMore([String filter=""]) async {
    Configuration config = Configuration.of(context);

    if (!isLoading) {
      setState(() {
        isLoading = true;
      });
      
      String parameter = "order[]=created_at-desc";
      _balanceList.addAll(await balanceApi.getBalanceList(context, config.user.id, page, parameter));
      if(_balanceList == null){
        _balanceList = [];
        listMyWidget = [];
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context){
            return AlertDialog(
              title: Text("Alert"),
              content: Text("Login Gagal"),
              actions: <Widget>[
                FlatButton(
                  key: Key("ok"),
                  child: Text("OK"),
                  onPressed: (){
                    return Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                  },
                )
              ],
            );
          }
        );
      }else{
        await makeAnimation();
        listMyWidget.clear();
        _balanceList.map((item){
          listMyWidget.add(
            createBalanceListWidget(config, item)
          );
        }).toList();
        page++;
      }

      setState(() {
        listMyWidget = listMyWidget;
        _balanceList = _balanceList;
        isLoading = false;
        page = page;
      });
    }
  }
  
  initBalanceList([String filter=""]) async {
    Configuration config = Configuration.of(context);

    setState(() {
      enrichmentBalanceProfilePageLoading = true;
      listMyWidget.clear();
      page = 1;
    });
    
    String parameter = "$filter&order[]=created_at-desc";
    _balanceList = await balanceApi.getBalanceList(context, config.user.id, page, parameter);
    if(_balanceList == null){
      _balanceList = [];
      listMyWidget = [];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context){
          return AlertDialog(
            title: Text("Alert"),
            content: Text("Login Gagal"),
            actions: <Widget>[
              FlatButton(
                key: Key("ok"),
                child: Text("OK"),
                onPressed: (){
                  return Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                },
              )
            ],
          );
        }
      );
    }else{
      page++;
      if(_balanceList.length+1 !=1){
        _balanceList.map((item){
          listMyWidget.add(
            createBalanceListWidget(config, item)
          );
        }).toList();
        listMyWidget.add(
          Center(
            child: Opacity(
              opacity: isLoading ? 1.0 : 0.0,
              child: CircularProgressIndicator(),
            ),
          )
        );
      }else{
        listMyWidget.add(
          PlaceholderList(type: "balance",),
        );
      }
    }

    setState(() {
      listMyWidget = listMyWidget;
      _balanceList = _balanceList;
      enrichmentBalanceProfilePageLoading = false;
      page = page;
    });
  }

  Widget createBalanceListWidget(Configuration config, Balance item){
    Color colorText, colorIcon;
    // status:
    // 0 = menunggu konfirmasi
    // 1 = batal
    // 2 = berhasil tarik saldo
    if(item.status == 0){
      colorText = config.grayNonActiveColor;
      colorIcon = config.orangeColor;
    }else if(item.status == 1){
      colorText = Colors.red;
      colorIcon = Colors.red;
    }else if(item.status == 2){
      colorText = Colors.green;
      colorIcon = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SSText(
                  '${item.value.toString()}', 
                  5, 
                  color: colorText
                ),
                SizedBox(height: 5,),
                SSText(item.title, 5, maxLines: 2,),
                SizedBox(height: 5,),
                SSText(
                  '${item.createdAt.toString().substring(0, 10)} ${item.createdAt.toString().substring(11, 19)}', 
                  8, 
                  color: config.lightGrayColor
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if(item.status == 0) ...[
                Icon(Icons.info, color: colorIcon),
                SSText(
                  message['waitingConfirmation'], 
                  8,
                  color: colorIcon,
                ),
              ] else if(item.status == 1) ...[
                Icon(Icons.close, color: colorIcon),
                SSText(
                  message['cancelled'], 
                  8,
                  color: colorIcon,
                ),
              ] else if(item.status == 2) ...[
                Icon(Icons.check, color: colorIcon),
                SSText(
                  message['balanceWithdrawSuccess'], 
                  8,
                  color: colorIcon,
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Configuration config = Configuration.of(context);

    return Scaffold(
      appBar: AppBar(
        title: SSText(message["income"], 4, color: config.blueColor),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: config.blueColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15,40,15,0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(child: Image(image: AssetImage("assets/icon/saldo-illust.png"),height: 65, width: 65)),
              SizedBox(height: 10,),
              Center(child: SSText(message["income"], 8, fontWeight: FontWeight.w500,)),
              SizedBox(height: 5,),
              Center(child: SSText(user.balance.toString(), 1, size: 24, color: config.grayColor,)),
              SizedBox(height: 15,),
              Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: ()async{
                          await customNavigator(context, "userAccountList");
                          initUserAccountList();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(width: 1, color: config.grayNonActiveColor)
                            )
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Center(child: SSText(message["bankAccount"], 6, color: config.blueColor)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: (){
                          buildShowDialog(context, config);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Center(child: SSText(message["withdrawBalance"], 6, color: config.blueColor)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(message["transactionHistory"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 15),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: (){_selectDateStart(context);},
                      child: Container(
                        decoration: ShapeDecoration(
                          shape: UnderlineInputBorder()
                        ),
                        child: Container(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Text("$dateStart"),
                        ),
                      )
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(child: Text("-")),
                  ),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: (){_selectDateEnd(context);},
                      child: Container(
                        decoration: ShapeDecoration(
                          shape: UnderlineInputBorder()
                        ),
                        child: Container(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Text("$dateEnd"),
                        ),
                      )
                    )
                  ),
                ],
              ),
              SizedBox(height: 30,),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: enrichmentBalanceProfilePageLoading ?
                  CreateShimmers()
                  :
                  CustomScrollView(
                    controller: _scrollController,
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) => 
                          Column(
                            children: listMyWidget
                          ),
                          childCount: 1,
                        )
                      )
                    ],
                  )
                ),
              )
            ],
          ),
        )
      ),
    );
  }

  Future<Null> _refresh() async {
    String filter = '';
    if(filterApplied){
      String dateFilter = '${(DateFormat('yyyy-MM-dd').format(_dateStart)).toString()}, ${(DateFormat('yyyy-MM-dd').format(_dateEnd)).toString()}';
      filter = "filters[]=created_at|between|$dateFilter 23:59:59|and";
    }
    page = 1;
    await initBalanceList(filter);
    await initUserAccountList();
    return null;
  }

  Future buildShowDialog(BuildContext context, Configuration config) {
    return showDialog(
      context: context,
      builder: (context){
        return StatefulBuilder(
          builder: (context, setState){
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              content: Stack(
                overflow: Overflow.visible,
                children: <Widget>[
                  Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(8),
                          child: Container(
                            child: SSText(message["withdrawBalance"], 1, color: config.blueColor),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 8, right: 8, top: 10),
                          child: Container(
                            child: SSText(message["destinationAccount"], 6),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          child: OCDropdown(
                            loading: userAccountLoading,
                            color: config.blueColor,
                            hintText: "",
                            value: selectedBank,
                            items: bankDropdownList,
                            ifEmpty: message["empty"],
                            onChanged: (selected){
                              setState(() {
                                selectedBank = selected;
                              });
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.5),
                          ),
                          padding: EdgeInsets.all(8),
                          child: OCTextField(
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.number,
                            prefixIcon: Padding(child: SSText('Rp', 6), padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10)),
                            controller: balanceController,
                            focusNode: balanceFocusNode,
                            maxLines: 1,
                            hintText: '0',
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Button(
                            borderRadius: 15,
                            backgroundColor: config.orangeColor,
                            child: Center(child: SSText(message["withdrawBalance"], 4, color: Colors.white)),
                            onTap: (){
                              // selectedBank -> UserAccountID
                              int value = int.tryParse(balanceController.text) ?? 0;
                              if(selectedBank == '0'){
                                Alert(
                                  context: context,
                                  title: message["warning"],
                                  content: SSText(message['addNewAccount'], 5),
                                  cancel: false,
                                  disableBackButton: true,
                                  defaultAction: () {
                                  }
                                );
                              }else{
                                createBalanceWithdrawal(value, selectedBank);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    ).then((onValue){
      setState(() {
        balanceController.text = '';
      });
    });
  }
  
  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context, 
      initialDate: _dateStart, 
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if(picked != null){
      setState(() {
        _dateStart = picked;
        filterApplied = true;
        temp = picked.toString();
        temp = temp.split(" ");
        dateStart = (DateFormat('EE, dd MMM yyyy').format(picked)).toString();
        if(_dateStart.isAfter(_dateEnd)){
          _dateEnd = _dateStart;
          dateEnd = (DateFormat('EE, dd MMM yyyy').format(picked)).toString();
        }
      });
      String dateFilter = '${(DateFormat('yyyy-MM-dd').format(_dateStart.toUtc())).toString()}, ${(DateFormat('yyyy-MM-dd').format(_dateEnd.toUtc())).toString()}';
      String filter = "filtersArr[1][0]=created_at|between|$dateFilter 23:59:59";
      initBalanceList(filter);
    }
  }

  Future<void> _selectDateEnd(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context, 
      initialDate: _dateEnd, 
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if(picked != null){
      setState(() {
        filterApplied = true;
        _dateEnd = picked;
        temp = picked.toString();
        temp = temp.split(" ");
        dateEnd = (DateFormat('EE, dd MMM yyyy').format(picked)).toString();
        if(_dateEnd.isBefore(_dateStart)){
          _dateStart = _dateEnd;
          dateStart = (DateFormat('EE, dd MMM yyyy').format(picked)).toString();
        }
      });
      String dateFilter = '${(DateFormat('yyyy-MM-dd').format(_dateStart.toUtc())).toString()}, ${(DateFormat('yyyy-MM-dd').format(_dateEnd.toUtc())).toString()}';
      String filter = "filtersArr[1][]=created_at|between|$dateFilter 23:59:59|and";
      initBalanceList(filter);
    }
  }
  _scrollListener(){
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
      if(_balanceList.length%c.apiLimit == 0){
        loadMore();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  makeAnimation() async {
    final offsetFromBottom = _scrollController.position.maxScrollExtent - _scrollController.offset;
    if (offsetFromBottom < 50) {
      await _scrollController.animateTo(
        _scrollController.offset - (50 - offsetFromBottom),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

}

class CreateShimmers extends StatelessWidget {
  const CreateShimmers({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) => 
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200],
                    highlightColor: Colors.grey[350],
                    period: Duration(milliseconds: 800),
                    child: Container(
                      width: 150,
                      height: 20,
                      color: Colors.grey[200]
                    )
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[200],
                    highlightColor: Colors.grey[350],
                    period: Duration(milliseconds: 800),
                    child: Container(
                      width: 100,
                      height: 20,
                      color: Colors.grey[200]
                    )
                  )
                ],
              ),
            ),
            childCount: 10
          )
        )
      ],
    );
  }
}

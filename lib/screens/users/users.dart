import 'package:e_doctor/constants/colors.dart';
import 'package:e_doctor/constants/gradients.dart';
import 'package:e_doctor/screens/auth/components/auth_views.dart';
import 'package:e_doctor/screens/users/model.dart';
import 'package:e_doctor/screens/users/users_gql.dart';
import 'package:e_doctor/state/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';

class UserListScreen extends StatefulWidget {
  UserListScreen({this.covid = false});
  final bool covid;
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<String> selectionList = [];
  String groupName = "";
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget body() {
    return Column(
      children: <Widget>[
        headerContainerComponent(),
        searchBarComponent(),
        queryComponent()
      ],
    );
  }

  Widget headerContainerComponent() {
    final group = selectionList.length > 0;
    return Container(
      padding: EdgeInsets.only(left: 25, right: 25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black.withOpacity(.1),
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(margin: EdgeInsets.only(top: 40)),
          gradientTextComponent(
            ORANGE_GRADIENT,
            'Chat with a doctor/nutritionist',
            size: 24,
            weight: FontWeight.w500,
          ),
          Container(margin: EdgeInsets.only(top: 10)),
          Text(
            'Please write the reason for this check-up & report if you suffer from any of COVID-19 symptoms',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
          Container(margin: EdgeInsets.only(top: 15)),
          if (group) ...groupNameInputComponent(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              flatButtonComponent("CANCEL", () => Navigator.pop(context)),
              newChatMutationComponent()
            ],
          ),
          Container(margin: EdgeInsets.only(top: 15)),
        ],
      ),
    );
  }

  List<Widget> groupNameInputComponent() {
    return [
      Container(margin: EdgeInsets.only(top: 10)),
      Container(
        padding: EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
          color: LIGHT_GREY_COLOR,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          style: TextStyle(color: BLACK_COLOR),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Ex: Fever/Cough/Headache...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (val) {
            setState(() {
              groupName = val;
            });
          },
        ),
      ),
      Container(margin: EdgeInsets.only(top: 10))
    ];
  }

  Widget flatButtonComponent(
    String text,
    VoidCallback onPressed, {
    bool primary = false,
  }) {
    return FlatButton(
      textColor: primary ? DARK_ORANGE : null,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget newChatMutationComponent() {
    final appState = Provider.of<AppState>(context);

    return Mutation(
      options: MutationOptions(
        documentNode: gql(createChatMutation),
        update: (Cache cache, QueryResult result) => cache,
        onCompleted: (dynamic result) {
          print('-----created-----conversation');
          // print(result);
          // print(result.exception && result.exception);
          Navigator.pop(context);
        },
      ),
      builder: (RunMutation run, QueryResult result) {
        print("------printing------selectionList");
        print(selectionList);
        return flatButtonComponent(
          "START CHAT",
          selectionList.length == 0
              ? null
              : () {
                    run({'participantIds': selectionList, 'name': 'test', 'text': groupName});
                },
          primary: true,
        );
      },
    );
  }

  Widget searchBarComponent() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 10, 10),
      child: TextField(
        cursorColor: DARK_ORANGE,
        onChanged: (val) {
          setState(() {
            searchText = val;
          });
        },
        decoration: InputDecoration(
          hintText: "Search",
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.search,
            color: DARK_ORANGE,
          ),
        ),
      ),
    );
  }

  Widget queryComponent() {
    final appState = Provider.of<AppState>(context);
    print("----printing----uuu");
    print(appState.token);

    var users;
    return Query(
      options: QueryOptions(
        documentNode: gql(getUserQuery),
        pollInterval: 100,
      ),
      builder: (QueryResult result, { VoidCallback refetch, FetchMore fetchMore }) {
        if(result.loading) return CupertinoActivityIndicator();
        if (result.data != null && !result.loading) {
          print("----printing----result.data");
          print(result.data);

          List<dynamic> userData = result.data['users'] as List<dynamic>;
          users = UsersModel.fromJson(userData);
          return userListComponent(users);
        }

        return Container();
      },
    );
  }

  Widget userListComponent(UsersModel list) {
    final filteredList = searchItem(list);
    return Expanded(
      child: ListView.separated(
        separatorBuilder: (ctx, i) => Divider(height: 20),
        padding: EdgeInsets.all(20),
        physics: BouncingScrollPhysics(),
        itemCount: filteredList.length,
        itemBuilder: (context, index) => userItemComponent(filteredList[index]),
      ),
    );
  }

  List<UserModel> searchItem(UsersModel list) {
    final usersList = list.users;
    if (searchText == "") return usersList;

    print("---here--- searchitem");
    print(searchItem);

    final filteredList = list.users.where(
      (user) => user.username.toLowerCase().contains(
            searchText.toLowerCase(),
          ),
    );
    return filteredList.toList();
  }

  Widget userItemComponent(UserModel user) {
    bool itemSelected = selectionList.indexOf(user.id) != -1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          user.username,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: itemSelected ? DARK_ORANGE : null,
          ),
        ),
        Checkbox(
          checkColor: DARK_ORANGE,
          activeColor: PALE_ORANGE.withOpacity(.3),
          value: itemSelected,
          onChanged: (value) {
            setState(() {
              value
                  ? selectionList.add(user.id)
                  : selectionList.remove(user.id);
            });
          },
        )
      ],
    );
  }
}
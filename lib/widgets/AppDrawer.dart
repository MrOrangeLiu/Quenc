import 'package:flutter/material.dart';
import 'package:quenc/models/PostCategory.dart';

class AppDrawer extends StatelessWidget {
  final Function changeCategory;
  final List<PostCategory> allCategories;

  AppDrawer({this.changeCategory, this.allCategories});

  List<Widget> allCategoriesListTile(BuildContext ctx) {
    List<Widget> listTiles = [];

    listTiles.add(ListTile(
      leading: Icon(Icons.label),
      title: Text("所有"),
      onTap: () {
        changeCategory(null);
        Navigator.of(ctx).pop();
      },
    ));
    listTiles.add(const Divider());

    for (var c in allCategories) {
      listTiles.add(ListTile(
        leading: Icon(Icons.label),
        title: Text(c.categoryName),
        onTap: () {
          changeCategory(c);
          Navigator.of(ctx).pop();
        },
      ));
      listTiles.add(const Divider());
    }

    return listTiles;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            AppBar(
              title: Text("QuenC"),
              automaticallyImplyLeading: false,
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text("搜尋"),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 60,
                color: theme.primaryColorLight,
                child: Center(
                  child: Text(
                    "類別",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColorDark,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(),
            ...allCategoriesListTile(context),
            // ListTile(
            //     leading: const Icon(
            //       Icons.input,
            //       textDirection: TextDirection.rtl,
            //     ),
            //     title: const Text("登出"),
            //     onTap: () {
            //       // Navigator.of(context)
            //       //     .pushReplacementNamed(MainScreen.routeName);
            //       Navigator.popUntil(context, ModalRoute.withName("/"));
            //       UserService().signOut();
            //     }),
            // const Divider(),
          ],
        ),
      ),
    );
  }
}

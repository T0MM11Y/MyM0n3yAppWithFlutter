import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:mymoney/models/database.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool isExpense = true;
  List<Category> categories = [];
  final AppDb db = AppDb();
  TextEditingController categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    updateCategories(isExpense ? 0 : 1);
  }

  Future<void> updateCategories(int categoryType) async {
    final fetchedCategories = await getAllCategory(categoryType);
    setState(() {
      categories = fetchedCategories;
    });
  }

  Future deleteCategory(int id) async {
    try {
      await db.deleteCategory(id);
      updateCategories(isExpense ? 0 : 1);
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  Future<void> insert(String name, int type, BuildContext context) async {
    try {
      final now = DateTime.now();
      final row = await db
          .into(db.categories)
          .insertReturning(CategoriesCompanion.insert(
            name: name,
            type: type,
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
      print('Inserted row id: $row');
      updateCategories(type);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error inserting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await db.getAllCategories(type);
  }

  Future<void> updateCategory(int id, String name) async {
    try {
      await db.updateCategory(id, name);
      updateCategories(isExpense ? 0 : 1);
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  void openDialog(String? categoryName, [int? categoryId]) {
    bool isUpdate = categoryId != null;
    if (categoryName != null && categoryName.isNotEmpty) {
      categoryNameController.text = categoryName;
    } else {
      categoryNameController.clear();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text((isExpense) ? "Add Expense" : "Add Income",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (isExpense) ? Colors.red : Colors.green,
                fontSize: 20,
              )),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text("Please enter the category name below:",
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                TextFormField(
                  controller: categoryNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Category',
                    hintText: 'Enter category name',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isUpdate) {
                      updateCategory(categoryId!, categoryNameController.text);
                    } else {
                      insert(categoryNameController.text, isExpense ? 0 : 1,
                          context);
                    }
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.save),
                  label: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0, bottom: 0),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildSwitchCard(),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryItem(categories[index], index);
                  },
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
      ),
    );
  }

  Widget _buildSwitchCard() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isExpense ? Colors.red[100]! : Colors.green[100]!,
                isExpense ? Colors.red[200]! : Colors.green[200]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isExpense ? Icons.trending_down : Icons.trending_up,
                  color: isExpense ? Colors.red[900] : Colors.green[900],
                  size: 30,
                ),
                Switch(
                  value: isExpense,
                  onChanged: (bool value) {
                    setState(() {
                      isExpense = value;
                      updateCategories(isExpense ? 0 : 1);
                    });
                  },
                  inactiveTrackColor: Color.fromARGB(255, 38, 155, 153),
                  inactiveThumbColor: Color.fromARGB(255, 228, 228, 228),
                  activeTrackColor: Color.fromARGB(255, 219, 125, 123),
                  activeColor: Color.fromARGB(255, 255, 255, 255),
                ),
                Text(
                  isExpense ? 'Expense' : 'Income',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red[900] : Colors.green[900],
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    openDialog(null);
                  },
                  icon: Icon(Icons.playlist_add_rounded, size: 30),
                  color: isExpense ? Colors.red[900] : Colors.green[900],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isExpense ? Colors.redAccent : Colors.greenAccent,
        child: Icon(Icons.category, color: Colors.white),
      ),
      title: Text(
        category.name,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: () {
              openDialog(category.name, category.id);
            },
            icon: Icon(Icons.edit, color: Colors.orange),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Confirmation',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                        'Are you sure you want to delete this category?',
                        style: TextStyle(fontSize: 16)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.black87)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          deleteCategory(category.id);
                          Navigator.of(context).pop();
                        },
                        child: Text('Delete',
                            style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

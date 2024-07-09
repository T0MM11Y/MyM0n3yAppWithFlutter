import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mymoney/models/database.dart';
import 'package:mymoney/models/transaction_with_category.dart';
import 'package:mymoney/pages/landing_page.dart';
import 'package:mymoney/pages/main_page.dart';

class TransactionPage extends StatefulWidget {
  final TransactionWithCategory? transactionWithCategory;

  const TransactionPage({
    Key? key,
    required this.transactionWithCategory,
  }) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final AppDb database = AppDb();
  bool isExpense = true;
  List<Category> categories = [];
  TextEditingController dateController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int? selectedCategoryId;
  bool isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    amountController.addListener(formatAmount);

    if (widget.transactionWithCategory != null) {
      final transaction = widget.transactionWithCategory!.transaction;
      isExpense = widget.transactionWithCategory!.category.type == 0;
      amountController.text = transaction.amount.abs().toString();
      selectedCategoryId = transaction.categoryId;
      dateController.text =
          DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
      detailController.text = transaction.name;
    }
    _fetchCategories();
  }

  void formatAmount() {
    String cleanNumberString =
        amountController.text.replaceAll(RegExp('[^0-9]'), '');
    if (cleanNumberString.isNotEmpty &&
        int.tryParse(cleanNumberString) != null) {
      int number = int.parse(cleanNumberString);
      String formattedNumber = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      ).format(number);
      int cursorPos = amountController.selection.baseOffset;

      setState(() {
        amountController.value = TextEditingValue(
          text: formattedNumber,
          selection: TextSelection.collapsed(offset: formattedNumber.length),
        );
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      categories = await getCategories();
      if (categories.isNotEmpty && widget.transactionWithCategory == null) {
        selectedCategoryId = categories.first.id;
      }
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> insertTransaction(BuildContext context, int amount,
      int categoryId, DateTime date, String nameDetail) async {
    try {
      final row = await database.into(database.transactions).insertReturning(
            TransactionsCompanion.insert(
              name: nameDetail,
              amount: amount,
              categoryId: categoryId,
              transactionDate: Value(date),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      print('Inserted row id: $row');

      // Tampilkan snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
      );

      // Navigasi ke LandingPage
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LandingPage(
              duration: const Duration(milliseconds: 2000),
              nextRoute: MaterialPageRoute(builder: (context) => MainPage()),
            ),
          ));
    } catch (e) {
      print('Error inserting transaction: $e');
    }
  }

  Future<void> updateTransaction(BuildContext context, int id, int amount,
      int categoryId, DateTime date, String nameDetail) async {
    try {
      await database.updateTransaction(
        id,
        nameDetail,
        amount,
        categoryId,
        date,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction updated successfully!'),
          backgroundColor: Colors.green, // Updated to green
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
      );
      // Navigasi ke LandingPage
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LandingPage(
              duration: const Duration(milliseconds: 2000),
              nextRoute: MaterialPageRoute(builder: (context) => MainPage()),
            ),
          ));
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    return await database.getAllCategories(isExpense ? 0 : 1);
  }

  @override
  void dispose() {
    dateController.dispose();
    amountController.dispose();
    detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 38, 155, 153),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 25, right: 25),
                  child: Row(
                    children: [
                      Icon(
                        isExpense ? Icons.trending_down : Icons.trending_up,
                        color: isExpense ? Colors.red[900] : Colors.green[900],
                        size: 30,
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text(
                            isExpense ? 'Expense' : 'Income',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? Colors.red[900]
                                  : Colors.green[900],
                            ),
                          ),
                          trailing: Switch(
                            value: isExpense,
                            onChanged: widget.transactionWithCategory != null
                                ? null
                                : (bool value) {
                                    setState(() {
                                      isExpense = value;
                                      _fetchCategories();
                                    });
                                  },
                            inactiveTrackColor:
                                Color.fromARGB(255, 38, 155, 153),
                            inactiveThumbColor:
                                Color.fromARGB(255, 228, 228, 228),
                            activeTrackColor:
                                Color.fromARGB(255, 219, 125, 123),
                            activeColor: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  margin: const EdgeInsets.all(18.0),
                  elevation: 1,
                  color: Colors.white,
                  shadowColor: const Color.fromARGB(255, 196, 255, 241),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              hintText: 'Enter the amount',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some amount';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          if (isLoadingCategories)
                            CircularProgressIndicator()
                          else if (categories.isEmpty)
                            Text('No categories found')
                          else
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Category',
                                hintText: 'Select the category',
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              items: categories
                                  .map((category) => DropdownMenuItem<int>(
                                        child: Text(category.name),
                                        value: category.id,
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategoryId = value;
                                });
                              },
                              value: selectedCategoryId,
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                          SizedBox(height: 10),
                          TextFormField(
                            readOnly: true,
                            controller: dateController,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              hintText: 'Select the date',
                              prefixIcon: Icon(Icons.date_range),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2099),
                              );
                              if (pickedDate != null) {
                                String formattedDate =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                                setState(() {
                                  dateController.text = formattedDate;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a date';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            maxLines: 3,
                            controller: detailController,
                            decoration: InputDecoration(
                              labelText: 'Detail',
                              hintText: 'Enter the detail',
                              prefixIcon: Icon(Icons.details),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          selectedCategoryId != null) {
                        int amount = int.tryParse(amountController.text
                                .replaceAll(RegExp('[^0-9]'), '')) ??
                            0;
                        int categoryId = selectedCategoryId!;
                        DateTime date =
                            DateFormat('yyyy-MM-dd').parse(dateController.text);
                        String detail = detailController.text;
                        if (widget.transactionWithCategory != null) {
                          final transaction =
                              widget.transactionWithCategory!.transaction;
                          updateTransaction(context, transaction.id, amount,
                              categoryId, date, detail);
                        } else {
                          insertTransaction(
                              context, amount, categoryId, date, detail);
                        }
                      }
                    },
                    icon: Icon(Icons.check, size: 30),
                    label: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color.fromARGB(255, 96, 199, 198),
                      padding:
                          EdgeInsets.symmetric(horizontal: 80, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

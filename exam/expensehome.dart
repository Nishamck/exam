import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox<Expense>('expenses');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Expense Tracker',
      home: ExpenseTracker(),
    );
  }
}

class Expense {
  final String title;
  final double amount;
  final DateTime date;
  Expense({required this.title, required this.amount, required this.date});

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    title: json['title'],
    amount: json['amount'],
    date: DateTime.parse(json['date']),
  );
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final title = reader.readString();
    final amount = reader.readDouble();
    final date = DateTime.parse(reader.readString());
    return Expense(title: title, amount: amount, date: date);
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.date.toIso8601String());
  }
}

class ExpenseController extends GetxController {
  var expenses = <Expense>[].obs;
  var totalAmount = 0.0.obs;

  final Box<Expense> _expenseBox = Hive.box('expenses');

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  void addExpense(Expense expense) {
    _expenseBox.add(expense);
    expenses.add(expense);
    calculateTotal();
  }

  void deleteExpense(int index) {
    _expenseBox.deleteAt(index);
    expenses.removeAt(index);
    calculateTotal();
  }

  void loadExpenses() {
    expenses.addAll(_expenseBox.values);
    calculateTotal();
  }

  void calculateTotal() {
    totalAmount.value = expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
}

class ExpenseTracker extends StatelessWidget {
  final ExpenseController controller = Get.put(ExpenseController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
      ),
      body: Obx(() => ListView.builder(
        itemCount: controller.expenses.length,
        itemBuilder: (context, index) {
          final expense = controller.expenses[index];
          return ListTile(
            title: Text(expense.title),
            subtitle: Text(
                '${expense.date.toLocal().toString().split(' ')[0]} - ₹${expense.amount.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => controller.deleteExpense(index),
            ),
          );
        },
      )),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showAddExpenseDialog(context),
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => Get.to(() => TotalAmountPage(
              totalAmount: controller.totalAmount.value,
            )),
            child: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text;
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (title.isNotEmpty && amount > 0) {
                final expense = Expense(
                  title: title,
                  amount: amount,
                  date: DateTime.now(),
                );
                controller.addExpense(expense);
                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class TotalAmountPage extends StatelessWidget {
  final double totalAmount;

  TotalAmountPage({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Amount'),
      ),
      body: Center(
        child: Text(
          'Total Expense: ₹${totalAmount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

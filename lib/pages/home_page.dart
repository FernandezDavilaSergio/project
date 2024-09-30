import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> toDoList = [];
  late SharedPreferences prefs;
  String? _selectedCategory;

  List<Map<String, dynamic>> successfulTasks = [];
  List<Map<String, dynamic>> failedTasks = [];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void markTaskCompleted(int index) {
    setState(() {
      Map<String, dynamic> task = toDoList[index];
      DateTime? endDate = DateTime.parse(task['endDate']);
      DateTime now = DateTime.now();

      task['completed'] = true;

      // Verificar si la tarea se completó a tiempo o no
      if (now.isBefore(endDate) || now.isAtSameMomentAs(endDate)) {
        successfulTasks.add(task);
        _showMessage("Task completed successfully!", Colors.green);
      } else {
        failedTasks.add(task);
        _showMessage("Task failed (completed late).", Colors.red);
      }

      // Eliminar de la lista original si lo deseas
      toDoList.removeAt(index);
    });
  }

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? savedList = prefs.getStringList('toDoList');

    if (savedList != null) {
      setState(() {
        toDoList = savedList.map((taskString) {
          final Map<String, dynamic> task = jsonDecode(taskString);
          return task;
        }).toList();
      });
    }
  }

  Future<void> saveNewTask() async {
    if (_controller.text.isEmpty || _startDate == null || _endDate == null || _endDate!.isBefore(_startDate!)) {
      _showMessage("Please provide valid task details.", Colors.red);
      return;
    }

    setState(() {
      toDoList.add({
        'task': _controller.text,
        'completed': false,
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'category': _selectedCategory,
      });
      _controller.clear();
      _startDate = null;
      _endDate = null;
      _selectedCategory = 'Familiar';
    });

    await _saveData();

    _showMessage("Task added successfully!", Colors.green);
  }

  Future<void> _saveData() async {
    List<String> stringList = toDoList.map((task) {
      return jsonEncode(task);
    }).toList();

    await prefs.setStringList('toDoList', stringList);
  }

  void checkBoxChanged(int index) {
    setState(() {
      toDoList[index]['completed'] = !toDoList[index]['completed'];

      DateTime endDate = DateTime.parse(toDoList[index]['endDate']!);
      if (toDoList[index]['completed']) {
        if (DateTime.now().isBefore(endDate)) {
          _showMessage("Task completed on time!", Colors.green);
        } else {
          _showMessage("Task not completed on time.", Colors.red);
        }
      }
    });
    _saveData();
  }

  void deleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
    _saveData();
  }

  void editTask(int index) {
    _controller.text = toDoList[index]['task'];
    _startDate = toDoList[index]['startDate'] != null
        ? DateTime.parse(toDoList[index]['startDate'])
        : null;
    _endDate = toDoList[index]['endDate'] != null
        ? DateTime.parse(toDoList[index]['endDate'])
        : null;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Edit your task'),
                    onChanged: (value) {
                      setState(() {
                        toDoList[index]['task'] = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _selectDateForEdit(context, true, setState),
                    child: Text(
                      _startDate != null
                          ? 'Start Date: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'
                          : 'Select Start Date',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDateForEdit(context, false, setState),
                    child: Text(
                      _endDate != null
                          ? 'End Date: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                          : 'Select End Date',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text('Select Category'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: <String>['Estudio', 'Social', 'Familiar', 'Personal']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_startDate == null || _endDate == null || _endDate!.isBefore(_startDate!)) {
                      _showMessage("Please select valid start and end dates.", Colors.red);
                      return;
                    }
                    setState(() {
                      toDoList[index]['task'] = _controller.text;
                      toDoList[index]['startDate'] = _startDate?.toIso8601String();
                      toDoList[index]['endDate'] = _endDate?.toIso8601String();
                      toDoList[index]['category'] = _selectedCategory;
                    });

                    // Actualizar el estado global
                    this.setState(() {
                      toDoList[index]['task'] = _controller.text;
                      toDoList[index]['startDate'] = _startDate?.toIso8601String();
                      toDoList[index]['endDate'] = _endDate?.toIso8601String();
                    });

                    _saveData();
                    _controller.clear();
                    _startDate = null;
                    _endDate = null;

                    Navigator.of(context).pop();
                    _showMessage("Task updated successfully!", Colors.green);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateForEdit(BuildContext context, bool isStartDate, StateSetter setState) async {
    DateTime initialDate = isStartDate && _startDate != null ? _startDate! : _endDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          if (_startDate != null && pickedDate.isBefore(_startDate!)) {
            _showMessage("End date cannot be before start date.", Colors.red);
          } else {
            _endDate = pickedDate;
          }
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          if (_startDate != null && pickedDate.isBefore(_startDate!)) {
            _showMessage("End date cannot be before start date.", Colors.red);
          } else {
            _endDate = pickedDate;
          }
        }
      });
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Simple GPTask'),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: ListView.builder(
                itemCount: toDoList.length,
                itemBuilder: (BuildContext context, index) {
                  return Column(
                    children: [
                      Slidable(
                        startActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => editTask(index),
                              icon: Icons.edit,
                              label: 'Edit',
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => deleteTask(index),
                              icon: Icons.delete,
                              label: 'Delete',
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          height: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: toDoList[index]['completed'],
                                    onChanged: (value) => checkBoxChanged(index),
                                    checkColor: Colors.black,
                                    activeColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      toDoList[index]['task'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        decoration: toDoList[index]['completed']
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        decorationColor: Colors.white,
                                        decorationThickness: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(toDoList[index]['startDate']))}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    'End Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(toDoList[index]['endDate']))}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Category: ${toDoList[index]['category']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
          ),
          // Expandir la parte inferior
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade200,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(2, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Enter your task',
                              hintStyle: const TextStyle(
                                  color: Colors.blueGrey
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              counterText: '',
                            ),
                            maxLength: 30,
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: saveNewTask,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectDate(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _startDate != null
                              ? 'Start Date: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'
                              : 'Select Start Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectDate(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _endDate != null
                              ? 'End Date: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                              : 'Select End Date',
                        ),
                      ),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: <String>['Estudio', 'Social', 'Familiar', 'Personal']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value), // Mantiene el estilo por defecto
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  hint: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Select Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                  dropdownColor: Colors.teal.shade900,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.teal.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

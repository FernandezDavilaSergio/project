import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> toDoList = [];
  late SharedPreferences prefs;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      });
      _controller.clear();
      _startDate = null;
      _endDate = null;
    });

    await _saveData();

    // Mostrar mensaje de éxito
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
          _showMessage("Task not completed on time.", Colors.red); // Mensaje cuando no se cumple a tiempo
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
                        toDoList[index]['task'] = value; // Actualizar en tiempo real
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
                    // Actualizar la tarea editada en la lista
                    setState(() {
                      toDoList[index]['task'] = _controller.text;
                      toDoList[index]['startDate'] = _startDate?.toIso8601String();
                      toDoList[index]['endDate'] = _endDate?.toIso8601String();
                    });

                    // Actualizar el estado global
                    this.setState(() {
                      toDoList[index]['task'] = _controller.text;
                      toDoList[index]['startDate'] = _startDate?.toIso8601String();
                      toDoList[index]['endDate'] = _endDate?.toIso8601String();
                    });

                    _saveData();  // Guardar los cambios en almacenamiento persistente
                    _controller.clear();
                    _startDate = null;
                    _endDate = null;
                    Navigator.of(context).pop(); // Cerrar el diálogo
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
        duration: const Duration(seconds: 3), // Mostrar mensaje por 3 segundos
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
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10), // Padding en los bordes
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
                          padding: const EdgeInsets.all(10), // Menos padding para los cuadros
                          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 5), // Margen entre tareas
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
                                        fontSize: 22,
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
                              if (toDoList[index]['startDate'] != null) ...[
                                Text(
                                  'Start Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(toDoList[index]['startDate']))}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                  ),
                                ),
                              ],
                              if (toDoList[index]['endDate'] != null) ...[
                                Text(
                                  'End Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(toDoList[index]['endDate']))}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Espacio entre tareas
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
              color: Colors.teal.shade200,  // Color más claro para el recuadro
              borderRadius: BorderRadius.circular(15), // Borde redondeado del contenedor
            ),
            child: Column(
              children: [
                // Cuadro de texto con color deepPurple.shade300
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2), // Color de la sombra
                                spreadRadius: 2, // Extensión de la sombra
                                blurRadius: 5,   // Difuminado de la sombra
                                offset: Offset(2, 3), // Desplazamiento de la sombra
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Enter your task', // Texto dentro del cuadro
                              hintStyle: const TextStyle(
                                  color: Colors.blueGrey
                              ), // Color del texto
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10), // Borde redondeado
                                borderSide: BorderSide.none, // Sin borde
                              ),
                              filled: true,
                              fillColor: Colors.white, // Fondo del cuadro de texto
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Botón de añadir tarea con contorno redondeado
                    FloatingActionButton(
                      onPressed: saveNewTask,
                      backgroundColor: Colors.white, // Color de fondo del botón
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Modifica este valor para ajustar el radio
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 30,
                      ), // Icono del botón
                    ),
                  ],
                ),
                const SizedBox(height: 15), // Espacio entre el cuadro de texto y los botones de fecha
                // Botones de selección de fecha
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
                    const SizedBox(width: 10), // Espacio horizontal entre los botones
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

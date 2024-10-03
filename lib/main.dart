import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  late Map<String, dynamic> _lastRemove;
  late int _lastRemovePos;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //devido ao erro de n aceitar a lista null e quebrar assim que iniciar o app sem ter add nada antes
    //implementei uma verificação onde se n tiver nada salvo ele retornara a lista e se tiver salvo ele retorna os intes salvos
    _readData().then((data) {
      setState(() {
        if (data != null) {
          _toDoList = jsonDecode(data);
        } else {
          _toDoList = [];
        }
      });
    });
  }

// adicionar tarefa
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

// função onde ordena os itens por estado de concluido e não concluido
  Future<Null> _reFresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                //para definir o estilo, cor do botão e da letra segue esse trecho de cond
                ElevatedButton(
                  onPressed: _addToDo,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: Text(
                    "ADD",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            //listview é um widget de lista
            //builder é um construtor que permite que eu contrua a minha lista confrome nescessario
            child: RefreshIndicator(
              onRefresh: _reFresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    // Dismissible é usado para botão de arrastar, e nesse caso ele ira apagar o item
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (t) {
          setState(() {
            _toDoList[index]["ok"] = t;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemove = Map.from(_toDoList[index]);
          _lastRemovePos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemove["title"]}\" removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovePos, _lastRemove);
                  });
                }),
            duration: Duration(seconds: 2),
          );
          // nesse caso não usa mais o sacffold.of mas o ScaffoldMessenger.of para a mensagem no canto inferior
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/data.json";
    final file = File(path);

    // Check if the file exists, and create it if it doesn't
    if (!(await file.exists())) {
      await file.create(
          recursive: true); // Create file and directories if needed
    }

    return file;
  }

  //função para salvar o arquivo
  Future<File> _saveData() async {
    // essa linha ele pega  a lista, transforma em json e armazena em uma string
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

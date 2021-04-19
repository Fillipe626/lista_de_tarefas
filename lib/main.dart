import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override // Over da classe initistate para que o app pegue os dados do arquivo json ao inicializar
  void initState() {
    super.initState();

    _readData().then((data) {
      _toDoList =
          json.decode(data); //Decode do json para ser exibido os dados em tela
    });
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Alerta"),
            content: Text(
                "O nome da tarefa deve conter pelo menos cinco caracteres!"),
            actions: <Widget>[
              FlatButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _addToDo() {
    setState(() {
      //atualiza estado da tela
      Map<String, dynamic> newToDo = Map();
      newToDo["tittle"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] =
          false; //tarefa é adicionada como não checada //Todos precisam ter o "ok" escrito da mesma forma
      if (newToDo["tittle"].length > 5 && newToDo["tittle"].isNotEmpty) {
        //valida
        _toDoList.add(newToDo);
        _saveData();
      } else {
        _showDialog();
      } //adiciona nova tarefa
    });
  }



  Future<Null> _refresh() async {
    //função que ordena a lista de tarefas
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        //lista
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
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    // expande o textfild e espreme o botão
                    child: TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                          labelText: "Nova tarefa",
                          labelStyle:
                              TextStyle(color: Colors.deepPurpleAccent)),
                    ),
                  ),
                  RaisedButton(
                    color: Colors.deepPurpleAccent,
                    child: Text("Add"),
                    textColor: Colors.white,
                    onPressed: _addToDo,
                  )
                ],
              )),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  //pega o tamanho da lista da variavel
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    //É reponsável por criar cada item da lista
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      //Pega o tempo e transforma em chave para que o sitema saiba qual linha é excluída(não é a forma ideal)
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["tittle"]),
        value: _toDoList[index]["ok"],
        //Todos precisam ter o "ok" escrito da mesma forma
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"]
              ? //Todos precisam ter o "ok" escrito da mesma forma
              Icons.check_circle_rounded
              : Icons.favorite_rounded),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          //função que remove o item da lista
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            //barrinha embaixo que desfaz a ação
            content: Text("Tarefa \"${_lastRemoved["tittle"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3), //Quanto tempo a barra será exibida
          );
          Scaffold.of(context).removeCurrentSnackBar();//remove a snackbark para evitar o stackmento
          Scaffold.of(context).showSnackBar(snack); //Mostra a snackbar
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    //armazena os dados no arquivo
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    //armazena os dados no arquivo
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

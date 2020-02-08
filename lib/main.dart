import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


//Aqui começa o programa
void main() {
  runApp(MaterialApp(
    home: Home(), // Chamo o state
    debugShowCheckedModeBanner: false, // somente para não rodar com a faixa de debug
  ));
}
// 
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState(); // Cria o primeiro estado
}

class _HomeState extends State<Home> {
  //Onde declaro as váriaveis do HomeState
  GlobalKey<FormState> _formKey;
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;
  final _taskController = TextEditingController();
  List _toDoList;

  @override
  void initState() { // Onde vai passar sempre que iniciar o state do app
    _formKey = GlobalKey<FormState>();
    _toDoList = List();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
    super.initState();
  }

  //Adiciono em um arquivo
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _taskController.text;
      newToDo["ok"] = false;
      _taskController.text = "";
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {  // Tudo são widgets no flutter, aqui começa o desenho do aplicação
    return Scaffold(
      appBar: AppBar( // Barra de cima
        title: Text(
          "Lista de Tarefas",
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Form( // corpo da aplicação
        key: _formKey,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  RaisedButton(
                    onPressed: () {
                      _addToDo();
                    },
                    child: Text(
                      "ADD",
                    ),
                    textColor: Colors.white,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            Expanded( // Isso foi usado pois eu tenho uma coluna e dentro dela tenho uma row
              child: RefreshIndicator( // Então a row não sabera qual tamanho ela deve seguir
                onRefresh: _refresh, // Função chamada sempre que for dado um refresh no aplicativo segurando para baixo
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemBuilder: (context, index) {
                    return buildItem(context, index);
                  },
                  itemCount: _toDoList.length,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1)); // Usado para dar sort no aplicativo
    setState(() {
      _toDoList.sort((a, b) {
        if(a["ok"]  && !b["ok"])
          return -1;
        else if(!a["ok"] && b["ok"])
          return 1;
        else
          return 0;
      });
      _saveData();
    });

  }

  Future<File> _getFile() async { // Cria o arquivo json de forma asyncrona
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async { // Salva os dados em um arquivo de forma asyncrona
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async { // Le os dados do arquivo salvo no app de forma asyncrona
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget buildItem(context, index) { // Constroi um item de uma lista
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
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
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
        });

        final snack = SnackBar( // Barra usada para remover um elemento da lista
          content: Text(
            "Tarefa ${_lastRemoved["title"]} Removida!",
          ),
          action: SnackBarAction( // Ação da snack bar para desfazer a remoção
            label: "Desfazer",
            onPressed: () {
              setState(() {
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
            },
          ),
          duration: Duration(seconds: 3),
        );
        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }
}

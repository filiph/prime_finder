// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/material.dart';

import 'worker.dart';

import 'package:flutter/widgets.dart';

class IntegerPair {
  int key;
  int value;
  IntegerPair(this.key, this.value);

  @override
  String toString() => "IntegerPair<$key,$value>";
}

class PrimeFinder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new PrimeFinderState();
}

class PrimeFinderState extends State<PrimeFinder> {
  Isolate _isolate;

  SendPort _sendPort;

  String inputErrorMessage = '';

  int lastResult;

  String _lastTargets;

  bool isolateReady = false;

  bool isolateComputing = false;

  Queue<int> foundIntegers = new Queue<int>();

  List<IntegerPair> numbers = [new IntegerPair(1, 82), new IntegerPair(2, 79)];

  PrimeFinderState() {
    _init();
  }

  void addInput() {
    numbers.add(new IntegerPair(numbers.length + 1, 123));
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        _buildOutput(context),
        _buildStartStopButtons(context)
      ],
    );
  }

  Widget _buildOutput(BuildContext context) {
    return new Flexible(
        child: new Column(
      children: <Widget>[_buildCurrent(context), _buildAllResultsList(context)],
    ));
  }

  Widget _buildCurrent(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.only(
          top: 124.0, bottom: 48.0, left: 24.0, right: 24.0),
      child: _buildCurrentText(context),
    );
  }

  Widget _buildCurrentText(BuildContext context) {
    if (lastResult == null) {
      return new Text("Nothing here yet. Try computing a prime number.");
    }
    return new Text(
      "$lastResult",
      textScaleFactor: 2.0,
      style: new TextStyle(
          color: isolateComputing ? Colors.grey : Theme.of(context).accentColor,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAllResultsList(BuildContext context) {
    if (foundIntegers.isEmpty) return new Text("");
    return new Column(
        children: foundIntegers
            .map((result) => new Text("$result"))
            .toList(growable: false));
  }

  Widget _buildStartStopButtons(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.all(24.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new MaterialButton(
              color: isolateComputing
                  ? Colors.grey
                  : Theme.of(context).accentColor,
              child: new Text(
                "Compute Next".toUpperCase(),
                style: Theme.of(context).primaryTextTheme.button,
              ),
              onPressed: isolateComputing ? null : _startCompute),
          new MaterialButton(
              child: new Text("FORCE STOP"),
              onPressed: isolateComputing ? () {} : null)
        ],
      ),
    );
  }

  _startCompute() async {
    if (_targetsChanged()) {
      _sendPort.send({
        "type": "register-targets",
        "value": numbers.map((pair) => pair.value).toList()
      });
      foundIntegers.clear();
    }
    _sendPort.send({"type": "start"});
    isolateReady = false;
    isolateComputing = true;
  }

  void deleteByKey(int key) {
    numbers.removeWhere((pair) => pair.key == key);
    recomputeKeys();
  }

  @override
  void dispose() {
    _isolate?.kill();
    super.dispose();
  }

  void forceStop() {
    _sendPort.send({"type": "force-stop"});
  }

  void recomputeKeys() {
    for (int i = 0; i < numbers.length; i++) {
      numbers[i].key = i + 1;
    }
  }

  String _buildTargetsFingerprint() =>
      (numbers.map((pair) => pair.value).toList()..sort()).join(',');

  void _handleMessage(Map<String, Object> message) {
    String type = message["type"];
    switch (type) {
      case "port":
        _sendPort = message["value"];
        setState(() {
          isolateReady = true;
        });
        return;
      case "latest":
        setState(() {
          lastResult = message["value"];
        });
        return;
      case "found":
        setState(() {
          foundIntegers.addFirst(message["value"]);
        });
        return;
      case "done":
        _sendPort.send({"type": "get-latest"});
        setState(() {
          isolateReady = true;
          isolateComputing = false;
        });
        return;
    }
  }

  _init() async {
    ReceivePort receivePort = new ReceivePort();
    receivePort.listen(_handleMessage);

    _isolate =
        await Isolate.spawn(entryPoint, receivePort.sendPort, paused: true);

    var errorPort = new ReceivePort();
    errorPort.listen((error) {
      print("ERROR: $error");
    });
    _isolate.addErrorListener(errorPort.sendPort);

    _isolate.resume(_isolate.pauseCapability);
  }

  bool _targetsChanged() {
    if (_lastTargets == null) {
      _lastTargets = _buildTargetsFingerprint();
      return true;
    }
    var newFingerprint = _buildTargetsFingerprint();
    if (newFingerprint == _lastTargets) {
      return false;
    }
    _lastTargets = newFingerprint;
    return true;
  }
}

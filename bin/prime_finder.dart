// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

main(List<String> args) async {
  if (args.isEmpty) {
    print("Provide numbers to find.\n"
        "For example: dart bin/prime_finer.dart 82 79");
    exitCode = 2;
    return;
  }

  int key = 1;
  numbers = args
      .map((numberAsString) => int.parse(numberAsString))
      .map((n) => new IntegerPair(key++, n))
      .toList(growable: false);

  ReceivePort receivePort = new ReceivePort();
  receivePort.listen(_handleMessage);

  var uri = Uri.parse('../web/worker.dart');

  _isolate =
      await Isolate.spawnUri(uri, [], receivePort.sendPort, paused: true);

  var errorPort = new ReceivePort();
  errorPort.listen((error) {
    print("ERROR: $error");
  });
  _isolate.addErrorListener(errorPort.sendPort);

  _isolate.resume(_isolate.pauseCapability);
}

Queue<int> foundIntegers = new Queue<int>();

String inputErrorMessage = '';

bool isolateComputing = false;

bool isolateReady = false;

int lastResult;

List<IntegerPair> numbers = [new IntegerPair(1, 82), new IntegerPair(2, 79)];

Isolate _isolate;

String _lastTargets;

SendPort _sendPort;

void addInput() {
  numbers.add(new IntegerPair(numbers.length + 1, 123));
}

compute() async {
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
      isolateReady = true;
      compute();
      return;
    case "latest":
      lastResult = message["value"];
      return;
    case "found":
      foundIntegers.addFirst(message["value"]);
      print(foundIntegers.first);
      compute();
      return;
    case "done":
      _sendPort.send({"type": "get-latest"});
      isolateReady = true;
      isolateComputing = false;
      return;
  }
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

class IntegerPair {
  int key;
  int value;
  IntegerPair(this.key, this.value);

  @override
  String toString() => "IntegerPair<$key,$value>";
}

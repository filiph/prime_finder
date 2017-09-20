// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:isolate';

import 'package:angular/core.dart';
import 'package:angular_components/angular_components.dart';

import '../integer_input/integer_input.dart';

class IntegerPair {
  int key;
  int value;
  IntegerPair(this.key, this.value);

  @override
  String toString() => "IntegerPair<$key,$value>";
}

@Component(
  selector: 'my-app',
  styleUrls: const ['prime_finder.css'],
  templateUrl: 'prime_finder.html',
  directives: const [materialDirectives, IntegerInput],
  providers: const [materialProviders],
)
class PrimeFinder implements OnInit, OnDestroy {
  Isolate _isolate;

  SendPort _sendPort;

  String inputErrorMessage = '';

  int lastResult;

  String _lastTargets;

  bool isolateReady = false;

  bool isolateComputing = false;

  Queue<int> foundIntegers = new Queue<int>();

  List<IntegerPair> numbers = [new IntegerPair(1, 82), new IntegerPair(2, 79)];

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

  @override
  ngOnDestroy() {
    _isolate?.kill();
  }

  @override
  ngOnInit() async {
    ReceivePort receivePort = new ReceivePort();
    receivePort.listen(_handleMessage);

    var uri = Uri.parse('worker.dart');

    _isolate =
        await Isolate.spawnUri(uri, [], receivePort.sendPort, paused: true);

    var errorPort = new ReceivePort();
    errorPort.listen((error) {
      print("ERROR: $error");
    });
    _isolate.addErrorListener(errorPort.sendPort);

    _isolate.resume(_isolate.pauseCapability);
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
        return;
      case "latest":
        lastResult = message["value"];
        return;
      case "found":
        foundIntegers.addFirst(message["value"]);
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
}

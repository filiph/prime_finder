// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:isolate';

import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:webworker_isolate/integer_input/integer_input.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, IntegerInput],
  providers: const [materialProviders],
)
class AppComponent implements OnInit, OnDestroy {
  Isolate _isolate;

  SendPort _sendPort;

  String inputErrorMessage = '';

  List<IntegerPair> numbers = [new IntegerPair(1, 82), new IntegerPair(2, 79)];

  int lastResult;

  String _lastTargets;

  bool isolateReady = false;

  bool isolateComputing = false;

  Queue<int> foundIntegers = new Queue<int>();

  List<int> get previous {
    if (foundIntegers.length <= 1) return null;
    return foundIntegers.skip(1).toList();
  }

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
    print("deleting $key");
    numbers.removeWhere((pair) => pair.key == key);
    recomputeKeys();
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

  String _buildTargetsFingerprint() =>
      (numbers.map((pair) => pair.value).toList()..sort()).join(',');

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
}

class IntegerPair {
  int key;
  int value;
  IntegerPair(this.key, this.value);

  String toString() => "IntegerPair<$key,$value>";
}

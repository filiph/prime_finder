import 'dart:async';
import 'dart:isolate';

main(List<String> args, SendPort sendPort) {
  new PrimeFinder(sendPort);
}

class PrimeFinder {
  int _maxReached = 2;

  int _current = 2;

  final ReceivePort _receivePort;

  final SendPort _sendPort;

  int max;

  List<String> targets;

  var _primes = <int>[];

  PrimeFinder(this._sendPort) : _receivePort = new ReceivePort() {
    _receivePort.listen(_handleMessage);
    _sendPort.send({"type": "port", "value": _receivePort.sendPort});
  }

  bool complies(int number) {
    String text = number.toString();
    return targets.every((target) => text.contains(target));
  }

  findPrimes() async {
    var alreadyComputedPrimes =
        _primes.where((prime) => prime >= _current && prime < _maxReached);
    var complying = alreadyComputedPrimes.where(complies);
    for (var number in complying) {
      _sendPort.send({"type": "found", "value": number});
      _sendPort.send({"type": "done"});
      _current = number + 1;
      return;
    }

    for (int i = _maxReached; max != null ? i <= max : true; i++) {
      _maxReached = i;
      _current = i;
      bool isPrime = true;
      for (var prime in _primes) {
        if (i % prime == 0) {
          isPrime = false;
          break;
        }
      }
      if (isPrime) {
        _primes.add(i);
        if (complies(i)) {
          _sendPort.send({"type": "found", "value": i});
          _sendPort.send({"type": "done"});
          return;
        }
      }
      if (i % 1000 == 0) {
        if (forceStop) {
          forceStop = false;
          _sendPort.send({"type": "done"});
          return;
        }

        await new Future.delayed(const Duration(milliseconds: 5));
      }

      if (i % 12345 == 0) {
        _sendPort.send({"type": "latest", "value": _primes.last});
      }
    }
    _sendPort.send({"type": "done"});
  }

  bool forceStop = false;

  void _handleMessage(Map<String, Object> message) {
    String type = message["type"];
    switch (type) {
      case "set-max":
        max = message["value"];
        return;
      case "register-targets":
        _current = 2;
        targets = (message["value"] as List<int>)
            .map((e) => e.toString())
            .toList(growable: false)..sort();
        return;
      case "start":
        findPrimes();
        return;
      case "force-stop":
        forceStop = true;
        return;
      case "get-latest":
        _sendPort.send({
          "type": "latest",
          "value": _primes.last
        });
        return;
    }
  }
}

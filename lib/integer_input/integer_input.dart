// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:angular/core.dart';
import 'package:angular_components/angular_components.dart';
import 'package:prime_finder/prime_finder.dart';

@Component(
  selector: 'integer-input',
  styleUrls: const ['integer_input.css'],
  templateUrl: 'integer_input.html',
  directives: const [materialDirectives],
  providers: const [materialProviders],
)
class IntegerInput implements OnInit, OnDestroy {
  static final _whitespace = new RegExp(r'\s');

  @ViewChild('number')
  MaterialInputComponent inputEl;


  final _deletedController = new StreamController<int>.broadcast();

  @Output()
  Stream<int> get deleted => _deletedController.stream;

  @Input()
  IntegerPair pair;

  @Input('disabled')
  bool isDisabled = false;

  String inputErrorMessage = '';

  String get label => "Number #${pair.key}";

  delete() async {
    await new Future.delayed(const Duration(milliseconds: 300));
    _deletedController.add(pair.key);
  }

  handleChange() {
    try {
      pair.value = int.parse(inputEl.inputText.replaceAll(_whitespace, ''));
      inputErrorMessage = '';
    } on FormatException {
      inputErrorMessage = "Not an integer";
    }
  }

  @override
  ngOnInit() {
    inputEl.inputText = '${pair.value}';
  }

  @override
  ngOnDestroy() {
    _deletedController.close();
  }
}

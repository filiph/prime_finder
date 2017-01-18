// Copyright (c) 2017, filiph. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:prime_finder/app_component.dart';

@Component(
  selector: 'integer-input',
  styleUrls: const ['integer_input.css'],
  templateUrl: 'integer_input.html',
  directives: const [materialDirectives],
  providers: const [materialProviders],
)
class IntegerInput implements OnInit {
  static final _whitespace = new RegExp(r'\s');

  @ViewChild('number')
  MaterialInputComponent inputEl;

  @Output()
  EventEmitter<int> deleted = new EventEmitter<int>();

  @Input()
  IntegerPair pair;

  String inputErrorMessage = '';

  String get label => "Number #${pair.key}";

  delete() async {
    await new Future.delayed(const Duration(milliseconds: 300));
    deleted.add(pair.key);
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
}

@JS()
library log;

import 'package:js/js.dart';

@JS('console.log')
external dynamic log(dynamic value);

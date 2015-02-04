library polymorphic.tests.all;

import "common.dart";

@ExternalGroup("storage")
import "storage.dart";

@ExternalGroup("utils")
import "utils.dart";

void main() {
  runTests(#polymorphic.tests.all);
}

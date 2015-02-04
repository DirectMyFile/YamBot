library polymorphic.test.utils;

import "common.dart";
export "common.dart";

import "dart:io";

import "package:polymorphic_bot/utils.dart";

@Group("EnvironmentUtils")
class EnvironmentUtilsGroup {
  @Test("isCompiled() returns false for uncompiled output")
  isCompiledReturnsFalse() {
    expect(EnvironmentUtils.isCompiled(), isFalse);
  }
  
  @Test("isLikelyPlugin() returns false for non-plugins")
  isLikelyPluginReturnsFalse() {
    expect(EnvironmentUtils.isPlugin(), isFalse);
  }
}

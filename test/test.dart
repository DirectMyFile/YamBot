import "common.dart";
export "common.dart";

@ExternalGroup("external")
import "test_external.dart";

@Configure()
configure() => useVMConfiguration();

@Group("Group A", subgroups: const [TestGroupB])
class TestGroup {
  @Test("Test A")
  a() => print("TEST A");
}

@SubGroup("Group B", subgroups: const [TestGroupC])
class TestGroupB {
  @Test("Test B")
  b() => print("TEST B");
}

@SubGroup("Group C")
class TestGroupC {
  @Test("Test C")
  c() => print("TEST C");
  
  @Test("Test D")
  d() => print(mockOf(String));
}

@Mocker(String)
mockString() => "Hello World";
import "common.dart";
export "common.dart";

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
  b() => print("TEST C");
}
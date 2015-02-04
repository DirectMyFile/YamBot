library polymorphic.tests.storage;

import "common.dart";
export "common.dart";

import "dart:io";

import "package:polymorphic_bot/api.dart" show Storage;

@Group("persistence")
class PersistenceGroup {
  @Test("is persistent")
  void persists() {
    var storage = getStorage("persist");
    storage.setString("a", "b");
    expect(storage.getString("a"), equals("b"));
    storage.save();
    expect(fileExists("persist.json"), isTrue);
    storage.destroy();
    storage = getStorage("persist");
    expect(storage.getString("a"), equals("b"));
    expect(fileExists("persist.json"), isTrue);
    storage.destroy();
  }

  @Test("sub storage")
  void substorage() {
    var storage = getStorage("storage");
    var hi = storage.getSubStorage("hi");
    expect(hi.keys.length, equals(0));
    hi.setString("a", "b");
    expect(hi.keys.contains("a"), isTrue);
    expect(hi.getString("a"), equals("b"));
    expect(storage.getMap("hi").containsKey("a"), isTrue);
    expect(storage.getMap("hi")["a"], equals("b"));
    storage.save();
    storage.destroy();
  }
  
  @Destroy()
  destroy() => storageFiles.forEach((path) {
    var file = new File(path);
    if (file.existsSync())
      file.deleteSync();
  });
}

bool fileExists(String path) => new File(path).existsSync();

Storage getStorage(String name) {
  var p = "${name}.json";
  if (!storageFiles.contains(p)) storageFiles.add(p);
  return new Storage(p)..load();
}

List<String> storageFiles = [];
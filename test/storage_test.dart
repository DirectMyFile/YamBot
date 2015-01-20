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
  
  @Destroy()
  destroy() => storageFiles.forEach((path) => new File(path).deleteSync());
}

bool fileExists(String path) => new File(path).existsSync();

Storage getStorage(String name) {
  var p = "${name}.json";
  if (!storageFiles.contains(p)) storageFiles.add(p);
  return new Storage(p)..load();
}

List<String> storageFiles = [];
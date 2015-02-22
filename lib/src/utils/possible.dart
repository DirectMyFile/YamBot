part of polymorphic.utils;

typedef void PossibleFunction<T>(T value);
typedef void PossibleAction();

class Possible<T> {
  PossibleFunction<T> _callback;

  Possible();

  void then(PossibleFunction<T> callback) {
    _callback = callback;
  }

  void run(PossibleAction action) {
    then((_) => action());
  }
}

class PossibleCreator<T> {
  final Possible<T> possible = new Possible<T>();

  void complete(T value) {
    if (possible._callback != null) {
      possible._callback(value);
    }
  }
}

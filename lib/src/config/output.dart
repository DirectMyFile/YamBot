part of yambot.config;

class Output extends PODO {
  ConsoleOutput console = new ConsoleOutput();
}

class ConsoleOutput extends PODO {
  bool connect = true;
  bool disconnect = true;
  bool ready = false;
  bool messages = true;
  bool join = true;
  bool part = true;
  bool quit = true;
  bool raw = false;
}

part of yambot.config;

class Output extends PODO {
  ConsoleOutput console = new ConsoleOutput();
}

class ConsoleOutput extends PODO {
  bool messages = true;
  bool join = true;
  bool part = true;
  bool quit = true;
  bool raw = false;
}

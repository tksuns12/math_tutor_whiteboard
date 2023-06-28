class PointerManager {
  List<int> pointers = [];
  bool isInMultiplePointers = false;

  void addPointer(int pointer) {
    pointers.add(pointer);
    if (pointers.length > 1) {
      isInMultiplePointers = true;
    }
  }

  void popPointer() {
    pointers.removeLast();
    if (pointers.isEmpty) {
      isInMultiplePointers = false;
    }
  }
}

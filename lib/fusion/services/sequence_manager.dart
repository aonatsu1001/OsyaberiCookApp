class SequenceManager {
  final List<String> items;
  int currentIndex = 0; // デフォルト0番目

  SequenceManager(this.items);

  Map<String, dynamic> next() {
    if (items.isEmpty) return {"index": -1, "item": null};
    currentIndex = (currentIndex + 1) % items.length;
    return {"index": currentIndex, "item": items[currentIndex]};
  }

  Map<String, dynamic> previous() {
    if (items.isEmpty) return {"index": -1, "item": null};
    currentIndex = (currentIndex - 1 + items.length) % items.length;
    return {"index": currentIndex, "item": items[currentIndex]};
  }

  Map<String, dynamic> jump(int index) {
    if (index < 0 || index >= items.length) {
      return {"index": -1, "item": null};
    }
    currentIndex = index;
    return {"index": currentIndex, "item": items[currentIndex]};
  }
}

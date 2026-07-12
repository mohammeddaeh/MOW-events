class VersionComparator {
  VersionComparator._();

  /// Returns true if [remote] is a newer version than [current].
  static bool isNewer(String remote, String current) {
    final remoteParts = _parse(remote);
    final currentParts = _parse(current);

    for (var i = 0; i < 3; i++) {
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final cleaned = version.split('+').first;
    final segments = cleaned.split('.');
    return List.generate(3, (i) {
      if (i >= segments.length) return 0;
      return int.tryParse(segments[i]) ?? 0;
    });
  }
}

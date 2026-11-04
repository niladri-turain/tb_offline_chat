/// Someone nearby. We only ever know their random anonymous ID.
class Peer {
  const Peer(this.id);

  /// First 4 characters of their uuid, upper case, e.g. "7F3A".
  final String id;

  String get name => 'Anon $id';

  /// Two characters shown inside the avatar.
  String get initials => id.substring(0, 2);
}

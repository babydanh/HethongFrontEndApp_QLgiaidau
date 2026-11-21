/// Body of `PATCH /livestream/cameras/:id`: only the fields that changed.
class CameraPatch {
  const CameraPatch({this.name, this.playbackUrl});

  final String? name;
  final String? playbackUrl;

  bool get isEmpty => name == null && playbackUrl == null;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': ?name,
    'playbackUrl': ?playbackUrl,
  };
}

/// Uploads the file of a FILE custom field of the advanced registration form
/// (`POST /tournaments/:id/registration-attachment`).
abstract class IRegistrationAttachmentRepository {
  /// Returns the stored attachment (`url`, `publicId`, `originalName`, `size`,
  /// `mimeType`); it goes verbatim into `customResponses[fieldId]`.
  Future<Map<String, dynamic>> upload({
    required String tournamentId,
    required String fieldId,
    required List<int> bytes,
    required String fileName,
  });
}

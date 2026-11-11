/// Hiện nút bản ghi MP4 khi trận còn camera, hoặc khi trận đã phát và bản ghi
/// vẫn đọc được dù camera đã gỡ (key trả về pool). `hasRecording` chỉ tính là
/// có khi đúng boolean `true` (Backend cũ không trả = chưa có bản ghi).
bool canShowRecordingButton({required bool hasCamera, bool? hasRecording}) =>
    hasCamera || hasRecording == true;

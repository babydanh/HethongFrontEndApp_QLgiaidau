import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// Bảng style dùng chung cho mọi nơi hiển thị nội dung HTML (mô tả giải,
/// điều lệ, giới thiệu). Một nguồn duy nhất để cỡ chữ không lệch giữa các màn.
///
/// Vì sao cần ép: thư viện `flutter_widget_from_html` đặt cỡ tiêu đề theo `em`
/// — `h1 = 2em`, `h2 = 1.5em`, `h3 = 1.17em` (đọc trong `core_widget_factory.dart`
/// `_tagH1/_tagH2/_tagH3`). Cùng một nội dung HTML đó, trên web khung rộng nên
/// vừa mắt, nhưng trên điện thoại (bề rộng ~390px) `h1` phình gần hết bề ngang,
/// đẩy tiêu đề "ĐIỀU LỆ THI ĐẤU" xuống nhiều dòng. Vì vậy ở đây ta ép cỡ
/// **tuyệt đối** cho tiêu đề thay vì để `em` nhân với cỡ gốc.
class RichTextStyles {
  const RichTextStyles._();

  /// Cỡ chữ gốc, khớp `text-sm` của web.
  static const double baseFontSize = 13.5;

  /// Cỡ tiêu đề tuyệt đối (px) trên màn hình nhỏ — vừa đủ nổi bật mà không
  /// chiếm hết bề ngang.
  static const double _h1 = 19;
  static const double _h2 = 17;
  static const double _h3 = 15.5;
  static const double _h4 = 14.5;

  /// Dựng `customStylesBuilder` cho [HtmlWidget].
  ///
  /// Nhận `element` của từng node rồi trả về CSS dạng chuỗi. Giá trị trả về
  /// được **gộp đè** lên style mặc định của thư viện, nên chỉ cần khai các
  /// thuộc tính muốn ép.
  static CustomStylesBuilder builder({
    required double baseFontSize,
    required Color linkColor,
  }) {
    return (element) {
      switch (element.localName) {
        case 'h1':
          return {
            'font-size': '${_h1}px',
            'font-weight': '800',
            'line-height': '1.3',
            'margin': '4px 0 8px',
          };
        case 'h2':
          return {
            'font-size': '${_h2}px',
            'font-weight': '800',
            'line-height': '1.3',
            'margin': '4px 0 6px',
          };
        case 'h3':
          return {
            'font-size': '${_h3}px',
            'font-weight': '700',
            'line-height': '1.35',
            'margin': '2px 0 4px',
          };
        case 'h4':
        case 'h5':
        case 'h6':
          return {
            'font-size': '${_h4}px',
            'font-weight': '700',
            'margin': '2px 0 4px',
          };
        case 'p':
          return {'margin': '0 0 8px', 'font-size': '${baseFontSize}px'};
        case 'ul':
        case 'ol':
          return {'margin': '0 0 8px', 'padding-left': '20px'};
        case 'li':
          return {'margin': '0 0 4px'};
        case 'a':
          return {'color': '#2563EB', 'text-decoration': 'underline'};
        case 'figure':
          return {'margin': '8px 0'};
        case 'figcaption':
          return {'font-size': '${baseFontSize - 1.5}px', 'opacity': '0.7'};
        default:
          return null;
      }
    };
  }
}

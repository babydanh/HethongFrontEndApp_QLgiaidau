## Why

`openspec doctor` (OpenSpec 1.14.2) báo: "Guidance for operation 'archive' must be an array of strings, ignoring this operation's guidance".
Trong `openspec/config.yaml`, 2 mục của `operations.archive.guidance` (dòng 36 và 37) chứa `: ` mà không đặt trong nháy, nên YAML đọc thành map thay vì chuỗi. OpenSpec bỏ qua CẢ khối hướng dẫn archive, nên agent chạy `/opsx-archive` không nhận được luật rebase trước khi archive, giữ cả hai phía khi spec chung đã đổi, và cấm `--skip-specs`.

## What Changes

- Đặt 2 mục đó trong nháy kép. Nội dung chữ giữ nguyên từng ký tự.

## Out of scope

- Không đổi nội dung bất kỳ luật nào trong `config.yaml`.
- Không đổi `openspec-gate.py`, không archive hay sửa change khác.
- Không đổi code ứng dụng; không có spec delta (`skip_specs: true`).

## Impact

- Chỉ `openspec/config.yaml` của repo App.
- Cùng lỗi có ở cả 3 repo (Web, Backend, App); mỗi repo có change riêng cùng tên, sửa độc lập. Không ảnh hưởng API hay field nào.

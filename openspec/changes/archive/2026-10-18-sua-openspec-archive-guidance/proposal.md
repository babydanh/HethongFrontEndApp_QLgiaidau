## Why

`openspec doctor` (OpenSpec 1.14.2) báo: "Guidance for operation 'archive' must be an array of strings, ignoring this operation's guidance".
Trong `openspec/config.yaml`, 2 mục của `operations.archive.guidance` (dòng 36 và 37) chứa `: ` mà không đặt trong nháy, nên YAML đọc thành map thay vì chuỗi. OpenSpec bỏ qua CẢ khối hướng dẫn archive, nên lệnh `/opsx-archive` không nạp được các luật đó từ `config.yaml`. Bản sao của chúng trong `AGENTS.md` và skill `git-worktree-lanes` vẫn còn, nhưng chỉ có tác dụng khi agent đọc tới.

## What Changes

- Đặt 2 mục đó trong nháy kép. Nội dung chữ giữ nguyên từng ký tự.
- Repo App còn cùng lỗi ở `rules.specs` dòng 24 (`(hiện: app_vi.arb ...)`): doctor báo "Rules for 'specs' must be an array of strings, ignoring this artifact's rules", nên cả 2 luật viết spec bị bỏ qua. Đặt dòng đó trong nháy kép.

## Out of scope

- Không đổi nội dung bất kỳ luật nào trong `config.yaml`.
- Không đổi `openspec-gate.py`, không archive hay sửa change khác.
- Không đổi code ứng dụng; không có spec delta (`skip_specs: true`).

## Impact

- Chỉ `openspec/config.yaml` của repo App.
- Cùng lỗi có ở cả 3 repo (Web, Backend, App); mỗi repo có change riêng cùng tên, sửa độc lập. Không ảnh hưởng API hay field nào.

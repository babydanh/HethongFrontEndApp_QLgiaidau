# Tasks

## 1. Sửa cấu hình

- [x] 1.1 Đặt nháy kép cho mục guidance ở dòng 36 và 37 của `openspec/config.yaml`. Xong khi: `yaml.safe_load` trả `operations.archive.guidance` là danh sách 5 phần tử đều là chuỗi, và nội dung chữ giống bản trước.
- [x] 1.2 Đặt nháy kép cho `rules.specs` dòng 24. Xong khi: `yaml.safe_load` trả `rules.specs` toàn chuỗi, nội dung chữ giữ nguyên.

## 2. Kiểm chứng

- [x] 2.1 `openspec doctor`. Xong khi: không còn dòng "must be an array of strings" (cả guidance archive lẫn rules specs).
- [x] 2.2 `openspec validate --all --strict`. Xong khi: exit 0.

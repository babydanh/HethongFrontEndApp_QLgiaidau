# Tasks

## 1. Sửa cấu hình

- [ ] 1.1 Đặt nháy kép cho mục guidance ở dòng 36 và 37 của `openspec/config.yaml`. Xong khi: `yaml.safe_load` trả `operations.archive.guidance` là danh sách 5 phần tử đều là chuỗi, và nội dung chữ giống bản trước.

## 2. Kiểm chứng

- [ ] 2.1 `openspec doctor`. Xong khi: không còn dòng "Guidance for operation 'archive' must be an array of strings".
- [ ] 2.2 `openspec validate --all --strict`. Xong khi: exit 0.

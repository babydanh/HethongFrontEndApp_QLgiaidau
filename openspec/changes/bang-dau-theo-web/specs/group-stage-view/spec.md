## ADDED Requirements
### Requirement: Bảng đấu công khai theo bố cục Web
Trang công khai SHALL hiển thị mỗi bảng với tên rõ "Bảng X", ba chế độ xem và popup chi tiết trận.

#### Scenario: Bảng chéo nội dung đôi
- **WHEN** một bảng có đội đôi đã đấu xong một trận
- **THEN** hàng đội hiển thị 2 dòng VĐV viết tắt, ô giao nhau hiển thị mỗi set một dòng "điểm mình-điểm đối thủ", và bấm ô mở popup có tên đầy đủ

#### Scenario: Ô chưa đấu
- **WHEN** hai đội chưa đấu
- **THEN** ô hiển thị "-" và bấm vẫn mở popup trận (trạng thái sắp diễn ra)

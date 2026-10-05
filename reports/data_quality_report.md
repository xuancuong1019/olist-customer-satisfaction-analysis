# Data Quality Report — Olist E-Commerce Dataset

**Layer kiểm tra:** `staging` (dữ liệu thô, chưa xử lý)
**Database:** `e_commerce`
**Công cụ kiểm tra:** SQL Server (T-SQL) + Python (pandas, sqlalchemy)

---

## 1. Row Count Check

| Bảng | Số dòng CSV gốc | Số dòng trong SQL Server | Trạng thái |
|---|---|---|---|
| `olist_order_reviews` | 104,719 (đếm dòng vật lý) | 99,224 | Chênh lệch — đã xác minh nguyên nhân |
| Các bảng còn lại | Khớp | Khớp | Đạt |

### Phân tích chi tiết
- Chênh lệch giữa 104,719 và 99,224 ban đầu bị nghi ngờ là **mất dữ liệu khi import**.
- Sau khi kiểm tra lại tại notebook `01_sanity_check_cleaning`, xác nhận nguyên nhân: cột `review_comment_message` chứa **ký tự xuống dòng (`\n`)** bên trong nội dung review (khách viết bình luận nhiều đoạn).
- Theo chuẩn CSV (RFC 4180), các field có chứa xuống dòng được bao trong dấu `"..."`, và `\n` bên trong cặp ngoặc kép này **không phải là ranh giới kết thúc dòng**.
- 104,719 là kết quả đếm **dòng vật lý** (sai, vì không hiểu quy tắc quoting). 99,224 là kết quả đếm **dòng logic/bản ghi thật** (đúng, khớp với số liệu chuẩn công khai của dataset Olist).

**Kết luận:** Không có dữ liệu bị mất. Import đã đầy đủ 100%.

---

## 2. Schema & Structure Check

| Hạng mục | Kết quả |
|---|---|
| Cấu trúc bảng (số cột, tên cột) | ✅ Khớp với thiết kế ban đầu |
| Nội dung các cột | ✅ Xác nhận hoàn chỉnh, không phát hiện lệch cấu trúc do lỗi parser |

**Kết luận:** Toàn bộ 9 bảng staging có cấu trúc đúng như kỳ vọng.

---

## 3. Uniqueness Check

Kiểm tra các cột định danh (ID) không được phép trùng lặp:

| Cột | Bảng | Kết quả | Ghi chú |
|---|---|---|---|
| `review_id` | `olist_order_reviews` | ⚠️ **Có trùng lặp** | Xem phân tích bên dưới |
| `order_id` | `olist_orders` | ✅ Không trùng | |
| `customer_id` | `olist_customers` | ✅ Không trùng | |
| `seller_id` | `olist_sellers` | ✅ Không trùng | |
| `product_id` | `olist_products` | ✅ Không trùng | |

### Phân tích trường hợp `review_id` trùng lặp

- Các dòng có cùng `review_id` nhưng **khác `order_id`**.
- Giả thuyết đã kiểm chứng: khi một khách hàng mua nhiều đơn hàng từ **nhiều shop khác nhau trong cùng một lần giao dịch**, Olist chỉ gửi **một khảo sát duy nhất** cho tất cả các đơn đó.
- Hệ quả: `review_id` không đủ để làm khóa chính đơn lẻ; cần dùng **composite key `(review_id, order_id)`**.

**Xử lý đề xuất ở layer `clean`:** Đặt `PRIMARY KEY (review_id, order_id)` cho bảng `olist_order_reviews`.

---

## 4. Completeness / NULL Check (Missing Values)

Đối chiếu kết quả từ cả Python và SQL — **khớp nhau hoàn toàn**, xác nhận độ tin cậy của phép đo.

| Bảng | Cột | Số lượng thiếu | Đánh giá sơ bộ |
|---|---|---|---|
| `olist_order_reviews` | `review_comment_message` | 58,274 | Hợp lý — khách không bắt buộc viết nội dung, chỉ chấm điểm |
| `olist_order_reviews` | `review_comment_title` | 87,658 | Hợp lý — tiêu đề càng ít được điền hơn nội dung |
| `olist_orders` | `order_approved_at` | 160 | Cần đối chiếu với `order_status` (đơn bị hủy/chưa duyệt) |
| `olist_orders` | `order_delivered_carrier_date` | 1,783 | Cần đối chiếu với `order_status` (đơn chưa giao cho vận chuyển) |
| `olist_orders` | `order_delivered_customer_date` | 2,965 | Cần đối chiếu với `order_status` (đơn chưa giao đến khách / bị hủy) |
| `olist_products` | `product_category_name` | 610 | Sản phẩm thiếu thông tin danh mục |
| `olist_products` | `product_description_lenght` | 610 | Trùng với nhóm thiếu category — khả năng cùng 1 nhóm sản phẩm bị thiếu metadata |
| `olist_products` | `product_name_lenght` | 610 | Trùng nhóm trên |
| `olist_products` | `product_photos_qty` | 610 | Trùng nhóm trên |
| `olist_products` | `product_height_cm` | 2 | Số lượng rất nhỏ, khả năng lỗi nhập liệu cá biệt |
| `olist_products` | `product_length_cm` | 2 | Trùng nhóm trên |
| `olist_products` | `product_weight_g` | 2 | Trùng nhóm trên |
| `olist_products` | `product_width_cm` | 2 | Trùng nhóm trên |

### Nhận xét
- Nhóm 4 cột cùng thiếu đúng 610 dòng ở `olist_products` (`product_category_name`, `product_description_lenght`, `product_name_lenght`, `product_photos_qty`) nhiều khả năng là **cùng một tập 610 sản phẩm** bị thiếu toàn bộ metadata mô tả — cần xác minh thêm bằng cách kiểm tra các dòng này có trùng nhau không.
- Nhóm 4 cột kích thước vật lý (`height`, `length`, `weight`, `width`) chỉ thiếu 2 dòng — số lượng quá nhỏ để ảnh hưởng phân tích, có thể xử lý bằng loại bỏ hoặc impute.

**[Cần xác nhận]** Chưa xác minh liệu 610 dòng thiếu category có phải chính xác là cùng một tập hợp dòng hay không — đề xuất chạy kiểm tra chéo:
```sql
SELECT COUNT(*) FROM staging.olist_products
WHERE (product_category_name IS NULL OR product_category_name = '')
  AND (product_name_lenght IS NULL OR product_name_lenght = '')
  AND (product_description_lenght IS NULL OR product_description_lenght = '')
  AND (product_photos_qty IS NULL OR product_photos_qty = '');
```

---

## 5. Referential Integrity Check

| Cặp kiểm tra | Kết quả | Trạng thái |
|---|---|---|
| `orders.customer_id` → `customers.customer_id` | 0 orphan | ✅ Đạt |
| `order_items.order_id` → `orders.order_id` | 0 orphan | ✅ Đạt |
| `order_items.product_id` → `products.product_id` | 0 orphan | ✅ Đạt |
| `order_items.seller_id` → `sellers.seller_id` | 0 orphan | ✅ Đạt |
| `order_payments.order_id` → `orders.order_id` | 0 orphan | ✅ Đạt |
| `order_reviews.order_id` → `orders.order_id` | 0 orphan | ✅ Đạt |
| `products.product_category_name` → `product_category.product_category_name` | **13 orphan** | ⚠️ Phát hiện vấn đề |

### Phân tích trường hợp `orphan_products_category = 13`

- Có **13 sản phẩm** trong `olist_products` được gán một `product_category_name`, nhưng giá trị đó **không tồn tại** trong bảng chuẩn `product_category` (bảng dịch tên category sang tiếng Anh).
- Hệ quả: nếu `JOIN` với `product_category` để lấy tên tiếng Anh, 13 sản phẩm này sẽ bị loại khỏi kết quả nếu dùng `INNER JOIN`, hoặc có giá trị `NULL` ở cột tên tiếng Anh nếu dùng `LEFT JOIN`.

**Xử lý đề xuất ở layer `clean`:**
1. Trích xuất danh sách 13 category_name bị lệch để xem đây là lỗi chính tả/khoảng trắng hay category thực sự không có bản dịch:
```sql
SELECT DISTINCT p.product_category_name
FROM staging.olist_products p
LEFT JOIN staging.product_category c ON p.product_category_name = c.product_category_name
WHERE p.product_category_name IS NOT NULL AND c.product_category_name IS NULL;
```
2. Dựa vào kết quả, quyết định: sửa lỗi chính tả (nếu có), bổ sung thủ công vào `product_category`, hoặc gán nhãn `"unknown"` khi xây layer `clean`.

---

## 6. Tổng hợp vấn đề cần xử lý ở layer `clean`

| # | Vấn đề | Mức độ ảnh hưởng | Hướng xử lý đề xuất |
|---|---|---|---|
| 1 | `review_id` trùng do gộp khảo sát nhiều đơn | Trung bình | Đặt PK composite `(review_id, order_id)` |
| 2 | NULL ở `review_comment_title`/`message` | Thấp (hợp lệ nghiệp vụ) | Giữ nguyên NULL, không impute |
| 3 | NULL ở các cột ngày giao hàng (`approved_at`, `delivered_carrier_date`, `delivered_customer_date`) | Trung bình | Đối chiếu với `order_status` trước khi quyết định xử lý |
| 4 | 610 sản phẩm thiếu metadata mô tả | Trung bình | Xác minh có trùng tập dòng không; cân nhắc giữ NULL hoặc loại khỏi phân tích liên quan đến mô tả sản phẩm |
| 5 | 2 sản phẩm thiếu kích thước vật lý | Thấp | Loại bỏ hoặc impute bằng giá trị trung vị theo category |
| 6 | 13 sản phẩm có category không khớp bảng dịch | Thấp | Kiểm tra lỗi chính tả, bổ sung hoặc gán "unknown" |
| 7 | `customer_id` ≠ `customer_unique_id` (99,441 vs 96,096) | Cao (ảnh hưởng phân tích khách hàng) | Dùng `customer_unique_id` khi tính repeat customer/RFM; cân nhắc composite `(customer_id, customer_unique_id)` khi join đơn hàng |

---

## 7. Việc cần làm tiếp theo

1. Chạy kiểm tra chéo cho mục 610 dòng thiếu metadata sản phẩm (mục 4, phần [Cần xác nhận]).
2. Trích xuất danh sách 13 category bị lệch (mục 5) để quyết định hướng xử lý cụ thể.
3. Đối chiếu NULL ở các cột ngày giao hàng với `order_status` để phân loại NULL hợp lệ vs bất thường.
4. Dựa trên toàn bộ kết luận ở mục 6, thiết kế DDL chính thức cho schema `clean`.